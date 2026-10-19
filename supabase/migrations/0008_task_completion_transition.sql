-- Tasks owns the completion transition used by linked Mind Map projections.
-- Existing open Tasks start at creation; existing completed Tasks start at
-- their completion. Metadata edits keep the current transition unchanged.
begin;

alter table public.tasks
  add column if not exists completion_changed_at timestamptz;

update public.tasks
set completion_changed_at = coalesce(
  (payload ->> 'completionChangedAt')::timestamptz,
  (payload ->> 'completedAt')::timestamptz,
  (payload ->> 'createdAt')::timestamptz,
  updated_at
)
where completion_changed_at is null;

create or replace function public.task_completion_transition_guard()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  v_changed_at timestamptz;
begin
  if tg_op = 'UPDATE' and
     (old.payload ->> 'completedAt') is not distinct from
     (new.payload ->> 'completedAt') then
    v_changed_at := old.completion_changed_at;
  elsif tg_op = 'UPDATE' then
    v_changed_at := coalesce(
      (new.payload ->> 'completionChangedAt')::timestamptz,
      new.updated_at
    );
  else
    v_changed_at := coalesce(
      (new.payload ->> 'completionChangedAt')::timestamptz,
      (new.payload ->> 'completedAt')::timestamptz,
      (new.payload ->> 'createdAt')::timestamptz,
      new.updated_at
    );
  end if;
  if v_changed_at > new.updated_at then
    raise exception using errcode = '22023',
      message = 'Completion transition cannot follow Task version';
  end if;
  new.completion_changed_at := v_changed_at;
  new.payload := pg_catalog.jsonb_set(
    new.payload, '{completionChangedAt}',
    pg_catalog.to_jsonb(v_changed_at), true
  );
  return new;
end;
$$;

drop trigger if exists task_completion_transition_guard on public.tasks;
create trigger task_completion_transition_guard
before insert or update of payload, updated_at on public.tasks
for each row execute function public.task_completion_transition_guard();

revoke all on function public.task_completion_transition_guard() from public, anon, authenticated;
notify pgrst, 'reload schema';
commit;
