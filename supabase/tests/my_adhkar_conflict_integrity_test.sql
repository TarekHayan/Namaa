-- T091: My Adhkar conflict integrity (contracts/adhkar-qiyam-sync.md):
-- newest-wins with one stable conflict for concurrent edits whatever the
-- arrival order (two owners play the two arrival orders), the equal-timestamp
-- tie, an entry delete with an empty p_group_ids accepted (the local delete
-- removes the memberships), and replay safety. Placeholder strings only.
begin;
select plan(21);
insert into auth.users(instance_id,id,aud,role,email,encrypted_password,created_at,updated_at)
values('00000000-0000-0000-0000-000000000000',
  '86666666-6666-4666-8666-666666666666','authenticated','authenticated',
  'my-adhkar-conflict@example.com','x',now(),now()),
  ('00000000-0000-0000-0000-000000000000',
  '77777777-7777-4777-8777-777777777777','authenticated','authenticated',
  'my-adhkar-conflict-b@example.com','x',now(),now());

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

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"86666666-6666-4666-8666-666666666666","role":"authenticated"}',true);

-- The shared group and the base entry.
select is(pg_temp.submit_group(
  'aaaaaaaa-1111-4111-8111-111111111111','group 1','2026-11-16 08:00:00+00',
  false,'2026-11-16 08:00:00+00',null,'conf-group')->>'error',null,
  'the group lands');
select is(pg_temp.submit_item(
  'bbbbbbbb-2222-4222-8222-222222222222','base text','base source',
  array['aaaaaaaa-1111-4111-8111-111111111111'::uuid],
  '2026-11-16 08:05:00+00',false,'2026-11-16 08:05:00+00',null,
  'conf-item')->>'error',null,'the entry lands');

-- Two devices race offline edits: the newest wins and exactly one stable
-- conflict is kept.
select is(pg_temp.submit_item(
  'bbbbbbbb-2222-4222-8222-222222222222','device A text',null,
  array['aaaaaaaa-1111-4111-8111-111111111111'::uuid],
  '2026-11-16 08:05:00+00',false,'2026-11-16 09:00:00+00',
  '2026-11-16 08:05:00+00','race-a')->'active_record'->>'text',
  'device A text','device A edit lands at 09:00');
select is(pg_temp.submit_item(
  'bbbbbbbb-2222-4222-8222-222222222222','device B text','device B source',
  array['aaaaaaaa-1111-4111-8111-111111111111'::uuid],
  '2026-11-16 08:05:00+00',false,'2026-11-16 08:50:00+00',
  '2026-11-16 08:05:00+00','race-b')->'active_record'->>'text',
  'device A text','the older device B edit loses to the newest-wins rule');
select is((select count(*) from public.my_adhkar_conflicts
  where entity_type='item'
    and entity_id='bbbbbbbb-2222-4222-8222-222222222222'),1::bigint,
  'exactly one conflict is kept for the race');
select is((select retained_record->>'text' from public.my_adhkar_conflicts
  where entity_type='item'
    and entity_id='bbbbbbbb-2222-4222-8222-222222222222'),
  'device B text','the losing version is retained');
select is(pg_temp.submit_item(
  'bbbbbbbb-2222-4222-8222-222222222222','device B text','device B source',
  array['aaaaaaaa-1111-4111-8111-111111111111'::uuid],
  '2026-11-16 08:05:00+00',false,'2026-11-16 08:50:00+00',
  '2026-11-16 08:05:00+00','race-b-2')->>'conflict_id',
  pg_temp.submit_item(
    'bbbbbbbb-2222-4222-8222-222222222222','device B text','device B source',
    array['aaaaaaaa-1111-4111-8111-111111111111'::uuid],
    '2026-11-16 08:05:00+00',false,'2026-11-16 08:50:00+00',
    '2026-11-16 08:05:00+00','race-b-3')->>'conflict_id',
  'the same pair yields the same stable conflict id under new operations');

-- An exact replay returns the recorded outcome with no new side effects.
select is(pg_temp.submit_item(
  'bbbbbbbb-2222-4222-8222-222222222222','device A text',null,
  array['aaaaaaaa-1111-4111-8111-111111111111'::uuid],
  '2026-11-16 08:05:00+00',false,'2026-11-16 09:00:00+00',
  '2026-11-16 08:05:00+00','race-a')->>'replayed','true',
  'an exact replay is answered from the receipt');

-- A changed-content operation-ID collision is rejected.
select is(pg_temp.submit_item(
  'bbbbbbbb-2222-4222-8222-222222222222','different text',null,
  array['aaaaaaaa-1111-4111-8111-111111111111'::uuid],
  '2026-11-16 08:05:00+00',false,'2026-11-16 09:00:00+00',
  '2026-11-16 08:05:00+00','race-a')->>'error',
  'My Adhkar operation ID reused with different content',
  'an operation ID reused with different content is rejected');

-- An entry delete with an EMPTY p_group_ids is accepted: the local delete
-- removes the memberships, so the deleted entry carries no group set.
select is(pg_temp.submit_item(
  'cccccccc-3333-4333-8333-333333333333','short lived',null,
  array['aaaaaaaa-1111-4111-8111-111111111111'::uuid],
  '2026-11-16 08:10:00+00',false,'2026-11-16 08:10:00+00',null,
  'short-add')->>'error',null,'the entry to delete lands');
select is(pg_temp.submit_item(
  'cccccccc-3333-4333-8333-333333333333','short lived',null,
  array[]::uuid[],
  '2026-11-16 08:10:00+00',true,'2026-11-16 08:12:00+00',
  '2026-11-16 08:10:00+00','short-delete')->'active_record'->>'deleted_at',
  '2026-11-16T08:12:00+00:00',
  'a delete with an empty p_group_ids is accepted');
select is((select count(*) from public.my_adhkar_item_groups
  where item_id='cccccccc-3333-4333-8333-333333333333'),0::bigint,
  'the delete removed the memberships');

-- Concurrent renames of one group: owner A sees the newest first.
select is(pg_temp.submit_group(
  'fafafafa-1111-4111-8111-111111111111','base name','2026-11-16 08:00:00+00',
  false,'2026-11-16 08:00:00+00',null,'rename-base')->>'error',null,
  'the group to rename lands');
select is(pg_temp.submit_group(
  'fafafafa-1111-4111-8111-111111111111','name X','2026-11-16 08:00:00+00',
  false,'2026-11-16 09:00:00+00','2026-11-16 08:00:00+00',
  'rename-x')->'active_record'->>'name','name X','the newest rename lands');
select is(pg_temp.submit_group(
  'fafafafa-1111-4111-8111-111111111111','name Y','2026-11-16 08:00:00+00',
  false,'2026-11-16 08:50:00+00','2026-11-16 08:00:00+00',
  'rename-y')->'active_record'->>'name','name X',
  'the older concurrent rename loses');
select is((select count(*) from public.my_adhkar_conflicts
  where entity_type='group'
    and entity_id='fafafafa-1111-4111-8111-111111111111'
    and retained_record->>'name'='name Y'),1::bigint,
  'one group conflict keeps the losing rename');

-- Owner B plays the opposite arrival order for the same two versions and
-- for an equal-timestamp tie on an entry; the outcome must be the same.
select set_config('request.jwt.claims',
  '{"sub":"77777777-7777-4777-8777-777777777777","role":"authenticated"}',true);
select pg_temp.submit_group(
  'fafafafa-1111-4111-8111-111111111111','base name','2026-11-16 08:00:00+00',
  false,'2026-11-16 08:00:00+00',null,'b-rename-base');
select pg_temp.submit_group(
  'fafafafa-1111-4111-8111-111111111111','name Y','2026-11-16 08:00:00+00',
  false,'2026-11-16 08:50:00+00','2026-11-16 08:00:00+00','b-rename-y');
select is(pg_temp.submit_group(
  'fafafafa-1111-4111-8111-111111111111','name X','2026-11-16 08:00:00+00',
  false,'2026-11-16 09:00:00+00','2026-11-16 08:00:00+00',
  'b-rename-x')->'active_record'->>'name','name X',
  'the reverse arrival order ends on the same newest rename');
select pg_temp.submit_group(
  'fbfbfbfb-1111-4111-8111-111111111111','tie group','2026-11-16 08:00:00+00',
  false,'2026-11-16 08:00:00+00',null,'b-tie-group');
select pg_temp.submit_item(
  'dadadada-2222-4222-8222-222222222222','tie base',null,
  array['fbfbfbfb-1111-4111-8111-111111111111'::uuid],
  '2026-11-16 08:00:00+00',false,'2026-11-16 08:00:00+00',null,'b-tie-add');
select pg_temp.submit_item(
  'dadadada-2222-4222-8222-222222222222','tie z',null,
  array['fbfbfbfb-1111-4111-8111-111111111111'::uuid],
  '2026-11-16 08:00:00+00',false,'2026-11-16 09:00:00+00',
  '2026-11-16 08:00:00+00','b-tie-z');
select pg_temp.submit_item(
  'dadadada-2222-4222-8222-222222222222','tie a',null,
  array['fbfbfbfb-1111-4111-8111-111111111111'::uuid],
  '2026-11-16 08:00:00+00',false,'2026-11-16 09:00:00+00',
  '2026-11-16 08:00:00+00','b-tie-a');
-- Owner A: the same pair in the opposite order.
select set_config('request.jwt.claims',
  '{"sub":"86666666-6666-4666-8666-666666666666","role":"authenticated"}',true);
select pg_temp.submit_group(
  'fbfbfbfb-1111-4111-8111-111111111111','tie group','2026-11-16 08:00:00+00',
  false,'2026-11-16 08:00:00+00',null,'a-tie-group');
select pg_temp.submit_item(
  'dadadada-2222-4222-8222-222222222222','tie base',null,
  array['fbfbfbfb-1111-4111-8111-111111111111'::uuid],
  '2026-11-16 08:00:00+00',false,'2026-11-16 08:00:00+00',null,'a-tie-add');
select pg_temp.submit_item(
  'dadadada-2222-4222-8222-222222222222','tie a',null,
  array['fbfbfbfb-1111-4111-8111-111111111111'::uuid],
  '2026-11-16 08:00:00+00',false,'2026-11-16 09:00:00+00',
  '2026-11-16 08:00:00+00','a-tie-a');
select pg_temp.submit_item(
  'dadadada-2222-4222-8222-222222222222','tie z',null,
  array['fbfbfbfb-1111-4111-8111-111111111111'::uuid],
  '2026-11-16 08:00:00+00',false,'2026-11-16 09:00:00+00',
  '2026-11-16 08:00:00+00','a-tie-z');

reset role;
select is((select count(distinct conflict_id)::text || '/' || count(*)::text
  from public.my_adhkar_conflicts
  where entity_id='fafafafa-1111-4111-8111-111111111111'),'1/2',
  'both arrival orders keep one and the same stable group conflict id');
select is((select count(distinct text) from public.my_adhkar_items
  where item_id='dadadada-2222-4222-8222-222222222222'),1::bigint,
  'the equal-timestamp tie resolves to the same version in both orders');
select is((select count(distinct conflict_id)::text || '/' || count(*)::text
  from public.my_adhkar_conflicts
  where entity_id='dadadada-2222-4222-8222-222222222222'),'1/2',
  'both arrival orders keep one and the same stable tie conflict id');
select is((select count(*) from public.xp_awards),0::bigint,
  'no xp_awards row is ever written by My Adhkar');

select * from finish();
rollback;
