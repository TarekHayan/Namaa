-- Task completion and one-time XP integrity tests (T044).
-- This test is intentionally red until 0005_task_xp_completion.sql extends
-- apply_task_change() with atomic first-completion award behavior.

begin;

select plan(38);

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  created_at, updated_at
) values
  ('00000000-0000-0000-0000-000000000000',
   '51111111-1111-1111-1111-111111111111',
   'authenticated', 'authenticated', 'xp-owner@example.com', 'x',
   now(), now()),
  ('00000000-0000-0000-0000-000000000000',
   '52222222-2222-2222-2222-222222222222',
   'authenticated', 'authenticated', 'xp-other@example.com', 'x',
   now(), now());

create schema if not exists tests;
grant usage on schema tests to authenticated;

create or replace function tests.authenticate_as(uid uuid)
returns void language plpgsql as $$
begin
  execute 'set role authenticated';
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', uid::text, 'role', 'authenticated')::text,
    true
  );
end;
$$;

grant execute on function tests.authenticate_as(uuid) to authenticated;
select tests.authenticate_as('51111111-1111-1111-1111-111111111111');

select lives_ok($sql$ select public.apply_task_change(
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  '{"title":"Rewarded Task","completedAt":null,"completionXp":35}'::jsonb,
  'create-open',
  '2026-10-11T08:00:00Z',
  'create'
) $sql$, 'creating an open Task succeeds');
select is(
  (select count(*) from public.xp_awards),
  0::bigint,
  'creating an open Task does not create an XP award'
);

select is(
  (select replayed from public.apply_task_change(
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    '{"title":"Rewarded Task","completedAt":"2026-10-11T09:00:00Z","completionXp":99}'::jsonb,
    'complete-first',
    '2026-10-11T09:00:00Z',
    'update'
  )),
  false,
  'first completion is applied as a new operation'
);
select is(
  (select payload->>'completedAt' from public.tasks
   where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'),
  '2026-10-11T09:00:00Z',
  'first completion and its timestamp are persisted'
);
select is(
  (select count(*) from public.xp_awards),
  1::bigint,
  'first completion atomically creates one award'
);
select is(
  (select amount from public.xp_awards
   where source = 'task_done'
     and source_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'),
  20,
  'award uses the server-controlled completion XP'
);
select is(
  (select awarded_at from public.xp_awards
   where source = 'task_done'
     and source_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'),
  '2026-10-11T09:00:00Z'::timestamptz,
  'award keeps the first completion instant'
);

select is(
  (select replayed from public.apply_task_change(
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    '{"title":"Ignored retry","completedAt":"2026-10-11T10:00:00Z","completionXp":99}'::jsonb,
    'complete-first',
    '2026-10-11T10:00:00Z',
    'update'
  )),
  true,
  'duplicate completion operation ID replays its durable receipt'
);
select is(
  (select count(*) from public.xp_awards),
  1::bigint,
  'duplicate operation ID cannot duplicate the award'
);
select is(
  (select amount from public.xp_awards),
  20,
  'duplicate operation cannot change the first reward snapshot'
);

select lives_ok($sql$ select public.apply_task_change(
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  '{"title":"Rewarded Task","completedAt":null,"completionXp":35}'::jsonb,
  'reopen-one',
  '2026-10-11T10:00:00Z',
  'update'
) $sql$, 'reopening a rewarded Task succeeds');
select is(
  (select payload->>'completedAt' from public.tasks
   where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'),
  null,
  'reopening clears the current completion time'
);
select is(
  (select count(*) from public.xp_awards),
  1::bigint,
  'reopening retains the lifetime award'
);

select lives_ok($sql$ select public.apply_task_change(
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  '{"title":"Rewarded Task","completedAt":"2026-10-11T11:00:00Z","completionXp":99}'::jsonb,
  'complete-second',
  '2026-10-11T11:00:00Z',
  'update'
) $sql$, 'recompleting a rewarded Task succeeds');
select is(
  (select payload->>'completedAt' from public.tasks
   where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'),
  '2026-10-11T11:00:00Z',
  'a distinct recompletion updates current Task state'
);
select is(
  (select count(*) from public.xp_awards),
  1::bigint,
  'a distinct recompletion operation still cannot add an award'
);
select is(
  (select awarded_at from public.xp_awards),
  '2026-10-11T09:00:00Z'::timestamptz,
  'recompletion cannot replace the first award instant'
);

select tests.authenticate_as('52222222-2222-2222-2222-222222222222');
select is(
  (select count(*) from public.tasks),
  0::bigint,
  'another account cannot read the owner Task'
);
select is(
  (select count(*) from public.xp_awards),
  0::bigint,
  'another account cannot read the owner award'
);
select lives_ok($sql$ select public.apply_task_change(
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  '{"title":"Other account Task","completedAt":"2026-10-11T12:00:00Z","completionXp":20}'::jsonb,
  'other-complete',
  '2026-10-11T12:00:00Z',
  'create'
) $sql$, 'the other account can complete its own Task partition');
select is(
  (select count(*) from public.xp_awards),
  1::bigint,
  'same Task ID may award once in the other account partition'
);
select ok(
  exists(
    select 1 from public.xp_awards
    where owner = '52222222-2222-2222-2222-222222222222'
      and source = 'task_done'
      and source_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
  ),
  'the other account award is owned by its authenticated caller'
);

select tests.authenticate_as('51111111-1111-1111-1111-111111111111');
select is(
  (select count(*) from public.xp_awards),
  1::bigint,
  'owner still sees exactly its own first award'
);
select lives_ok($sql$ select public.apply_task_change(
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  '{}'::jsonb,
  'delete-rewarded',
  '2026-10-11T13:00:00Z',
  'delete'
) $sql$, 'deleting a rewarded Task succeeds');
select ok(
  (select deleted_at is not null from public.tasks
   where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'),
  'deleting a rewarded Task leaves a tombstone'
);
select is(
  (select count(*) from public.xp_awards),
  1::bigint,
  'deleting a rewarded Task retains its earned award'
);

-- The completion on device A is older than device B's edit, so it loses the
-- Task version conflict. Its one-time XP effect must still reach the ledger.
select lives_ok($sql$ select public.apply_task_change(
  'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
  '{"title":"Open on both devices","completedAt":null,"completionXp":35}'::jsonb,
  'stale-award-create',
  '2026-10-11T08:00:00Z',
  'create'
) $sql$, 'shared Task starts open');
select lives_ok($sql$ select public.apply_task_change(
  'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
  '{"title":"Newer device edit","completedAt":null,"completionXp":35}'::jsonb,
  'stale-award-newer-edit',
  '2026-10-11T10:00:00Z',
  'update'
) $sql$, 'newer edit reaches the server first');
select is(
  (select conflict_detected from public.apply_task_change(
    'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
    '{"title":"Open on both devices","completedAt":"2026-10-11T09:00:00Z","completionXp":99}'::jsonb,
    'stale-award-complete',
    '2026-10-11T09:00:00Z',
    'update'
  )),
  true,
  'older offline completion retains Task conflict evidence'
);
select is(
  (select payload->>'title' from public.tasks
   where id = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc'),
  'Newer device edit',
  'the newer Task edit remains active'
);
select is(
  (select count(*) from public.xp_awards
   where source_id = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc'),
  1::bigint,
  'the losing completion still records one lifetime award'
);
select is(
  (select amount from public.xp_awards
   where source_id = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc'),
  20,
  'the award uses the server-controlled reward'
);
select is(
  (select awarded_at from public.xp_awards
   where source_id = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc'),
  '2026-10-11T09:00:00Z'::timestamptz,
  'the award retains the losing completion instant'
);
select is(
  (select replayed from public.apply_task_change(
    'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
    '{"title":"Retry","completedAt":"2026-10-11T09:00:00Z","completionXp":99}'::jsonb,
    'stale-award-complete',
    '2026-10-11T09:00:00Z',
    'update'
  )),
  true,
  'retrying the losing completion replays its original operation receipt'
);

select throws_ok(
  $sql$ select public.apply_task_change(
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
    '{"title":"Invalid reward","completedAt":"2026-10-11T14:00:00Z","completionXp":-1}'::jsonb,
    'invalid-completion',
    '2026-10-11T14:00:00Z',
    'create'
  ) $sql$,
  '23514', NULL,
  'an invalid first award aborts the completion operation'
);
select is(
  (select count(*) from public.tasks
   where id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'),
  0::bigint,
  'failed award insertion rolls back the Task row'
);
select is(
  (select count(*) from public.xp_awards
   where source_id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'),
  0::bigint,
  'failed completion leaves no partial award'
);
reset role;
select is(
  (select count(*) from public.task_operation_receipts
   where operation_id = 'invalid-completion'),
  0::bigint,
  'failed completion leaves no partial operation receipt'
);

select * from finish();
rollback;
