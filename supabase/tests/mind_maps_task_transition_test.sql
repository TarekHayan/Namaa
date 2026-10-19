begin;
select plan(10);

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, created_at, updated_at
) values
  ('00000000-0000-0000-0000-000000000000',
   'a3111111-1111-4111-8111-111111111111', 'authenticated', 'authenticated',
   'map-transition-owner@example.com', 'x', now(), now()),
  ('00000000-0000-0000-0000-000000000000',
   'a3222222-2222-4222-8222-222222222222', 'authenticated', 'authenticated',
   'map-transition-other@example.com', 'x', now(), now());

create schema if not exists tests;
grant usage on schema tests to authenticated;
create or replace function tests.authenticate_as(uid uuid)
returns void language plpgsql as $$
begin
  execute 'set role authenticated';
  perform set_config('request.jwt.claims',
    json_build_object('sub', uid::text, 'role', 'authenticated')::text, true);
end;
$$;
grant execute on function tests.authenticate_as(uuid) to authenticated;
select tests.authenticate_as('a3111111-1111-4111-8111-111111111111');

select lives_ok($sql$ select public.apply_task_change(
  'a3333333-3333-4333-8333-333333333333',
  '{"title":"Linked","createdAt":"2026-10-19T08:00:00Z","completedAt":null,"completionXp":20}'::jsonb,
  'map-transition-create', '2026-10-19T08:00:00Z', 'create'
) $sql$, 'open Task is created');
select is((select completion_changed_at from public.tasks where id =
  'a3333333-3333-4333-8333-333333333333'),
  '2026-10-19T08:00:00Z'::timestamptz, 'open baseline is creation');

select lives_ok($sql$ select public.apply_task_change(
  'a3333333-3333-4333-8333-333333333333',
  '{"title":"Linked","createdAt":"2026-10-19T08:00:00Z","completedAt":"2026-10-19T09:00:00Z","completionChangedAt":"2026-10-19T09:00:00Z","completionXp":20}'::jsonb,
  'map-transition-complete', '2026-10-19T09:00:00Z', 'update'
) $sql$, 'Task completes');
select is((select completion_changed_at from public.tasks where id =
  'a3333333-3333-4333-8333-333333333333'),
  '2026-10-19T09:00:00Z'::timestamptz, 'completion advances transition');

select lives_ok($sql$ select public.apply_task_change(
  'a3333333-3333-4333-8333-333333333333',
  '{"title":"Renamed","createdAt":"2026-10-19T08:00:00Z","completedAt":"2026-10-19T09:00:00Z","completionChangedAt":"2026-10-19T10:00:00Z","completionXp":20}'::jsonb,
  'map-transition-rename', '2026-10-19T10:00:00Z', 'update'
) $sql$, 'metadata can change');
select is((select completion_changed_at from public.tasks where id =
  'a3333333-3333-4333-8333-333333333333'),
  '2026-10-19T09:00:00Z'::timestamptz, 'metadata cannot advance transition');

select lives_ok($sql$ select public.apply_task_change(
  'a3333333-3333-4333-8333-333333333333',
  '{"title":"Renamed","createdAt":"2026-10-19T08:00:00Z","completedAt":null,"completionChangedAt":"2026-10-19T11:00:00Z","completionXp":20}'::jsonb,
  'map-transition-reopen', '2026-10-19T11:00:00Z', 'update'
) $sql$, 'Task reopens');
select is((select count(*) from public.xp_awards where source = 'task_done'
  and source_id = 'a3333333-3333-4333-8333-333333333333'),
  1::bigint, 'replay and reopen retain one lifetime XP award');

select ok((select replayed from public.apply_task_change(
  'a3333333-3333-4333-8333-333333333333',
  '{"title":"Renamed","createdAt":"2026-10-19T08:00:00Z","completedAt":null,"completionChangedAt":"2026-10-19T11:00:00Z","completionXp":20}'::jsonb,
  'map-transition-reopen', '2026-10-19T11:00:00Z', 'update'
)), 'duplicate delivery replays the receipt');

select tests.authenticate_as('a3222222-2222-4222-8222-222222222222');
select is((select count(*) from public.tasks where id =
  'a3333333-3333-4333-8333-333333333333'),
  0::bigint, 'other account cannot read linked Task transition');

select * from finish();
rollback;
