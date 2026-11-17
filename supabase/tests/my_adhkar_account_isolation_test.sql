-- T091: My Adhkar access control. Anonymous callers and foreign owners are
-- denied; malformed input is rejected; every direct client write is denied.
-- Proofs from contracts/adhkar-qiyam-sync.md ("My Adhkar"). Placeholder
-- strings only: no real adhkar text appears in any fixture.
begin;
select plan(28);
insert into auth.users(instance_id,id,aud,role,email,encrypted_password,created_at,updated_at)
values('00000000-0000-0000-0000-000000000000',
  '86666666-6666-4666-8666-666666666666','authenticated','authenticated',
  'my-adhkar-iso@example.com','x',now(),now()),
  ('00000000-0000-0000-0000-000000000000',
  '77777777-7777-4777-8777-777777777777','authenticated','authenticated',
  'my-adhkar-other@example.com','x',now(),now());

create function pg_temp.submit_group(p_group uuid,p_name text,p_created timestamptz,
  p_deleted boolean,p_version timestamptz,p_base timestamptz,p_op text)
returns jsonb language plpgsql as $$
declare r jsonb;
begin
  select public.apply_my_adhkar_group_change_v1(p_group,p_name,p_created,
    p_deleted,p_version,p_base,p_op) into r;
  return r;
exception when others then
  return jsonb_build_object('error',sqlerrm);
end $$;

create function pg_temp.submit_item(p_item uuid,p_text text,p_source text,
  p_groups uuid[],p_created timestamptz,p_deleted boolean,
  p_version timestamptz,p_base timestamptz,p_op text)
returns jsonb language plpgsql as $$
declare r jsonb;
begin
  select public.apply_my_adhkar_item_change_v1(p_item,p_text,p_source,
    p_groups,p_created,p_deleted,p_version,p_base,p_op) into r;
  return r;
exception when others then
  return jsonb_build_object('error',sqlerrm);
end $$;

-- Anonymous callers: the anon role has no execute right at all, and a
-- session with no claims is rejected by the function itself.
set local role anon;
select throws_ok(
  'select public.apply_my_adhkar_group_change_v1(
     ''aaaaaaaa-1111-4111-8111-111111111111''::uuid,''g'',
     ''2026-11-16 08:00+00''::timestamptz,false,
     ''2026-11-16 08:00+00''::timestamptz,null,''anon-group'')',
  '42501',null,'the anon role cannot execute the group RPC');
select throws_ok(
  'select public.apply_my_adhkar_item_change_v1(
     ''bbbbbbbb-2222-4222-8222-222222222222''::uuid,''text'',null,
     array[''aaaaaaaa-1111-4111-8111-111111111111''::uuid],
     ''2026-11-16 08:00+00''::timestamptz,false,
     ''2026-11-16 08:00+00''::timestamptz,null,''anon-item'')',
  '42501',null,'the anon role cannot execute the entry RPC');
reset role;
select throws_ok(
  'select public.apply_my_adhkar_group_change_v1(
     ''aaaaaaaa-1111-4111-8111-111111111111''::uuid,''g'',
     ''2026-11-16 08:00+00''::timestamptz,false,
     ''2026-11-16 08:00+00''::timestamptz,null,''no-claims-group'')',
  '42501','Not authenticated','a session without claims is rejected (group)');
select throws_ok(
  'select public.apply_my_adhkar_item_change_v1(
     ''bbbbbbbb-2222-4222-8222-222222222222''::uuid,''text'',null,
     array[''aaaaaaaa-1111-4111-8111-111111111111''::uuid],
     ''2026-11-16 08:00+00''::timestamptz,false,
     ''2026-11-16 08:00+00''::timestamptz,null,''no-claims-item'')',
  '42501','Not authenticated','a session without claims is rejected (entry)');

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"86666666-6666-4666-8666-666666666666","role":"authenticated"}',true);
select is(pg_temp.submit_group(
  'aaaaaaaa-1111-4111-8111-111111111111','group 1','2026-11-16 08:00:00+00',
  false,'2026-11-16 08:00:00+00',null,'owner-a-group')->>'error',null,
  'owner A creates its first group');
select is(pg_temp.submit_item(
  'bbbbbbbb-2222-4222-8222-222222222222','entry text 1','source text 1',
  array['aaaaaaaa-1111-4111-8111-111111111111'::uuid],
  '2026-11-16 08:05:00+00',false,'2026-11-16 08:05:00+00',null,
  'owner-a-item')->>'error',null,'owner A creates its first entry');

-- Malformed inputs are rejected without side effects.
select is(pg_temp.submit_item(
  'cccccccc-3333-4333-8333-333333333333','   ',null,
  array['aaaaaaaa-1111-4111-8111-111111111111'::uuid],
  '2026-11-16 08:06:00+00',false,'2026-11-16 08:06:00+00',null,
  'blank-text')->>'error','Invalid My Adhkar item operation',
  'blank text is rejected');
select is(pg_temp.submit_item(
  'cccccccc-3333-4333-8333-333333333333',repeat('x',2001),null,
  array['aaaaaaaa-1111-4111-8111-111111111111'::uuid],
  '2026-11-16 08:06:00+00',false,'2026-11-16 08:06:00+00',null,
  'long-text')->>'error','Invalid My Adhkar item operation',
  'text over 2000 code points is rejected');
select is(pg_temp.submit_item(
  'cccccccc-3333-4333-8333-333333333333','t',repeat('x',501),
  array['aaaaaaaa-1111-4111-8111-111111111111'::uuid],
  '2026-11-16 08:06:00+00',false,'2026-11-16 08:06:00+00',null,
  'long-source')->>'error','Invalid My Adhkar item operation',
  'a source over 500 code points is rejected');
select is(pg_temp.submit_item(
  'cccccccc-3333-4333-8333-333333333333','t',null,array[]::uuid[],
  '2026-11-16 08:06:00+00',false,'2026-11-16 08:06:00+00',null,
  'empty-groups')->>'error','Invalid My Adhkar item operation',
  'an empty group set on a live entry is rejected');
select is(pg_temp.submit_item(
  'cccccccc-3333-4333-8333-333333333333','t',null,
  array['aaaaaaaa-1111-4111-8111-111111111111'::uuid,
        'aaaaaaaa-1111-4111-8111-111111111111'::uuid],
  '2026-11-16 08:06:00+00',false,'2026-11-16 08:06:00+00',null,
  'duplicate-groups')->>'error','Invalid My Adhkar item operation',
  'a duplicated group id is rejected');
select is(pg_temp.submit_item(
  'cccccccc-3333-4333-8333-333333333333','t',null,
  array['dddddddd-4444-4444-8444-444444444444'::uuid],
  '2026-11-16 08:06:00+00',false,'2026-11-16 08:06:00+00',null,
  'unknown-group')->>'error','My Adhkar group missing',
  'an unknown group is the retryable group_missing failure');
select is(pg_temp.submit_group(
  'eeeeeeee-5555-4555-8555-555555555555','   ','2026-11-16 08:06:00+00',
  false,'2026-11-16 08:06:00+00',null,'blank-name')->>'error',
  'Invalid My Adhkar group operation','a blank group name is rejected');
select is(pg_temp.submit_group(
  'eeeeeeee-5555-4555-8555-555555555555',repeat('x',61),
  '2026-11-16 08:06:00+00',false,'2026-11-16 08:06:00+00',null,
  'long-name')->>'error','Invalid My Adhkar group operation',
  'a name over 60 code points is rejected');
select is(pg_temp.submit_group(
  'eeeeeeee-5555-4555-8555-555555555555','group 2','2026-11-16 08:06:00+00',
  false,'2026-11-16 08:06:00+00',null,'   ')->>'error',
  'Invalid My Adhkar group operation','a blank operation ID is rejected');
select is(pg_temp.submit_item(
  'cccccccc-3333-4333-8333-333333333333','t',null,
  array['aaaaaaaa-1111-4111-8111-111111111111'::uuid],
  '2026-11-16 08:06:00+00',false,now() + interval '3 days',null,
  'too-far-ahead')->>'error',
  'My Adhkar timestamp more than two days ahead',
  'a timestamp more than two days ahead is rejected (entry)');
select is(pg_temp.submit_group(
  'eeeeeeee-5555-4555-8555-555555555555','group 2','2026-11-16 08:06:00+00',
  false,now() + interval '3 days',null,'too-far-ahead-group')->>'error',
  'My Adhkar timestamp more than two days ahead',
  'a timestamp more than two days ahead is rejected (group)');

-- A foreign owner is denied: owner B cannot see or write into owner A's
-- rows, and nothing leaks through RLS.
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"77777777-7777-4777-8777-777777777777","role":"authenticated"}',true);
select is((select count(*) from public.my_adhkar_groups),0::bigint,
  'owner B cannot see owner A groups through RLS');
select is((select count(*) from public.my_adhkar_items),0::bigint,
  'owner B cannot see owner A entries through RLS');
select is((select count(*) from public.my_adhkar_item_groups),0::bigint,
  'owner B cannot see owner A memberships through RLS');
select is(pg_temp.submit_item(
  'cccccccc-3333-4333-8333-333333333333','t',null,
  array['aaaaaaaa-1111-4111-8111-111111111111'::uuid],
  '2026-11-16 08:06:00+00',false,'2026-11-16 08:06:00+00',null,
  'foreign-group')->>'error','My Adhkar group missing',
  'owner A''s group is unknown to owner B (group_missing)');
select is(pg_temp.submit_group(
  'aaaaaaaa-1111-4111-8111-111111111111','hijacked','2026-11-16 08:06:00+00',
  false,'2026-11-16 08:06:00+00','2026-11-16 08:00:00+00',
  'foreign-base')->>'error','Unknown My Adhkar group base version',
  'owner B cannot touch owner A''s group through a base version');
reset role;
select is((select name from public.my_adhkar_groups
  where owner='86666666-6666-4666-8666-666666666666'
    and group_id='aaaaaaaa-1111-4111-8111-111111111111'),'group 1',
  'owner A group untouched by owner B activity');

-- Direct client writes are denied everywhere.
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"86666666-6666-4666-8666-666666666666","role":"authenticated"}',true);
select throws_ok(
  'insert into public.my_adhkar_groups values (
   ''86666666-6666-4666-8666-666666666666'',
   ''aaaaaaaa-1111-4111-8111-111111111111'',''x'',
   ''2026-11-16 08:00+00'',''2026-11-16 08:00+00'',null)',
  '42501',null,'direct group inserts are denied');
select throws_ok(
  'update public.my_adhkar_items set text = ''changed''',
  '42501',null,'direct entry updates are denied');
select throws_ok(
  'delete from public.my_adhkar_conflicts where owner = auth.uid()',
  '42501',null,'conflict deletes are denied');
select throws_ok(
  'insert into public.my_adhkar_item_groups values (
   ''86666666-6666-4666-8666-666666666666'',
   ''bbbbbbbb-2222-4222-8222-222222222222'',
   ''aaaaaaaa-1111-4111-8111-111111111111'',''2026-11-16 08:00+00'')',
  '42501',null,'membership writes are denied');
select throws_ok(
  'select * from public.my_adhkar_operation_receipts',
  '42501',null,'receipts are not readable by a client');
reset role;
select * from finish();
rollback;
