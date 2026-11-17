-- T091: My Adhkar operation integrity (contracts/adhkar-qiyam-sync.md):
-- code-point lengths, replay safety, the group delete cascade,
-- `group_deleted`, deletes that stay final, the 1000-entry and 100-group
-- limits, and zero xp_awards rows. Placeholder strings only.
begin;
select plan(32);
insert into auth.users(instance_id,id,aud,role,email,encrypted_password,created_at,updated_at)
values('00000000-0000-0000-0000-000000000000',
  '86666666-6666-4666-8666-666666666666','authenticated','authenticated',
  'my-adhkar-integrity@example.com','x',now(),now());

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

-- Code points: a supplementary-plane character is one code point.
select is(pg_temp.submit_group(
  'aaaaaaaa-1111-4111-8111-111111111111',repeat('𝐀',60),
  '2026-11-16 08:00:00+00',false,'2026-11-16 08:00:00+00',null,
  'group-cp')->>'error',null,
  'a 60-code-point supplementary name is accepted');
select is(pg_temp.submit_item(
  'bbbbbbbb-2222-4222-8222-222222222222',repeat('𝐀',2000),null,
  array['aaaaaaaa-1111-4111-8111-111111111111'::uuid],
  '2026-11-16 08:05:00+00',false,'2026-11-16 08:05:00+00',null,
  'item-cp')->>'error',null,
  'a 2000-code-point supplementary text is accepted');

-- A blank source is stored as null.
select is(pg_temp.submit_item(
  'cccccccc-3333-4333-8333-333333333333','entry text 1','   ',
  array['aaaaaaaa-1111-4111-8111-111111111111'::uuid],
  '2026-11-16 08:06:00+00',false,'2026-11-16 08:06:00+00',null,
  'blank-source')->'active_record'->>'source',null,
  'a blank source is stored as null');

-- A second, live group and one entry in both groups set up the cascade.
select is(pg_temp.submit_group(
  'dddddddd-4444-4444-8444-444444444444','group 2',
  '2026-11-16 08:00:00+00',false,'2026-11-16 08:00:00+00',null,
  'group-2')->>'error',null,'the second group lands');
select is(pg_temp.submit_item(
  'eeeeeeee-5555-4555-8555-555555555555','only in first',null,
  array['aaaaaaaa-1111-4111-8111-111111111111'::uuid],
  '2026-11-16 08:07:00+00',false,'2026-11-16 08:07:00+00',null,
  'item-first')->>'error',null,'the first entry lands');
select is(pg_temp.submit_item(
  'ffffffff-6666-4666-8666-666666666666','also in second',null,
  array['aaaaaaaa-1111-4111-8111-111111111111'::uuid,
        'dddddddd-4444-4444-8444-444444444444'::uuid],
  '2026-11-16 08:07:30+00',false,'2026-11-16 08:07:30+00',null,
  'item-second')->>'error',null,'the second entry lands');

-- The group delete cascade: an entry only in that group is deleted, an
-- entry also in a live group stays there, and the group's delete is the
-- only operation (no per-entry receipts).
select is(pg_temp.submit_group(
  'aaaaaaaa-1111-4111-8111-111111111111','first group',
  '2026-11-16 08:00:00+00',true,'2026-11-16 09:00:00+00',
  '2026-11-16 08:00:00+00','delete-group')->>'cascaded_entries','3',
  'the cascade deletes the three entries left with no live group');
select is((select deleted_at from public.my_adhkar_items
  where item_id='eeeeeeee-5555-4555-8555-555555555555')::text,
  '2026-11-16 09:00:00+00','the cascaded entry carries the delete instant');
select is((select deleted_at from public.my_adhkar_items
  where item_id='ffffffff-6666-4666-8666-666666666666'),null,
  'the entry also in a live group stays');
select is((select count(*) from public.my_adhkar_item_groups
  where group_id='aaaaaaaa-1111-4111-8111-111111111111'),0::bigint,
  'the deleted group lost every membership row');
reset role;
select is((select count(*) from public.my_adhkar_operation_receipts),7::bigint,
  'the cascade appends no per-entry receipt (only the seven operations)');
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"86666666-6666-4666-8666-666666666666","role":"authenticated"}',true);

-- `group_deleted`: a live edit whose only submitted group is deleted
-- deletes the entry with the submitted version kept as a conflict.
select is(pg_temp.submit_item(
  'ffffffff-6666-4666-8666-666666666666','edited text','source text 2',
  array['aaaaaaaa-1111-4111-8111-111111111111'::uuid],
  '2026-11-16 08:07:30+00',false,'2026-11-16 09:30:00+00',
  '2026-11-16 08:07:30+00','group-deleted-edit')->>'group_deleted',
  'true','an edit naming only deleted groups is group_deleted');
select is((select deleted_at from public.my_adhkar_items
  where item_id='ffffffff-6666-4666-8666-666666666666')::text,
  '2026-11-16 09:30:00+00','the group_deleted entry is deleted');
select is((select count(*) from public.my_adhkar_conflicts
  where entity_type='item'
    and entity_id='ffffffff-6666-4666-8666-666666666666'
    and retained_record->>'deleted_at' is null
    and retained_record->>'text'='edited text'),1::bigint,
  'the submitted version is kept as a visible conflict');

-- A delete stays final against older and newer edits.
select is(pg_temp.submit_item(
  '77777777-7777-4777-8777-777777777777','survivor',null,
  array['dddddddd-4444-4444-8444-444444444444'::uuid],
  '2026-11-16 08:20:00+00',false,'2026-11-16 08:20:00+00',null,
  'survivor-add')->>'error',null,'the delete-final entry lands');
select is(pg_temp.submit_item(
  '77777777-7777-4777-8777-777777777777','survivor',null,
  array[]::uuid[],
  '2026-11-16 08:20:00+00',true,'2026-11-16 09:00:00+00',
  '2026-11-16 08:20:00+00','survivor-delete')->'active_record'->>'deleted_at',
  '2026-11-16T09:00:00+00:00','the delete lands');
select is(pg_temp.submit_item(
  '77777777-7777-4777-8777-777777777777','older edit',null,
  array['dddddddd-4444-4444-8444-444444444444'::uuid],
  '2026-11-16 08:20:00+00',false,'2026-11-16 08:59:00+00',
  '2026-11-16 08:20:00+00','older-edit')->>'conflict_id',
  pg_temp.submit_item(
    '77777777-7777-4777-8777-777777777777','older edit',null,
    array['dddddddd-4444-4444-8444-444444444444'::uuid],
    '2026-11-16 08:20:00+00',false,'2026-11-16 08:59:00+00',
    '2026-11-16 08:20:00+00','older-edit-2')->>'conflict_id',
  'the older edit of a deleted entry produces one stable conflict id');
select is(pg_temp.submit_item(
  '77777777-7777-4777-8777-777777777777','newer edit',null,
  array['dddddddd-4444-4444-8444-444444444444'::uuid],
  '2026-11-16 08:20:00+00',false,'2026-11-16 10:00:00+00',
  '2026-11-16 08:20:00+00','newer-edit')->'active_record'->>'deleted_at',
  '2026-11-16T09:00:00+00:00',
  'a newer edit of a deleted entry is not applied; the deleted version stays');
select is((select count(*) from public.my_adhkar_conflicts
  where entity_id='77777777-7777-4777-8777-777777777777'
    and (active_record->>'deleted_at') is not null
    and (retained_record->>'deleted_at') is null),2::bigint,
  'both losing edits are conflicts; the deleted version stays active');

-- A delete wins even over a NEWER live edit the deleting device never saw;
-- the stored version still moves forward so other devices pull it, and the
-- live version it overrode is kept as a conflict.
select is(pg_temp.submit_item(
  '88888888-8888-4888-8888-888888888888','live v1',null,
  array['dddddddd-4444-4444-8444-444444444444'::uuid],
  '2026-11-16 08:30:00+00',false,'2026-11-16 08:30:00+00',null,
  'winner-add')->>'error',null,'the entry the two devices share lands');
select is(pg_temp.submit_item(
  '88888888-8888-4888-8888-888888888888','live v2 newer',null,
  array['dddddddd-4444-4444-8444-444444444444'::uuid],
  '2026-11-16 08:30:00+00',false,'2026-11-16 10:00:00+00',
  '2026-11-16 08:30:00+00','winner-edit')->>'error',null,
  'the newer live edit lands first');
select is(pg_temp.submit_item(
  '88888888-8888-4888-8888-888888888888','live v1',null,array[]::uuid[],
  '2026-11-16 08:30:00+00',true,'2026-11-16 09:15:00+00',
  '2026-11-16 08:30:00+00','winner-delete')->'active_record'->>'updated_at',
  '2026-11-16T10:00:00.000001+00:00',
  'the older delete still wins and the version moves one microsecond forward');
select is((select retained_record->>'text' from public.my_adhkar_conflicts
  where entity_id='88888888-8888-4888-8888-888888888888'),'live v2 newer',
  'the live version the delete overrode is kept as a conflict');

-- A deleted group stays deleted: a later rename is kept as a conflict.
select is(pg_temp.submit_group(
  'aaaaaaaa-1111-4111-8111-111111111111','renamed late',
  '2026-11-16 08:00:00+00',false,'2026-11-16 11:00:00+00',
  '2026-11-16 09:00:00+00','late-rename')->'active_record'->>'name',
  'first group','a rename of a deleted group is not applied');
select is((select retained_record->>'name' from public.my_adhkar_conflicts
  where entity_type='group'
    and entity_id='aaaaaaaa-1111-4111-8111-111111111111'),'renamed late',
  'the rename is kept as a conflict');

-- group_deleted on a CREATE: an entry added offline to a group another
-- device deleted is deleted and its version kept as a conflict.
select is(pg_temp.submit_item(
  '99999999-9999-4999-8999-999999999999','created offline',null,
  array['aaaaaaaa-1111-4111-8111-111111111111'::uuid],
  '2026-11-16 11:30:00+00',false,'2026-11-16 11:30:00+00',null,
  'create-on-deleted')->>'group_deleted','true',
  'a create naming only a deleted group is group_deleted');
select is((select deleted_at is not null from public.my_adhkar_items
  where item_id='99999999-9999-4999-8999-999999999999'),true,
  'that entry is stored as deleted');

-- Replay safety for a group operation.
select is(pg_temp.submit_group(
  'dddddddd-4444-4444-8444-444444444444','group 2',
  '2026-11-16 08:00:00+00',false,'2026-11-16 08:00:00+00',null,
  'group-2')->>'replayed','true',
  'an exact group replay is answered from the receipt');
select is(pg_temp.submit_group(
  'dddddddd-4444-4444-8444-444444444444','other name',
  '2026-11-16 08:00:00+00',false,'2026-11-16 08:00:00+00',null,
  'group-2')->>'error',
  'My Adhkar operation ID reused with different content',
  'a group operation ID reused with different content is rejected');

-- The 100-group and 1000-entry limits count live rows only. The first
-- group and every entry so far are deleted, so the counters start from the
-- one live group and no live entry.
do $$
declare
  g uuid := 'dddddddd-4444-4444-8444-444444444444';
  r jsonb;
begin
  for k in 1..99 loop
    r := pg_temp.submit_group(
      ('aaaaaaaa-1111-4111-8111-' || lpad(k::text,12,'0'))::uuid,
      'group ' || k,'2026-11-16 08:00:00+00',false,
      '2026-11-16 08:00:00+00',null,'limit-group-' || k);
    if r ? 'error' then
      raise exception 'group seed % failed: %',k,r->>'error';
    end if;
  end loop;
  r := pg_temp.submit_group(
    'aaaaaaaa-ffff-4111-8111-111111111111','one more',
    '2026-11-16 08:00:00+00',false,'2026-11-16 08:00:00+00',null,
    'limit-group-over');
  perform set_config('my.group_limit',coalesce(r->>'error','accepted'),true);
  for k in 0..999 loop
    r := pg_temp.submit_item(
      ('bbbbbbbb-2222-4222-8222-' || lpad(k::text,12,'0'))::uuid,
      'entry ' || k,null,array[g],'2026-11-16 08:10:00+00',false,
      '2026-11-16 08:10:00+00',null,'limit-item-' || k);
    if r ? 'error' then
      raise exception 'entry seed % failed: %',k,r->>'error';
    end if;
  end loop;
  r := pg_temp.submit_item(
    'bbbbbbbb-2222-4222-8222-ffffffffffff','one more entry',null,array[g],
    '2026-11-16 08:10:00+00',false,'2026-11-16 08:10:00+00',null,
    'limit-item-over');
  perform set_config('my.item_limit',coalesce(r->>'error','accepted'),true);
end $$;
select is(current_setting('my.group_limit'),'My Adhkar group limit reached',
  'the 101st live group is rejected');
select is(current_setting('my.item_limit'),'My Adhkar entry limit reached',
  'the 1001st live entry is rejected');
select is((select count(*) from public.xp_awards),0::bigint,
  'no xp_awards row is ever written by My Adhkar');

reset role;
select * from finish();
rollback;
