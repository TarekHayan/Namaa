-- Foundation account-isolation tests (T024).
--
-- Run with `supabase test db` against the local Supabase stack only
-- (supabase/config.toml). Proves, for the foundation_probe table:
--   1. the owning account may read and write its rows, and
--   2. a different authenticated account is denied read and write access.
-- Ownership always comes from the authenticated session (auth.uid()); a
-- caller-supplied owner value can never grant access.

begin;

select plan(11);

-- Two isolated accounts -----------------------------------------------------
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  created_at, updated_at
) values
  ('00000000-0000-0000-0000-000000000000',
   '11111111-1111-1111-1111-111111111111',
   'authenticated', 'authenticated', 'owner@example.com', 'x',
   now(), now()),
  ('00000000-0000-0000-0000-000000000000',
   '22222222-2222-2222-2222-222222222222',
   'authenticated', 'authenticated', 'other@example.com', 'x',
   now(), now());

-- Helper: act as an account by installing its JWT claims.
create schema if not exists tests;
grant usage on schema tests to authenticated;

create or replace function tests.authenticate_as(uid uuid)
returns void language plpgsql as $$
begin
  execute 'set role authenticated';
  perform set_config('request.jwt.claims',
    json_build_object('sub', uid::text, 'role', 'authenticated')::text,
    true);
end;
$$;

grant execute on function tests.authenticate_as(uuid) to authenticated;

select ok(
  not has_function_privilege(
    'anon',
    'public.apply_foundation_change(uuid,text,text,timestamptz,text)',
    'EXECUTE'
  ),
  'anonymous role cannot execute the foundation synchronization RPC'
);

-- ------------------------------------------------------------------ owner ---
select tests.authenticate_as('11111111-1111-1111-1111-111111111111');

-- Owner insert with a matching owner value is allowed.
insert into public.foundation_probe (id, owner, payload, operation_id)
values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        '11111111-1111-1111-1111-111111111111',
        'probe payload', 'op-1');
select is(
  (select count(*) from public.foundation_probe), 1::bigint,
  'owner can insert its own row');

-- Owner insert claiming ANOTHER account as owner is rejected by RLS.
select throws_ok(
  $sql$ insert into public.foundation_probe (id, owner, payload, operation_id)
        values ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
                '22222222-2222-2222-2222-222222222222',
                'spoofed owner', 'op-2') $sql$,
  '42501',
  NULL,
  'a caller-supplied owner id cannot establish ownership');

-- Owner update of its own row is allowed.
update public.foundation_probe set payload = 'probe payload v2'
where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
select is(
  (select payload from public.foundation_probe
    where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  'probe payload v2',
  'owner can update its own row');

-- Owner delete of its own row is allowed.
delete from public.foundation_probe
where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
select is(
  (select count(*) from public.foundation_probe), 0::bigint,
  'owner can delete its own row');

-- Reinsert for the cross-account section.
insert into public.foundation_probe (id, owner, payload, operation_id)
values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        '11111111-1111-1111-1111-111111111111',
        'probe payload', 'op-1');

-- The RPC updates and deletes an existing row when the incoming version is
-- newer. This protects normal sequential synchronization from being treated
-- as a permanent conflict.
select is(
  (select payload from public.apply_foundation_change(
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'probe payload v3',
    'op-rpc-update',
    now() + interval '1 minute',
    'update'
  )),
  'probe payload v3',
  'RPC updates an existing owner row when the incoming version is newer'
);
select * from public.apply_foundation_change(
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  '',
  'op-rpc-delete',
  now() + interval '2 minutes',
  'delete'
);
select is(
  (select count(*) from public.foundation_probe),
  0::bigint,
  'RPC deletes an existing owner row when the incoming version is newer'
);

-- Reinsert for the cross-account section.
insert into public.foundation_probe (id, owner, payload, operation_id)
values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        '11111111-1111-1111-1111-111111111111',
        'probe payload', 'op-1');

-- ------------------------------------------------------- different account ---
select tests.authenticate_as('22222222-2222-2222-2222-222222222222');

-- Cross-account read is denied (RLS filters the row out entirely).
select is(
  (select count(*) from public.foundation_probe), 0::bigint,
  'another account cannot read the owner row');

-- Cross-account update is denied (0 rows match, nothing changes).
update public.foundation_probe set payload = 'hijacked'
where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
select is(
  (select count(*) from public.foundation_probe
    where payload = 'hijacked'), 0::bigint,
  'another account cannot update the owner row');

-- Cross-account insert for the owner account is rejected by RLS.
select throws_ok(
  $sql$ insert into public.foundation_probe (id, owner, payload, operation_id)
        values ('cccccccc-cccc-cccc-cccc-cccccccccccc',
                '11111111-1111-1111-1111-111111111111',
                'cross-account insert', 'op-3') $sql$,
  '42501',
  NULL,
  'another account cannot insert a row for the owner');

-- Cross-account delete is denied (0 rows match, row survives).
delete from public.foundation_probe
where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

-- Authenticate as owner again to verify the row was untouched.
select tests.authenticate_as('11111111-1111-1111-1111-111111111111');
select is(
  (select count(*) from public.foundation_probe), 1::bigint,
  'another account cannot delete the owner row');

select * from finish();
rollback;
