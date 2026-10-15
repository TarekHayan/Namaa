-- Task account isolation and mutation-boundary tests (T004).
-- Direct client mutations are denied. Authenticated Task changes must pass
-- through apply_task_change(), which derives ownership from auth.uid().

begin;

select plan(21);

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  created_at, updated_at
) values
  ('00000000-0000-0000-0000-000000000000',
   '31111111-1111-1111-1111-111111111111',
   'authenticated', 'authenticated', 'task-owner@example.com', 'x',
   now(), now()),
  ('00000000-0000-0000-0000-000000000000',
   '32222222-2222-2222-2222-222222222222',
   'authenticated', 'authenticated', 'task-other@example.com', 'x',
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

select ok(
  not has_function_privilege(
    'anon',
    'public.apply_task_change(uuid,jsonb,text,timestamptz,text)',
    'EXECUTE'
  ),
  'anonymous callers cannot execute the Task synchronization RPC'
);
select ok(
  not has_table_privilege('anon', 'public.tasks', 'SELECT'),
  'anonymous callers cannot read Task rows'
);
select ok(
  not has_table_privilege('anon', 'public.tasks', 'INSERT')
  and not has_table_privilege('anon', 'public.tasks', 'UPDATE')
  and not has_table_privilege('anon', 'public.tasks', 'DELETE'),
  'anonymous callers cannot mutate Task rows'
);

-- Award rows are server-owned and immutable to authenticated clients.
insert into public.xp_awards (owner, source, source_id, amount, awarded_at)
values (
  '31111111-1111-1111-1111-111111111111',
  'task_completion',
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  15,
  '2026-10-08T09:00:00Z'
);

select tests.authenticate_as('31111111-1111-1111-1111-111111111111');

select is(
  (select owner from public.apply_task_change(
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    '{"title":"Owner task"}'::jsonb,
    'owner-create',
    '2026-10-08T08:00:00Z',
    'create'
  )),
  '31111111-1111-1111-1111-111111111111'::uuid,
  'Task RPC derives the owner from the authenticated session'
);
select is(
  (select count(*) from public.tasks),
  1::bigint,
  'owner can read its Task row'
);
select is(
  (select count(*) from public.xp_awards),
  1::bigint,
  'owner can read its immutable XP award'
);

select throws_ok(
  $sql$ insert into public.tasks
        (owner, id, payload, updated_at)
        values (
          '31111111-1111-1111-1111-111111111111',
          'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
          '{}'::jsonb,
          now()
        ) $sql$,
  '42501', NULL,
  'authenticated clients cannot insert Task rows directly'
);
select throws_ok(
  $sql$ update public.tasks set payload = '{"title":"direct"}'::jsonb
        where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' $sql$,
  '42501', NULL,
  'authenticated clients cannot update Task rows directly'
);
select throws_ok(
  $sql$ delete from public.tasks
        where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' $sql$,
  '42501', NULL,
  'authenticated clients cannot delete Task rows directly'
);
select throws_ok(
  $sql$ insert into public.xp_awards
        (owner, source, source_id, amount, awarded_at)
        values (
          '31111111-1111-1111-1111-111111111111',
          'task_completion',
          'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
          15,
          now()
        ) $sql$,
  '42501', NULL,
  'authenticated clients cannot create XP awards directly'
);
select throws_ok(
  $sql$ update public.xp_awards set amount = 99
        where source_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' $sql$,
  '42501', NULL,
  'authenticated clients cannot update XP awards'
);
select throws_ok(
  $sql$ delete from public.xp_awards
        where source_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' $sql$,
  '42501', NULL,
  'authenticated clients cannot delete XP awards'
);
select throws_ok(
  $sql$ select count(*) from public.task_operation_receipts $sql$,
  '42501', NULL,
  'operation receipts are internal and unreadable by clients'
);
select ok(
  not has_table_privilege(
    'authenticated', 'public.task_operation_receipts', 'INSERT'
  )
  and not has_table_privilege(
    'authenticated', 'public.task_operation_receipts', 'UPDATE'
  )
  and not has_table_privilege(
    'authenticated', 'public.task_operation_receipts', 'DELETE'
  ),
  'authenticated clients cannot mutate operation receipts directly'
);

select tests.authenticate_as('32222222-2222-2222-2222-222222222222');

select is(
  (select count(*) from public.tasks),
  0::bigint,
  'a different account cannot read the owner Task row'
);
select is(
  (select count(*) from public.xp_awards),
  0::bigint,
  'a different account cannot read the owner XP award'
);
select throws_ok(
  $sql$ insert into public.tasks
        (owner, id, payload, updated_at)
        values (
          '31111111-1111-1111-1111-111111111111',
          'cccccccc-cccc-cccc-cccc-cccccccccccc',
          '{"title":"spoofed"}'::jsonb,
          now()
        ) $sql$,
  '42501', NULL,
  'a caller cannot spoof another Task owner'
);
select is(
  (select owner from public.apply_task_change(
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    '{"title":"Other account task"}'::jsonb,
    'other-create',
    '2026-10-08T08:01:00Z',
    'create'
  )),
  '32222222-2222-2222-2222-222222222222'::uuid,
  'same Task id remains scoped to the current authenticated account'
);

select tests.authenticate_as('31111111-1111-1111-1111-111111111111');
select is(
  (select payload->>'title' from public.tasks
    where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  'Owner task',
  'different-account synchronization does not change the owner Task'
);
select is(
  (select count(*) from public.tasks),
  1::bigint,
  'owner sees only its own row after same-id synchronization'
);
select is(
  (select amount from public.xp_awards
    where source_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  15,
  'owner award remains unchanged after denied client mutations'
);

select * from finish();
rollback;
