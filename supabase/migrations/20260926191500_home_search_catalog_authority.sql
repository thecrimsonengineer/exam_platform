create or replace function public.refresh_published_study_search_index_refined()
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  row_count_total integer;
begin
  perform public.refresh_published_study_search_index();

  -- The learner catalogue is the authority for what is actually exposed.
  -- A current package that is not backed by an active catalogue pointer must
  -- never remain searchable.
  delete from public.published_study_search_index idx
  where not exists (
    select 1
    from public.published_catalog catalog
    where catalog.active = true
      and catalog.competency_id = idx.package_key
      and catalog.content_version = idx.package_version
  );

  insert into public.published_study_search_index (
    package_key,
    package_version,
    source_version,
    domain_id,
    domain_title,
    competency_id,
    competency_title,
    topic_id,
    topic_title,
    subtopic_id,
    subtopic_title,
    section_name,
    field_text,
    normalized_text,
    compact_text,
    weight,
    contextual
  )
  select distinct
    package_key,
    package_version,
    source_version,
    domain_id,
    domain_title,
    competency_id,
    competency_title,
    topic_id,
    topic_title,
    subtopic_id,
    subtopic_title,
    'Topic ID',
    topic_id,
    public.csp11_search_normalize(topic_id),
    replace(public.csp11_search_normalize(topic_id), ' ', ''),
    710,
    true
  from public.published_study_search_index
  where section_name = 'Subtopic'
  on conflict do nothing;

  insert into public.published_study_search_index (
    package_key,
    package_version,
    source_version,
    domain_id,
    domain_title,
    competency_id,
    competency_title,
    topic_id,
    topic_title,
    subtopic_id,
    subtopic_title,
    section_name,
    field_text,
    normalized_text,
    compact_text,
    weight,
    contextual
  )
  select distinct
    package_key,
    package_version,
    source_version,
    domain_id,
    domain_title,
    competency_id,
    competency_title,
    topic_id,
    topic_title,
    subtopic_id,
    subtopic_title,
    'Subtopic ID',
    subtopic_id,
    public.csp11_search_normalize(subtopic_id),
    replace(public.csp11_search_normalize(subtopic_id), ' ', ''),
    1120,
    false
  from public.published_study_search_index
  where section_name = 'Subtopic'
  on conflict do nothing;

  select count(*)::integer
    into row_count_total
    from public.published_study_search_index;

  return row_count_total;
end;
$$;

revoke all on function public.refresh_published_study_search_index_refined() from public;
revoke all on function public.refresh_published_study_search_index_refined() from anon;
revoke all on function public.refresh_published_study_search_index_refined() from authenticated;
grant execute on function public.refresh_published_study_search_index_refined() to service_role;

drop trigger if exists published_catalog_search_index_content_update on public.published_catalog;
create trigger published_catalog_search_index_content_update
after update of content_version, active on public.published_catalog
for each row
when (
  old.content_version is distinct from new.content_version
  or old.active is distinct from new.active
)
execute function public.csp11_refresh_study_search_index_from_catalog();

select public.refresh_published_study_search_index_refined();
