-- T017: Adhkar operation integrity: receipts, replay, convergence and
-- newest-wins resolution, per contracts/adhkar-qiyam-sync.md.
begin;
select plan(11);
insert into auth.users(instance_id,id,aud,role,email,encrypted_password,created_at,updated_at)
values('00000000-0000-0000-0000-000000000000',
  '86666666-6666-4666-8666-666666666666','authenticated','authenticated',
  'adhkar-op@example.com','x',now(),now());

create function pg_temp.submit(p_day date,p_item text,p_count integer,
  p_version timestamptz,p_base timestamptz,p_op text)
returns jsonb language sql as $$
  select public.apply_adhkar_item_change_v1(p_day,p_item,1,p_count,
    p_version,p_base,p_op);
$$;

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"86666666-6666-4666-8666-666666666666","role":"authenticated"}',true);

-- First insert with no base. m4 (target 3) carries the count progression.
select is(pg_temp.submit('2026-11-09','m4',1,'2026-11-09 06:00:00+00',null,
  'op-1')->>'replayed','false','first operation is not a replay');
select is(pg_temp.submit('2026-11-09','m4',1,'2026-11-09 06:00:00+00',null,
  'op-1')->>'replayed','true','exact replay returns the original outcome');
select is((select count(*) from public.adhkar_item_counts
  where item_id='m4'),1::bigint,'replay does not duplicate rows');
select throws_ok(
  'select public.apply_adhkar_item_change_v1(''2026-11-09''::date,''m4'',1,2,
   ''2026-11-09 06:00:00+00''::timestamptz,null,''op-1'')',
  '22023','Adhkar operation ID reused with different content',
  'a reused operation ID with different content is rejected');

-- Matching base convergence: no conflict, no error.
select is(pg_temp.submit('2026-11-09','m4',2,'2026-11-09 07:00:00+00',
  '2026-11-09 06:00:00+00','op-2')->>'conflict_id',null,
  'a matching base converges without conflict');
-- Identical content under a new operation also converges.
select is(pg_temp.submit('2026-11-09','m4',2,'2026-11-09 07:00:00+00',null,
  'op-2-identical')->>'conflict_id',null,
  'identical content is ordinary convergence');
-- A divergent version without the base produces a conflict (see conflicts
-- test for the retained evidence); here the newer count wins the record.
select ok(pg_temp.submit('2026-11-09','m4',3,'2026-11-09 08:00:00+00',null,
  'op-3') ? 'active_record','a divergent newer version still lands');
select is((select count from public.adhkar_item_counts where item_id='m4'),
  3,'the newest version is active');

-- An older arrival loses the record. m8 (target 100) carries the counts.
select ok(pg_temp.submit('2026-11-09','m8',5,'2026-11-09 09:00:00+00',null,
  'op-m8-new') ? 'active_record','the newer m8 version is stored first');
select ok(pg_temp.submit('2026-11-09','m8',2,'2026-11-09 08:00:00+00',null,
  'op-m8-old') ? 'active_record','the older m8 arrival still returns an outcome');
select is((select count from public.adhkar_item_counts where item_id='m8'),
  5,'the older arrival does not replace the newer version');

reset role;
select * from finish();
rollback;
