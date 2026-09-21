-- CSP11 Phase FR5 authoring workspace.
-- Creates a separate Supabase schema for future admin drafts.
-- No production content or learner data is inserted by this migration.

create schema if not exists authoring;

revoke all on schema authoring from public;
revoke all on schema authoring from anon, authenticated;
grant usage on schema authoring to service_role;

create table if not exists authoring.content_drafts (
  draft_id text primary key,
  content_id text not null,
  version integer not null check (version > 0),
  domain_id text not null,
  competency_id text not null,
  status text not null default 'draft'
    check (status in ('draft', 'review', 'validated')),
  title text not null default '',
  content_payload jsonb not null default '{}'::jsonb,
  source_payload jsonb not null default '{}'::jsonb,
  created_by_firebase_uid text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (content_id, version)
);

create index if not exists content_drafts_competency_status_idx
  on authoring.content_drafts (competency_id, status, updated_at desc);

create index if not exists content_drafts_domain_status_idx
  on authoring.content_drafts (domain_id, status, updated_at desc);

create table if not exists authoring.question_drafts (
  draft_id text primary key,
  question_id bigint,
  version integer not null default 1 check (version > 0),
  domain_number integer,
  competency_id text not null,
  subtopic_id text not null default '',
  topic_id text not null default '',
  status text not null default 'draft'
    check (status in ('draft', 'review', 'validated')),
  question_payload jsonb not null default '{}'::jsonb,
  quality_gate_payload jsonb not null default '{}'::jsonb,
  source_payload jsonb not null default '{}'::jsonb,
  created_by_firebase_uid text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists question_drafts_question_version_uidx
  on authoring.question_drafts (question_id, version)
  where question_id is not null;

create index if not exists question_drafts_competency_status_idx
  on authoring.question_drafts (competency_id, status, updated_at desc);

create index if not exists question_drafts_subtopic_status_idx
  on authoring.question_drafts (subtopic_id, status, updated_at desc)
  where subtopic_id <> '';

alter table authoring.content_drafts enable row level security;
alter table authoring.question_drafts enable row level security;

revoke all on table authoring.content_drafts from anon, authenticated;
revoke all on table authoring.question_drafts from anon, authenticated;
grant all on table authoring.content_drafts to service_role;
grant all on table authoring.question_drafts to service_role;

alter default privileges in schema authoring
  revoke all on tables from anon, authenticated;

alter default privileges in schema authoring
  grant all on tables to service_role;

-- Production tables are not an authoring workspace. Keep draft/review/validated
-- lifecycle states out of the learner-facing canonical tables.
alter table public.content_versions
  add constraint content_versions_production_status_only
  check (status in ('published', 'archived'));

alter table public.questions
  add constraint questions_production_status_only
  check (status in ('published', 'archived'));

comment on schema authoring is
  'Server-side CSP11 authoring workspace. Not learner-facing and not part of FR5 production parity.';

comment on table authoring.content_drafts is
  'Future content drafts and review/validated working copies. Published copies belong in public.content_versions.';

comment on table authoring.question_drafts is
  'Future question drafts and review/validated working copies. Published questions belong in public.questions.';
