-- CSP11 Phase FR6 published catalogue.
-- Schema only. FR6 does not cut learner runtime over to Supabase and does not
-- publish Storage objects. FR7 will build immutable package publishing.

create table public.published_catalog (
  competency_id text primary key,
  content_version integer not null check (content_version > 0),
  content_checksum_sha256 text not null
    check (content_checksum_sha256 ~ '^[0-9a-f]{64}$'),
  content_object_path text not null
    check (length(btrim(content_object_path)) > 0),
  content_size_bytes bigint not null
    check (content_size_bytes >= 0),
  question_version integer not null check (question_version > 0),
  question_checksum_sha256 text not null
    check (question_checksum_sha256 ~ '^[0-9a-f]{64}$'),
  question_object_path text not null
    check (length(btrim(question_object_path)) > 0),
  question_size_bytes bigint not null
    check (question_size_bytes >= 0),
  published_question_count integer not null
    check (published_question_count >= 0),
  active boolean not null default true,
  published_at timestamptz not null,
  updated_at timestamptz not null default now()
);

create index published_catalog_active_competency_idx
  on public.published_catalog (competency_id)
  where active;

create trigger published_catalog_touch_updated_at
before update on public.published_catalog
for each row execute function public.fr_touch_updated_at();

alter table public.published_catalog enable row level security;

revoke all on table public.published_catalog from anon, authenticated;
grant all on table public.published_catalog to service_role;

create policy fr_edge_only_deny_direct_client
  on public.published_catalog for all to anon, authenticated
  using (false) with check (false);
