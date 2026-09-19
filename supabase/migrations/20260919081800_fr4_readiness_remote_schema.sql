-- CSP11 Phase FR4 pre-migration readiness schema correction.
-- Schema only. All affected tables are empty at this checkpoint.

alter table public.readiness_snapshots
  rename to readiness_index_snapshots;

alter index public.readiness_snapshots_recent_idx
  rename to readiness_index_snapshots_recent_idx;

create table public.competency_evidence_snapshots (
  firebase_uid text not null references public.app_users(firebase_uid) on delete cascade,
  competency_id text not null,
  generated_at timestamptz not null,
  schema_version integer not null check (schema_version > 0),
  algorithm_version text not null,
  source_attempt_count integer not null check (source_attempt_count >= 0),
  evidence_confidence text,
  evidence_state text,
  source_payload jsonb not null,
  updated_at timestamptz not null default now(),
  primary key (firebase_uid, competency_id)
);

create index competency_evidence_snapshots_recent_idx
  on public.competency_evidence_snapshots (firebase_uid, generated_at desc);

create table public.competency_readiness_profiles (
  firebase_uid text not null references public.app_users(firebase_uid) on delete cascade,
  competency_id text not null,
  generated_at timestamptz not null,
  algorithm_version text not null,
  evidence_confidence text,
  readiness_state text,
  has_critical_gap boolean not null default false,
  source_payload jsonb not null,
  updated_at timestamptz not null default now(),
  primary key (firebase_uid, competency_id)
);

create index competency_readiness_profiles_recent_idx
  on public.competency_readiness_profiles (firebase_uid, generated_at desc);

create trigger competency_evidence_snapshots_touch_updated_at
before update on public.competency_evidence_snapshots
for each row execute function public.fr_touch_updated_at();

create trigger competency_readiness_profiles_touch_updated_at
before update on public.competency_readiness_profiles
for each row execute function public.fr_touch_updated_at();

alter table public.competency_evidence_snapshots enable row level security;
alter table public.competency_readiness_profiles enable row level security;

revoke all on table public.competency_evidence_snapshots from anon, authenticated;
revoke all on table public.competency_readiness_profiles from anon, authenticated;

grant all on table public.competency_evidence_snapshots to service_role;
grant all on table public.competency_readiness_profiles to service_role;

create policy fr_edge_only_deny_direct_client
  on public.competency_evidence_snapshots for all to anon, authenticated
  using (false) with check (false);

create policy fr_edge_only_deny_direct_client
  on public.competency_readiness_profiles for all to anon, authenticated
  using (false) with check (false);
