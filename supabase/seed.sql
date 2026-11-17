-- Local-only catalog fixture for integration tests (spec 009 T066).
-- NEVER shipped. The real v1 catalog is seeded by migration 0016 (T006); this
-- fixture adds catalog version 900 beside it, carrying IDs and targets only
-- (no text anywhere). The pgTAP tests replace version 1 with their own rows
-- inside their own transactions, so the two never collide.
-- `supabase test db` keeps passing after a reset.
insert into public.adhkar_catalog_items(catalog_version,item_id,list,position,target)
values
  (900,'m1','morning',1,1),
  (900,'m2','morning',2,3),
  (900,'m3','morning',3,10),
  (900,'e1','evening',1,1),
  (900,'e2','evening',2,3),
  (900,'e3','evening',3,10)
on conflict (catalog_version,item_id) do nothing;
