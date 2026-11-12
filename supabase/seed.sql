-- Local-only catalog fixture for integration tests (spec 009 T066).
-- NEVER shipped: the real catalog seeds in the same change as the
-- owner-approved asset (tasks.md T006, gated by T073), so the server can
-- never award set completion or accept counts for items the client does
-- not ship. This fixture carries IDs and targets only — no text anywhere.
-- Catalog version 900 belongs to the integration fixtures; the pgTAP
-- tests own version 1 and seed it inside their own transactions, so the
-- two never collide. `supabase test db` keeps passing after a reset.
insert into public.adhkar_catalog_items(catalog_version,item_id,list,position,target)
values
  (900,'m1','morning',1,1),
  (900,'m2','morning',2,3),
  (900,'m3','morning',3,10),
  (900,'e1','evening',1,1),
  (900,'e2','evening',2,3),
  (900,'e3','evening',3,10)
on conflict (catalog_version,item_id) do nothing;
