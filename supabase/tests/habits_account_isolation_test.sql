begin;
select plan(9);

insert into auth.users(instance_id,id,aud,role,email,encrypted_password,created_at,updated_at)
values
('00000000-0000-0000-0000-000000000000','61111111-1111-1111-1111-111111111111','authenticated','authenticated','habit-owner-a@example.com','x',now(),now()),
('00000000-0000-0000-0000-000000000000','62222222-2222-2222-2222-222222222222','authenticated','authenticated','habit-owner-b@example.com','x',now(),now());

insert into public.habits(owner,id,payload,updated_at)
values ('61111111-1111-1111-1111-111111111111',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '{}'::jsonb, now());
insert into public.habit_days(owner,habit_id,local_date,payload,updated_at)
values ('61111111-1111-1111-1111-111111111111',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '2026-10-12', '{}'::jsonb, now());
insert into public.habit_operation_receipts(owner,operation_id,entity_type,entity_id,
  kind,request_payload,request_updated_at,result_payload,result_updated_at)
values ('61111111-1111-1111-1111-111111111111','isolation-op','habit',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','create','{}',now(),'{}',now());

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"61111111-1111-1111-1111-111111111111","role":"authenticated"}', true);
select is((select count(*) from public.habits), 1::bigint, 'owner reads own Habit');
select is((select count(*) from public.habit_days), 1::bigint, 'owner reads own day');
select ok(not has_table_privilege('authenticated','public.habits','INSERT'),
  'authenticated client cannot directly write Habits');
select ok(not has_table_privilege('authenticated','public.habit_days','UPDATE'),
  'authenticated client cannot directly edit days');
select ok(not has_table_privilege('authenticated','public.habit_operation_receipts','SELECT'),
  'authenticated client cannot read receipts');
select set_config('request.jwt.claims',
  '{"sub":"62222222-2222-2222-2222-222222222222","role":"authenticated"}', true);
select is((select count(*) from public.habits), 0::bigint, 'foreign Habit is hidden');
select is((select count(*) from public.habit_days), 0::bigint, 'foreign day is hidden');
select throws_ok(
  $sql$select public.apply_habit_change(
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    '{"id":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
      "accountId":"61111111-1111-1111-1111-111111111111",
      "name":"Foreign","createdAt":"2026-10-12T08:00:00Z",
      "updatedAt":"2026-10-12T09:00:00Z","deletedAt":null,
      "scheduleRevisions":[{"revisionId":"r1",
        "effectiveAt":"2026-10-12T08:00:00Z",
        "effectiveLocalDate":"2026-10-12","utcOffsetMinutes":120,
        "weekdays":[1]}]}'::jsonb,
    'foreign-op','2026-10-12T09:00:00Z','update')$sql$,
  '22023', null, 'foreign owner payload cannot mutate through RPC');
reset role;
select ok(not has_function_privilege('anon',
  'public.apply_habit_change(uuid,jsonb,text,timestamptz,text)','EXECUTE'),
  'anonymous client cannot invoke mutation boundary');

select * from finish();
rollback;
