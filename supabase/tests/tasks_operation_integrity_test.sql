-- Task synchronization operation-integrity tests (T005).
-- Stable operation IDs are replay-safe, deletes leave durable tombstones,
-- and old retries cannot resurrect deleted records.

begin;

select plan(22);

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  created_at, updated_at
) values (
  '00000000-0000-0000-0000-000000000000',
  '41111111-1111-1111-1111-111111111111',
  'authenticated', 'authenticated', 'task-sync@example.com', 'x',
  now(), now()
);

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
select tests.authenticate_as('41111111-1111-1111-1111-111111111111');

select is(
  (select replayed from public.apply_task_change(
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    '{"title":"Version 1"}'::jsonb,
    'create-op',
    '2026-10-08T08:00:00Z',
    'create'
  )),
  false,
  'first create operation is applied once'
);
select is(
  (select payload->>'title' from public.tasks
    where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  'Version 1',
  'create stores the Task payload'
);
select is(
  (select count(*) from public.tasks where deleted_at is null),
  1::bigint,
  'created Task is active rather than tombstoned'
);
reset role;
select is(
  (select count(*) from public.task_operation_receipts),
  1::bigint,
  'create stores one durable operation receipt'
);
select tests.authenticate_as('41111111-1111-1111-1111-111111111111');

select is(
  (select replayed from public.apply_task_change(
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    '{"title":"must not replace Version 1"}'::jsonb,
    'create-op',
    '2026-10-08T08:30:00Z',
    'create'
  )),
  true,
  'repeating the create operation ID is recognized as a replay'
);
select is(
  (select payload->>'title' from public.apply_task_change(
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    '{"title":"must not replace Version 1"}'::jsonb,
    'create-op',
    '2026-10-08T08:30:00Z',
    'create'
  )),
  'Version 1',
  'create replay returns the original stable result'
);
reset role;
select is(
  (select count(*) from public.task_operation_receipts),
  1::bigint,
  'create replay does not duplicate its receipt'
);
select tests.authenticate_as('41111111-1111-1111-1111-111111111111');

select is(
  (select replayed from public.apply_task_change(
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    '{"title":"Version 2"}'::jsonb,
    'update-op',
    '2026-10-08T09:00:00Z',
    'update'
  )),
  false,
  'first update operation is applied once'
);
select is(
  (select payload->>'title' from public.tasks
    where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  'Version 2',
  'newer update becomes the active Task version'
);
select is(
  (select conflict_detected from public.apply_task_change(
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    '{"title":"Version 2"}'::jsonb,
    'update-op',
    '2026-10-08T09:00:00Z',
    'update'
  )),
  true,
  'update result records that a previous version was retained'
);
select is(
  (select retained_payload->>'title' from public.apply_task_change(
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    '{"title":"Version 2"}'::jsonb,
    'update-op',
    '2026-10-08T09:00:00Z',
    'update'
  )),
  'Version 1',
  'update receipt retains the displaced payload for conflict evidence'
);
select is(
  (select replayed from public.apply_task_change(
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    '{"title":"ignored update retry"}'::jsonb,
    'update-op',
    '2026-10-08T10:00:00Z',
    'update'
  )),
  true,
  'repeating the update operation ID is replay-safe'
);
reset role;
select is(
  (select count(*) from public.task_operation_receipts),
  2::bigint,
  'update replay does not duplicate its receipt'
);
select tests.authenticate_as('41111111-1111-1111-1111-111111111111');

select ok(
  (select deleted_at is not null from public.apply_task_change(
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    '{}'::jsonb,
    'delete-op',
    '2026-10-08T10:00:00Z',
    'delete'
  )),
  'delete produces a tombstoned Task result'
);
select is(
  (select count(*) from public.tasks
    where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  1::bigint,
  'delete retains one durable tombstone row'
);
reset role;
select is(
  (select count(*) from public.task_operation_receipts),
  3::bigint,
  'delete stores its durable operation receipt'
);
select tests.authenticate_as('41111111-1111-1111-1111-111111111111');
select is(
  (select replayed from public.apply_task_change(
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    '{"title":"must not resurrect"}'::jsonb,
    'delete-op',
    '2026-10-08T11:00:00Z',
    'delete'
  )),
  true,
  'repeating the delete operation ID is replay-safe'
);
select ok(
  (select deleted_at is not null from public.tasks
    where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  'delete replay leaves the tombstone intact'
);

select is(
  (select conflict_detected from public.apply_task_change(
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    '{"title":"stale create retry"}'::jsonb,
    'late-stale-create-op',
    '2026-10-08T08:00:00Z',
    'create'
  )),
  true,
  'an older create after delete is reported as a version conflict'
);
select ok(
  (select deleted_at is not null from public.tasks
    where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  'an older create retry cannot resurrect a tombstoned Task'
);
reset role;
select is(
  (select count(*) from public.task_operation_receipts),
  4::bigint,
  'the stale retry also receives one durable receipt'
);
select is(
  (select count(distinct operation_id)
    from public.task_operation_receipts),
  4::bigint,
  'all operation receipts survive the tombstone'
);

select * from finish();
rollback;
