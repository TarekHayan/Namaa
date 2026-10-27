-- Ordinary sequential edits do not become conflicts. A stale base does.
begin;
select plan(11);

insert into auth.users(instance_id,id,aud,role,email,encrypted_password,created_at,updated_at)
values ('00000000-0000-0000-0000-000000000000',
  '76666666-6666-4666-8666-666666666666','authenticated','authenticated',
  'base-version@example.com','x',now(),now());

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"76666666-6666-4666-8666-666666666666","role":"authenticated"}',true);

select is((select conflict_detected from public.apply_task_change(
  '11111111-1111-4111-8111-111111111111',
  '{"title":"First","completionXp":1000000}'::jsonb,
  'task-create','2026-10-12T08:00:00Z','create')),
  false,'new task has no conflict');
select is((select conflict_detected from public.apply_task_change(
  '11111111-1111-4111-8111-111111111111',
  '{"title":"Second","completedAt":"2026-10-12T09:00:00Z","completionXp":1000000,"_syncBaseUpdatedAt":"2026-10-12T08:00:00Z"}'::jsonb,
  'task-sequential','2026-10-12T09:00:00Z','update')),
  false,'sequential task edit has no conflict');
select is((select conflict_detected from public.apply_task_change(
  '11111111-1111-4111-8111-111111111111',
  '{"title":"Stale","_syncBaseUpdatedAt":"2026-10-12T08:00:00Z"}'::jsonb,
  'task-stale','2026-10-12T09:30:00Z','update')),
  true,'stale task base is a conflict');
select is((select payload->>'completionXp' from public.tasks
  where id='11111111-1111-4111-8111-111111111111'),
  '20','task reward is normalized by server');
select is((select amount from public.xp_awards
  where source_id='11111111-1111-4111-8111-111111111111'),
  20,'untrusted million-XP completion cannot change the award');

select is((select conflict_detected from public.apply_habit_change(
  '22222222-2222-4222-8222-222222222222',
  jsonb_build_object('id','22222222-2222-4222-8222-222222222222',
    'accountId','76666666-6666-4666-8666-666666666666','name','Read',
    'createdAt','2026-10-12T08:00:00Z','updatedAt','2026-10-12T08:00:00Z',
    'deletedAt',null,'reminderMinuteOfDay',null,
    'scheduleRevisions',jsonb_build_array(jsonb_build_object(
      'revisionId','r1','effectiveAt','2026-10-12T08:00:00Z',
      'effectiveLocalDate','2026-10-12','utcOffsetMinutes',120,
      'weekdays',jsonb_build_array(1)))),
  'habit-create','2026-10-12T08:00:00Z','create')),
  false,'new habit has no conflict');
select is((select conflict_detected from public.apply_habit_change(
  '22222222-2222-4222-8222-222222222222',
  (select payload from public.habits where id='22222222-2222-4222-8222-222222222222')
    || '{"name":"Write","updatedAt":"2026-10-12T09:00:00Z","_syncBaseUpdatedAt":"2026-10-12T08:00:00Z"}'::jsonb,
  'habit-sequential','2026-10-12T09:00:00Z','update')),
  false,'sequential habit edit has no conflict');
select is((select conflict_detected from public.apply_habit_change(
  '22222222-2222-4222-8222-222222222222',
  (select payload from public.habits where id='22222222-2222-4222-8222-222222222222')
    || '{"name":"Stale","updatedAt":"2026-10-12T09:30:00Z","_syncBaseUpdatedAt":"2026-10-12T08:00:00Z"}'::jsonb,
  'habit-stale','2026-10-12T09:30:00Z','update')),
  true,'stale habit base is a conflict');

select is((select conflict_detected from public.apply_mind_map_change(
  'mind_map','33333333-3333-4333-8333-333333333333',
  '33333333-3333-4333-8333-333333333333',
  jsonb_build_object('ownerId','76666666-6666-4666-8666-666666666666',
    'id','33333333-3333-4333-8333-333333333333','title','Map',
    'centralNodeId','44444444-4444-4444-8444-444444444444',
    'settings','{}'::jsonb,'revisionId','r1',
    'createdAt','2026-10-12T08:00:00Z','updatedAt','2026-10-12T08:00:00Z',
    'deletedAt',null),
  'map-create','2026-10-12T08:00:00Z','create')),
  false,'new map has no conflict');
select is((select conflict_detected from public.apply_mind_map_change(
  'mind_map','33333333-3333-4333-8333-333333333333',
  '33333333-3333-4333-8333-333333333333',
  (select payload from public.mind_maps where id='33333333-3333-4333-8333-333333333333')
    || '{"title":"Updated","revisionId":"r2","updatedAt":"2026-10-12T09:00:00Z","_syncBaseUpdatedAt":"2026-10-12T08:00:00Z"}'::jsonb,
  'map-sequential','2026-10-12T09:00:00Z','update')),
  false,'sequential map edit has no conflict');
select is((select conflict_detected from public.apply_mind_map_change(
  'mind_map','33333333-3333-4333-8333-333333333333',
  '33333333-3333-4333-8333-333333333333',
  (select payload from public.mind_maps where id='33333333-3333-4333-8333-333333333333')
    || '{"title":"Stale","revisionId":"r3","updatedAt":"2026-10-12T09:30:00Z","_syncBaseUpdatedAt":"2026-10-12T08:00:00Z"}'::jsonb,
  'map-stale','2026-10-12T09:30:00Z','update')),
  true,'stale map base is a conflict');

select * from finish();
rollback;
