-- T018: Qiyam conflict integrity: one stable conflict per divergent pair,
-- arrival-order independent, with the equal-timestamp tie broken by the
-- semantic key performed|rakahs|witr|start|end|note-hash|zone|offset.
begin;
select plan(7);
insert into auth.users(instance_id,id,aud,role,email,encrypted_password,created_at,updated_at)
values('00000000-0000-0000-0000-000000000000',
  '86666666-6666-4666-8666-666666666666','authenticated','authenticated',
  'qiyam-conflict@example.com','x',now(),now());

create function pg_temp.submit(p_performed boolean,p_rakahs integer,
  p_witr boolean,p_start text,p_end text,p_note text,
  p_version timestamptz,p_base timestamptz,p_op text)
returns jsonb language sql as $$
  select public.apply_qiyam_night_change_v1('2026-11-09',p_performed,
    p_rakahs,p_witr,p_start,p_end,p_note,'Africa/Cairo',120,
    p_version,p_base,p_op);
$$;

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"86666666-6666-4666-8666-666666666666","role":"authenticated"}',true);

-- Device A: Yes with 4 rakahs at 01:00 (acknowledged). Device B diverges to
-- 8 rakahs at 02:00.
-- Device A answers Yes (4) twice in order: 00:30 with no base, then 01:00
-- with an acknowledged base. Device B, stale at 00:30, diverges to 8 at
-- 02:00, so the divergence keeps one conflict.
select pg_temp.submit(true,4,true,'03:10','04:00',null,
  '2026-11-10 00:30:00+00',null,'op-a0');
select pg_temp.submit(true,4,true,'03:10','04:00',null,
  '2026-11-10 01:00:00+00','2026-11-10 00:30:00+00','op-a1');
select pg_temp.submit(true,8,true,'03:00','04:00',null,
  '2026-11-10 02:00:00+00','2026-11-10 00:30:00+00','op-b');
select is((select rakahs from public.qiyam_nights),8,
  'the newer divergent version is active');
select is((select count(*) from public.qiyam_conflicts),1::bigint,
  'exactly one conflict is retained');

-- The conflict ID is the shared-namespace UUIDv5 of the ordered descriptors
-- (both versions carry no note, so the descriptor holds the literal null).
select is((select conflict_id from public.qiyam_conflicts),
  extensions.uuid_generate_v5(
    '70ca78e3-a267-4a2f-883f-1e0dea2df0c3'::uuid,
    'conflict/' || public.qiyam_record_id_v1('2026-11-09')::text
    || '/1794272400000000:true|4|true|03:10|04:00|null|Africa/Cairo|120'
    || '/' || '1794276000000000:true|8|true|03:00|04:00|null|Africa/Cairo|120'),
  'the conflict ID matches the shared NS009 construction');

select pg_temp.submit(true,4,true,'03:10','04:00',null,
  '2026-11-10 00:30:00+00',null,'op-a0');
select is((select count(*) from public.qiyam_conflicts),1::bigint,
  'a replay does not duplicate the conflict');

-- Equal timestamps: the greater semantic key (rakahs 8 over 4) wins
-- whichever side arrives last. The second arrival carries a stale base.
select pg_temp.submit(true,8,true,'02:00','04:00',null,
  '2026-11-10 04:00:00+00','2026-11-10 00:30:00+00','op-tie-8');
select pg_temp.submit(true,4,true,'02:00','04:00',null,
  '2026-11-10 04:00:00+00','2026-11-10 04:00:00+00','op-tie-4');
select is((select rakahs from public.qiyam_nights),8,
  'the greater semantic key wins the equal-timestamp tie');
select is((select count(*) from public.qiyam_conflicts),2::bigint,
  'each divergent pair keeps its own conflict row');

-- The retained version of the first conflict is the losing 4-rakah Yes.
select is((select retained_record->>'rakahs' from public.qiyam_conflicts
  order by detected_at limit 1),'4','the losing version stays visible');

reset role;
select * from finish();
rollback;
