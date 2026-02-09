-- Presentation demo seed for Taskly
-- Safe to run multiple times: it first removes previously generated "Demo %" projects and related rows.
-- Works with external auth by reusing existing user IDs already present in your database.

begin;

-- 1) Remove old demo rows so reruns stay clean.
with demo_projects as (
  select id
  from public.projects
  where name like 'Demo %'
)
delete from public.comments c
using public.tasks t
where c.task_id = t.id
  and t.project_id in (select id from demo_projects);

with demo_projects as (
  select id
  from public.projects
  where name like 'Demo %'
)
delete from public.tasks
where project_id in (select id from demo_projects);

delete from public.projects
where name like 'Demo %';

-- 2) Build a pool of valid user IDs from existing data.
create temporary table tmp_user_pool on commit drop as
select distinct p.id as user_id
from public.profiles p
union
select distinct t.user_id
from public.tasks t
where t.user_id is not null
union
select distinct t.assignee
from public.tasks t
where t.assignee is not null
union
select distinct pr.user_id
from public.projects pr
where pr.user_id is not null
union
select distinct c.user_id
from public.comments c
where c.user_id is not null;

do $$
begin
  if not exists (select 1 from tmp_user_pool) then
    raise exception 'No user IDs found. Create at least one real user/profile first, then run this script again.';
  end if;
end $$;

-- Optional: ensure every pooled user has a profile row so names render in UI.
insert into public.profiles (id, first_name, last_name, email, created_at)
select
  u.user_id,
  'Demo',
  'User ' || row_number() over (order by u.user_id),
  'demo.user.' || row_number() over (order by u.user_id) || '@example.com',
  now() - interval '120 days'
from tmp_user_pool u
left join public.profiles p on p.id = u.user_id
where p.id is null;

-- 3) Insert demo projects (exactly 4).
create temporary table tmp_demo_projects on commit drop as
with blueprints(name, description, status, idx) as (
  values
    ('Demo Apollo Launch', 'Cross-team launch preparation, QA gates, and release coordination.', 'active', 1),
    ('Demo Atlas Migration', 'Database and service migration with staged rollout checkpoints.', 'active', 2),
    ('Demo Customer Portal', 'Self-service portal improvements focused on onboarding and billing.', 'active', 3),
    ('Demo Analytics Revamp', 'Event tracking cleanup and KPI dashboard reliability initiative.', 'paused', 4)
),
user_rank as (
  select user_id, row_number() over (order by user_id) as rn
  from tmp_user_pool
),
inserted as (
  insert into public.projects (user_id, name, description, status, created_at)
  select
    ur.user_id,
    b.name,
    b.description,
    b.status,
    now() - (b.idx * interval '3 day') - (random() * interval '5 day')
  from blueprints b
  join user_rank ur
    on ur.rn = ((b.idx - 1) % (select count(*) from user_rank)) + 1
  returning id, user_id, name, status, created_at
)
select *
from inserted;

-- 4) Insert demo tasks (exactly 15 total).
create temporary table tmp_demo_tasks on commit drop as
with project_rank as (
  select
    p.id as project_id,
    p.name as project_name,
    row_number() over (order by p.id) as rn
  from tmp_demo_projects p
),
task_slots as (
  select
    pr.project_id,
    pr.project_name,
    gs.slot
  from generate_series(1, 15) as gs(slot)
  join project_rank pr
    on pr.rn = ((gs.slot - 1) % (select count(*) from project_rank)) + 1
),
task_plan as (
  select
    ts.*,
    case
      when ts.slot <= 5 then 'todo'
      when ts.slot <= 10 then 'in_progress'
      else 'done'
    end as task_status,
    (array['Low', 'Medium', 'High'])[1 + floor(random() * 3)::int] as task_priority
  from task_slots ts
),
inserted as (
  insert into public.tasks (
    user_id,
    project_id,
    title,
    description,
    status,
    priority,
    assignee,
    due_date,
    estimated_hours,
    position,
    created_at
  )
  select
    (select user_id from tmp_user_pool order by random() limit 1) as user_id,
    tp.project_id,
    format(
      '%s %s',
      (array[
        'Finalize', 'Review', 'Improve', 'Refactor', 'Automate', 'Validate', 'Coordinate', 'Document', 'Deploy'
      ])[1 + ((tp.slot + tp.project_id) % 9)],
      (array[
        'onboarding flow',
        'notification pipeline',
        'permission matrix',
        'report export',
        'project health cards',
        'comment moderation',
        'search quality',
        'API response times',
        'release checklist',
        'dashboard metrics',
        'task assignment'
      ])[1 + ((tp.slot * 2 + tp.project_id) % 11)]
    ) as title,
    format(
      'Presentation task for %s. Focus area #%s with clear owner, expected outcome, and measurable progress.',
      tp.project_name,
      tp.slot
    ) as description,
    tp.task_status as status,
    tp.task_priority as priority,
    case
      when random() < 0.85 then (select user_id from tmp_user_pool order by random() limit 1)
      else null
    end as assignee,
    case
      when tp.task_status = 'done' then (current_date - ((random() * 35)::int || ' days')::interval)::date
      when tp.task_status = 'in_progress' then (current_date + ((1 + random() * 14)::int || ' days')::interval)::date
      else (current_date + ((7 + random() * 40)::int || ' days')::interval)::date
    end as due_date,
    (2 + floor(random() * 22)::int) as estimated_hours,
    row_number() over (partition by tp.project_id, tp.task_status order by tp.slot) as position,
    now() - ((12 + floor(random() * 50)::int) || ' days')::interval as created_at
  from task_plan tp
  returning id, project_id, user_id, title, status, created_at
)
select *
from inserted;

-- 5) Insert demo comments (exactly 20 total).
create temporary table tmp_demo_comments on commit drop as
with task_rank as (
  select
    t.id as task_id,
    t.title,
    t.created_at as task_created_at,
    row_number() over (order by t.id) as rn
  from tmp_demo_tasks t
),
comment_slots as (
  select generate_series(1, 20) as slot
),
picked_tasks as (
  select
    cs.slot,
    coalesce(tr.task_id, rt.id) as task_id,
    coalesce(tr.title, rt.title) as title,
    coalesce(tr.task_created_at, rt.created_at) as task_created_at
  from comment_slots cs
  left join task_rank tr
    on tr.rn = cs.slot
  left join lateral (
    select t.id, t.title, t.created_at
    from tmp_demo_tasks t
    order by random()
    limit 1
  ) rt on true
),
inserted as (
  insert into public.comments (task_id, user_id, body, created_at)
  select
    pt.task_id,
    (select user_id from tmp_user_pool order by random() limit 1) as user_id,
    format(
      '%s %s%s',
      (array[
        'Great progress on',
        'Please review',
        'QA update for',
        'Blocked dependency noted for',
        'Status check on',
        'Added implementation notes for',
        'Final pass completed for',
        'Follow-up required on'
      ])[1 + floor(random() * 8)::int],
      lower(pt.title),
      (array[
        '.',
        ' - next update in standup.',
        ' - assigning follow-up now.',
        ' - risk level is currently medium.'
      ])[1 + floor(random() * 4)::int]
    ) as body,
    least(
      now(),
      greatest(
        pt.task_created_at,
        pt.task_created_at + ((1 + floor(random() * 20)::int) || ' days')::interval
      )
    ) as created_at
  from picked_tasks pt
  returning id, task_id
)
select *
from inserted;

do $$
declare
  project_count int;
  task_count int;
  comment_count int;
begin
  select count(*) into project_count from tmp_demo_projects;
  select count(*) into task_count from tmp_demo_tasks;
  select count(*) into comment_count from tmp_demo_comments;

  raise notice 'Demo seed complete: % projects, % tasks, % comments.', project_count, task_count, comment_count;
end $$;

commit;
