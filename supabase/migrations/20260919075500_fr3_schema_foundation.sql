-- CSP11 Phase FR3 PostgreSQL schema foundation.
-- Schema only. No production learner/content data is migrated by this file.

create or replace function public.fr_touch_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table public.app_users (
  firebase_uid text primary key,
  app_role text not null default 'student'
    check (app_role in ('student', 'admin')),
  email_snapshot text,
  source_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.content_versions (
  content_id text not null,
  version integer not null check (version > 0),
  domain_id text not null,
  competency_id text not null,
  competency_number integer not null check (competency_number > 0),
  title text not null,
  status text not null
    check (status in ('draft', 'review', 'validated', 'published', 'archived')),
  source_document_id text,
  content_payload jsonb not null,
  source_checksum_sha256 text,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (content_id, version),
  check (
    source_checksum_sha256 is null
    or source_checksum_sha256 ~ '^[0-9a-f]{64}$'
  )
);

create unique index content_versions_source_document_uidx
  on public.content_versions (source_document_id)
  where source_document_id is not null;

create index content_versions_competency_status_idx
  on public.content_versions (competency_id, status, version desc);

create index content_versions_domain_status_idx
  on public.content_versions (domain_id, status, version desc);

create table public.questions (
  question_id bigint not null check (question_id > 0),
  version integer not null check (version > 0),
  domain_number integer not null check (domain_number > 0),
  competency_id text not null,
  subtopic_id text not null default '',
  topic_id text not null default '',
  quiz_id text not null default '',
  content_package_id text not null default '',
  stem text not null,
  options jsonb not null default '[]'::jsonb,
  correct_answer integer not null default 0,
  explanation text not null default '',
  best_answer_rationale text not null default '',
  reference_text text not null default '',
  difficulty text not null default '',
  cognitive_level text not null default '',
  question_type text not null default '',
  status text not null
    check (status in ('draft', 'review', 'validated', 'published', 'archived')),
  tags text[] not null default '{}',
  quality_gate_payload jsonb not null default '{}'::jsonb,
  source_document_id text,
  source_payload jsonb not null default '{}'::jsonb,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (question_id, version),
  check (
    status <> 'published'
    or (
      jsonb_typeof(options) = 'array'
      and jsonb_array_length(options) = 4
      and correct_answer between 0 and 3
    )
  )
);

create unique index questions_source_document_uidx
  on public.questions (source_document_id)
  where source_document_id is not null;

create index questions_competency_status_idx
  on public.questions (competency_id, status, version desc);

create index questions_subtopic_status_idx
  on public.questions (subtopic_id, status, version desc)
  where subtopic_id <> '';

create index questions_quiz_status_idx
  on public.questions (quiz_id, status, version desc)
  where quiz_id <> '';

create table public.published_packages (
  package_kind text not null
    check (package_kind in ('content', 'questions', 'lab', 'flashcards')),
  package_key text not null,
  version integer not null check (version > 0),
  domain_id text,
  competency_id text,
  storage_bucket text not null,
  storage_path text not null,
  checksum_sha256 text not null
    check (checksum_sha256 ~ '^[0-9a-f]{64}$'),
  compressed_bytes bigint check (compressed_bytes is null or compressed_bytes >= 0),
  item_count integer check (item_count is null or item_count >= 0),
  is_current boolean not null default false,
  metadata jsonb not null default '{}'::jsonb,
  published_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  primary key (package_kind, package_key, version),
  unique (storage_bucket, storage_path)
);

create unique index published_packages_one_current_uidx
  on public.published_packages (package_kind, package_key)
  where is_current;

create index published_packages_competency_current_idx
  on public.published_packages (competency_id, package_kind)
  where is_current;

create table public.learner_subtopic_progress (
  firebase_uid text not null references public.app_users(firebase_uid) on delete cascade,
  subtopic_id text not null,
  domain_id text not null,
  domain_number integer not null check (domain_number > 0),
  domain_title text not null default '',
  competency_id text not null,
  competency_title text not null default '',
  subtopic_title text not null default '',
  study_content_id text not null,
  study_content_version integer not null check (study_content_version > 0),
  learning_state text not null
    check (learning_state in ('notStarted', 'inProgress', 'completed')),
  last_opened_at timestamptz not null,
  completed_at timestamptz,
  source_payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (firebase_uid, subtopic_id)
);

create index learner_subtopic_progress_competency_idx
  on public.learner_subtopic_progress (firebase_uid, competency_id);

create table public.learner_question_progress (
  firebase_uid text not null references public.app_users(firebase_uid) on delete cascade,
  question_id bigint not null check (question_id > 0),
  domain_number integer not null check (domain_number > 0),
  competency_id text not null,
  topic_id text not null default '',
  subtopic_id text not null default '',
  attempt_count integer not null check (attempt_count > 0),
  last_correct boolean not null,
  ever_correct boolean not null,
  first_answered_at timestamptz not null,
  last_answered_at timestamptz not null,
  source_payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (firebase_uid, question_id)
);

create index learner_question_progress_recent_idx
  on public.learner_question_progress (firebase_uid, last_answered_at desc);

create table public.learner_assessment_attempts (
  firebase_uid text not null references public.app_users(firebase_uid) on delete cascade,
  attempt_id text not null,
  question_id bigint not null check (question_id > 0),
  question_version integer not null check (question_version > 0),
  domain_number integer not null check (domain_number > 0),
  competency_id text not null,
  topic_id text not null default '',
  subtopic_id text not null default '',
  correct boolean not null,
  answered_at timestamptz not null,
  cognitive_level text not null default '',
  question_type text not null default '',
  difficulty_lane text not null default '',
  published_at_attempt boolean not null default false,
  session_kind text not null default 'practice',
  confidence text,
  source_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (firebase_uid, attempt_id)
);

create index learner_assessment_attempts_recent_idx
  on public.learner_assessment_attempts (firebase_uid, answered_at desc);

create index learner_assessment_attempts_competency_idx
  on public.learner_assessment_attempts (firebase_uid, competency_id, answered_at desc);

create table public.readiness_snapshots (
  firebase_uid text not null references public.app_users(firebase_uid) on delete cascade,
  snapshot_id text not null,
  generated_at timestamptz not null,
  availability text,
  score integer check (score is null or score between 0 and 100),
  evidence_confidence text,
  algorithm_version text,
  source_payload jsonb not null,
  created_at timestamptz not null default now(),
  primary key (firebase_uid, snapshot_id)
);

create index readiness_snapshots_recent_idx
  on public.readiness_snapshots (firebase_uid, generated_at desc);

create table public.exam_study_plans (
  firebase_uid text not null references public.app_users(firebase_uid) on delete cascade,
  plan_id text not null,
  exam_date date not null,
  timezone text not null,
  active boolean not null,
  plan_version integer not null check (plan_version > 0),
  created_at_source timestamptz not null,
  updated_at_source timestamptz not null,
  source_payload jsonb not null,
  updated_at timestamptz not null default now(),
  primary key (firebase_uid, plan_id, plan_version)
);

create unique index exam_study_plans_one_active_uidx
  on public.exam_study_plans (firebase_uid)
  where active;

create index exam_study_plans_recent_idx
  on public.exam_study_plans (firebase_uid, updated_at_source desc);

create table public.daily_study_plans (
  firebase_uid text not null references public.app_users(firebase_uid) on delete cascade,
  plan_id text not null,
  plan_date date not null,
  plan_version integer not null check (plan_version > 0),
  generated_at timestamptz not null,
  available_minutes integer not null check (available_minutes >= 0),
  allocated_minutes integer not null check (allocated_minutes >= 0),
  status text not null
    check (status in ('active', 'completed', 'superseded', 'stale')),
  planner_algorithm_version text not null,
  source_evidence_version text not null default '',
  source_readiness_version text not null default '',
  previous_plan_id text,
  input_snapshot_version text not null default '',
  source_payload jsonb not null,
  updated_at timestamptz not null default now(),
  primary key (firebase_uid, plan_id, plan_version),
  check (allocated_minutes <= available_minutes)
);

create unique index daily_study_plans_one_active_per_day_uidx
  on public.daily_study_plans (firebase_uid, plan_date)
  where status = 'active';

create index daily_study_plans_recent_idx
  on public.daily_study_plans (firebase_uid, plan_date desc, generated_at desc);

create table public.study_plan_block_outcomes (
  firebase_uid text not null references public.app_users(firebase_uid) on delete cascade,
  outcome_id text not null,
  plan_id text not null,
  block_id text not null,
  recorded_at timestamptz not null,
  source_payload jsonb not null,
  created_at timestamptz not null default now(),
  primary key (firebase_uid, outcome_id)
);

create index study_plan_block_outcomes_plan_idx
  on public.study_plan_block_outcomes (firebase_uid, plan_id, recorded_at desc);

create table public.lab_attempts (
  firebase_uid text not null references public.app_users(firebase_uid) on delete cascade,
  attempt_id text not null,
  lab_id text not null,
  lab_version integer,
  started_at timestamptz,
  completed_at timestamptz,
  outcome text,
  source_payload jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (firebase_uid, attempt_id)
);

create index lab_attempts_recent_idx
  on public.lab_attempts (firebase_uid, started_at desc);

create index lab_attempts_lab_idx
  on public.lab_attempts (firebase_uid, lab_id, started_at desc);

create table public.learning_twin_evidence (
  firebase_uid text not null references public.app_users(firebase_uid) on delete cascade,
  evidence_id text not null,
  evidence_type text not null,
  occurred_at timestamptz not null,
  source_payload jsonb not null,
  created_at timestamptz not null default now(),
  primary key (firebase_uid, evidence_id)
);

create index learning_twin_evidence_recent_idx
  on public.learning_twin_evidence (firebase_uid, occurred_at desc);

create table public.fr_migration_ledger (
  source_system text not null,
  source_collection text not null,
  source_id text not null,
  target_table text not null,
  target_key text not null,
  source_checksum_sha256 text,
  target_checksum_sha256 text,
  validation_status text not null default 'pending'
    check (validation_status in ('pending', 'matched', 'mismatch', 'failed', 'excluded')),
  failure_reason text,
  migrated_at timestamptz,
  validated_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  primary key (source_system, source_collection, source_id),
  check (
    source_checksum_sha256 is null
    or source_checksum_sha256 ~ '^[0-9a-f]{64}$'
  ),
  check (
    target_checksum_sha256 is null
    or target_checksum_sha256 ~ '^[0-9a-f]{64}$'
  )
);

create index fr_migration_ledger_status_idx
  on public.fr_migration_ledger (validation_status, source_collection);

create trigger app_users_touch_updated_at
before update on public.app_users
for each row execute function public.fr_touch_updated_at();

create trigger content_versions_touch_updated_at
before update on public.content_versions
for each row execute function public.fr_touch_updated_at();

create trigger questions_touch_updated_at
before update on public.questions
for each row execute function public.fr_touch_updated_at();

create trigger learner_subtopic_progress_touch_updated_at
before update on public.learner_subtopic_progress
for each row execute function public.fr_touch_updated_at();

create trigger learner_question_progress_touch_updated_at
before update on public.learner_question_progress
for each row execute function public.fr_touch_updated_at();

create trigger exam_study_plans_touch_updated_at
before update on public.exam_study_plans
for each row execute function public.fr_touch_updated_at();

create trigger daily_study_plans_touch_updated_at
before update on public.daily_study_plans
for each row execute function public.fr_touch_updated_at();

create trigger lab_attempts_touch_updated_at
before update on public.lab_attempts
for each row execute function public.fr_touch_updated_at();

alter table public.app_users enable row level security;
alter table public.content_versions enable row level security;
alter table public.questions enable row level security;
alter table public.published_packages enable row level security;
alter table public.learner_subtopic_progress enable row level security;
alter table public.learner_question_progress enable row level security;
alter table public.learner_assessment_attempts enable row level security;
alter table public.readiness_snapshots enable row level security;
alter table public.exam_study_plans enable row level security;
alter table public.daily_study_plans enable row level security;
alter table public.study_plan_block_outcomes enable row level security;
alter table public.lab_attempts enable row level security;
alter table public.learning_twin_evidence enable row level security;
alter table public.fr_migration_ledger enable row level security;

revoke all on table public.app_users from anon, authenticated;
revoke all on table public.content_versions from anon, authenticated;
revoke all on table public.questions from anon, authenticated;
revoke all on table public.published_packages from anon, authenticated;
revoke all on table public.learner_subtopic_progress from anon, authenticated;
revoke all on table public.learner_question_progress from anon, authenticated;
revoke all on table public.learner_assessment_attempts from anon, authenticated;
revoke all on table public.readiness_snapshots from anon, authenticated;
revoke all on table public.exam_study_plans from anon, authenticated;
revoke all on table public.daily_study_plans from anon, authenticated;
revoke all on table public.study_plan_block_outcomes from anon, authenticated;
revoke all on table public.lab_attempts from anon, authenticated;
revoke all on table public.learning_twin_evidence from anon, authenticated;
revoke all on table public.fr_migration_ledger from anon, authenticated;

grant all on table public.app_users to service_role;
grant all on table public.content_versions to service_role;
grant all on table public.questions to service_role;
grant all on table public.published_packages to service_role;
grant all on table public.learner_subtopic_progress to service_role;
grant all on table public.learner_question_progress to service_role;
grant all on table public.learner_assessment_attempts to service_role;
grant all on table public.readiness_snapshots to service_role;
grant all on table public.exam_study_plans to service_role;
grant all on table public.daily_study_plans to service_role;
grant all on table public.study_plan_block_outcomes to service_role;
grant all on table public.lab_attempts to service_role;
grant all on table public.learning_twin_evidence to service_role;
grant all on table public.fr_migration_ledger to service_role;

revoke execute on function public.fr_touch_updated_at() from public, anon, authenticated;
grant execute on function public.fr_touch_updated_at() to service_role;

-- Edge-only learner architecture: even if direct table grants are added later,
-- these explicit RLS policies continue to fail closed for client roles.
create policy fr_edge_only_deny_direct_client
  on public.app_users for all to anon, authenticated
  using (false) with check (false);
create policy fr_edge_only_deny_direct_client
  on public.content_versions for all to anon, authenticated
  using (false) with check (false);
create policy fr_edge_only_deny_direct_client
  on public.questions for all to anon, authenticated
  using (false) with check (false);
create policy fr_edge_only_deny_direct_client
  on public.published_packages for all to anon, authenticated
  using (false) with check (false);
create policy fr_edge_only_deny_direct_client
  on public.learner_subtopic_progress for all to anon, authenticated
  using (false) with check (false);
create policy fr_edge_only_deny_direct_client
  on public.learner_question_progress for all to anon, authenticated
  using (false) with check (false);
create policy fr_edge_only_deny_direct_client
  on public.learner_assessment_attempts for all to anon, authenticated
  using (false) with check (false);
create policy fr_edge_only_deny_direct_client
  on public.readiness_snapshots for all to anon, authenticated
  using (false) with check (false);
create policy fr_edge_only_deny_direct_client
  on public.exam_study_plans for all to anon, authenticated
  using (false) with check (false);
create policy fr_edge_only_deny_direct_client
  on public.daily_study_plans for all to anon, authenticated
  using (false) with check (false);
create policy fr_edge_only_deny_direct_client
  on public.study_plan_block_outcomes for all to anon, authenticated
  using (false) with check (false);
create policy fr_edge_only_deny_direct_client
  on public.lab_attempts for all to anon, authenticated
  using (false) with check (false);
create policy fr_edge_only_deny_direct_client
  on public.learning_twin_evidence for all to anon, authenticated
  using (false) with check (false);
create policy fr_edge_only_deny_direct_client
  on public.fr_migration_ledger for all to anon, authenticated
  using (false) with check (false);
