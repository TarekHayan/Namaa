begin;
select plan(10);

insert into auth.users(instance_id,id,aud,role,email,encrypted_password,created_at,updated_at)
values
('00000000-0000-0000-0000-000000000000','81111111-1111-4111-8111-111111111111','authenticated','authenticated','prayer-a@example.com','x',now(),now()),
('00000000-0000-0000-0000-000000000000','82222222-2222-4222-8222-222222222222','authenticated','authenticated','prayer-b@example.com','x',now(),now());

select is(public.prayer_report_id_v1('2026-10-29'::date,'fajr'),
  '7f760cba-01ed-5edf-b06c-603eefdebe52'::uuid,
  'SQL report identity matches the pinned client UUIDv5 vector');
select is(public.prayer_conflict_id_v1(
    '7f760cba-01ed-5edf-b06c-603eefdebe52'::uuid,
    '1793264400000000:completed_late|1793264400000000|Africa/Cairo|120',
    '1793264400000000:missed|null|Africa/Cairo|120'),
  'e58910e7-0b1c-55e0-8c8b-36fe5265969b'::uuid,
  'SQL conflict identity matches the pinned client vector');

insert into public.prayer_reports(owner,report_id,local_date,prayer_name,status,
  recorded_zone_id,recorded_offset_minutes,created_at,updated_at)
values('81111111-1111-4111-8111-111111111111',
  public.prayer_report_id_v1('2026-10-29','fajr'),
  '2026-10-29','fajr','pending','Africa/Cairo',120,
  '2026-10-29 05:00+00','2026-10-29 05:00+00');
insert into public.prayer_conflicts(owner,conflict_id,report_id,local_date,
  prayer_name,active_report,retained_report)
values('81111111-1111-4111-8111-111111111111',
  'e58910e7-0b1c-55e0-8c8b-36fe5265969b',
  public.prayer_report_id_v1('2026-10-29','fajr'),
  '2026-10-29','fajr','{}','{}');

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"81111111-1111-4111-8111-111111111111","role":"authenticated"}',true);
select is((select count(*) from public.prayer_reports),1::bigint,'owner reads own report');
select is((select count(*) from public.prayer_conflicts),1::bigint,'owner reads own evidence');
select ok(not has_table_privilege('authenticated','public.prayer_reports','INSERT'),
  'client has no direct report insert');
select ok(not has_table_privilege('authenticated','public.prayer_conflicts','UPDATE'),
  'client has no direct conflict update');
select ok(not has_table_privilege('authenticated','public.prayer_operation_receipts','SELECT'),
  'client cannot inspect internal receipts');
select set_config('request.jwt.claims',
  '{"sub":"82222222-2222-4222-8222-222222222222","role":"authenticated"}',true);
select is((select count(*) from public.prayer_reports),0::bigint,'foreign report is hidden');
select is((select count(*) from public.prayer_conflicts),0::bigint,'foreign evidence is hidden');
reset role;
select ok(not has_function_privilege('anon',
  'public.apply_prayer_report_change_v1(uuid,date,text,text,timestamptz,text,integer,timestamptz,timestamptz,timestamptz,text)',
  'EXECUTE'),'anonymous mutation denied');
select * from finish();
rollback;
