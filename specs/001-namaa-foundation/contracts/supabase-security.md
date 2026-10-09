# Contract: Supabase Security and Environment Boundary

## Purpose

Define the Foundation boundary for Supabase authentication and account-scoped cloud access. This
contract establishes infrastructure constraints only; it defines no product-domain tables or
feature behavior.

## Client Rules

- Flutter infrastructure adapters may use Supabase Auth and approved Supabase data services only
  through Application ports. Domain and Presentation code do not import Supabase packages.
- The client contains a publishable Supabase key only. It must never contain a secret or
  service-role key.
- An authenticated account identity is obtained from the authorized session. A caller-provided
  account ID cannot establish access rights.
- Account-scoped cloud operations require least-privilege database grants and Row Level Security
  policies. RLS must permit the owning account and deny a different authenticated account.
- Supabase Realtime is introduced only when a separately approved feature needs it; it is not a
  substitute for the local-first synchronization queue.

## Environment and Verification Rules

- Automated Supabase tests run against the local Supabase stack with version-controlled schema,
  migration, grant, and RLS-policy artifacts.
- Device integration uses only the isolated non-production Supabase project. Automated suites do
  not contact production.
- Database verification proves both the owner-allowed and cross-account-denied cases for each
  exposed account-scoped operation.
- Credentials, tokens, and secrets are not written to logs, failure records, general preferences,
  or test fixtures.

## Deferred Decisions

- The final product-domain schema, grants, and policies are owned by their respective approved
  feature specifications.
- The definitive conflict tie-breaker remains unresolved; Foundation retains a visible conflict
  record rather than silently selecting a tie.
