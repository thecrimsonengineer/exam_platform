create table if not exists public.published_study_search_index (
  package_key text not null,
  package_version integer not null,
  source_version integer not null,
  domain_id text not null,
  domain_title text not null,
  competency_id text not null,
  competency_title text not null,
  topic_id text not null,
  topic_title text not null,
  subtopic_id text not null,
  subtopic_title text not null,
  section_name text not null,
  field_text text not null,
  normalized_text text not null,
  compact_text text not null,
  weight integer not null,
  contextual boolean not null default false,
  primary key (
    package_key,
    source_version,
    topic_id,
    subtopic_id,
    section_name,
    normalized_text,
    field_text
  )
);

revoke all on table public.published_study_search_index from public;
revoke all on table public.published_study_search_index from anon;
revoke all on table public.published_study_search_index from authenticated;
grant select, insert, delete on table public.published_study_search_index to service_role;

create index if not exists published_study_search_index_route_idx
  on public.published_study_search_index (
    competency_id,
    topic_id,
    subtopic_id
  );

create index if not exists published_study_search_index_normalized_prefix_idx
  on public.published_study_search_index (normalized_text text_pattern_ops);

create index if not exists published_study_search_index_compact_prefix_idx
  on public.published_study_search_index (compact_text text_pattern_ops);

create or replace function public.refresh_published_study_search_index()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  inserted_count integer;
begin
  delete from public.published_study_search_index;

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
  with published_sources as (
    select
      pp.package_key,
      pp.version as package_version,
      (pp.metadata->>'sourceVersion')::integer as source_version,
      cv.domain_id,
      case cv.domain_id
        when 'd01' then 'Advanced Application of Safety Principles'
        when 'd02' then 'Program Management'
        when 'd03' then 'Risk Management'
        when 'd04' then 'Emergency Management'
        when 'd05' then 'Environmental Management'
        when 'd06' then 'Occupational Health and Applied Science'
        when 'd07' then 'Training'
        else upper(cv.domain_id)
      end as domain_title,
      cv.competency_id,
      cv.title as competency_title,
      cv.content_payload
    from public.published_packages pp
    join public.content_versions cv
      on cv.competency_id = pp.package_key
     and cv.version = (pp.metadata->>'sourceVersion')::integer
     and lower(cv.status) = 'published'
    where pp.package_kind = 'content'
      and pp.is_current = true
      and pp.storage_bucket = 'csp11-published-packages'
      and pp.storage_path =
        'content/' || pp.package_key || '/v' || pp.version::text || '.json.gz'
  ), subtopics as (
    select
      src.package_key,
      src.package_version,
      src.source_version,
      src.domain_id,
      src.domain_title,
      src.competency_id,
      src.competency_title,
      topic_item->>'id' as topic_id,
      topic_item->>'title' as topic_title,
      subtopic_item->>'id' as subtopic_id,
      subtopic_item->>'title' as subtopic_title,
      subtopic_item as subtopic_json
    from published_sources src
    cross join lateral jsonb_array_elements(
      case
        when jsonb_typeof(src.content_payload->'topics') = 'array'
          then src.content_payload->'topics'
        else '[]'::jsonb
      end
    ) as topic_row(topic_item)
    cross join lateral jsonb_array_elements(
      case
        when jsonb_typeof(topic_item->'subtopics') = 'array'
          then topic_item->'subtopics'
        else '[]'::jsonb
      end
    ) as subtopic_row(subtopic_item)
    where coalesce(topic_item->>'id', '') <> ''
      and coalesce(topic_item->>'title', '') <> ''
      and coalesce(subtopic_item->>'id', '') <> ''
      and coalesce(subtopic_item->>'title', '') <> ''
  ), fields as (
    select package_key, package_version, source_version,
      domain_id, domain_title, competency_id, competency_title,
      topic_id, topic_title, subtopic_id, subtopic_title,
      'Subtopic'::text as section_name,
      subtopic_title as field_text, 1100 as weight, false as contextual
    from subtopics

    union all

    select s.package_key, s.package_version, s.source_version,
      s.domain_id, s.domain_title, s.competency_id, s.competency_title,
      s.topic_id, s.topic_title, s.subtopic_id, s.subtopic_title,
      'Learning objective', objective_text, 940, false
    from subtopics s
    cross join lateral jsonb_array_elements_text(
      case when jsonb_typeof(s.subtopic_json->'learningObjectives') = 'array'
        then s.subtopic_json->'learningObjectives' else '[]'::jsonb end
    ) as objective_row(objective_text)

    union all

    select s.package_key, s.package_version, s.source_version,
      s.domain_id, s.domain_title, s.competency_id, s.competency_title,
      s.topic_id, s.topic_title, s.subtopic_id, s.subtopic_title,
      'Main content', content_value #>> '{}', 840, false
    from subtopics s
    cross join lateral jsonb_array_elements(
      case when jsonb_typeof(s.subtopic_json->'blocks') = 'array'
        then s.subtopic_json->'blocks' else '[]'::jsonb end
    ) as block_row(block_json)
    cross join lateral jsonb_path_query(
      coalesce(block_json->'data', '{}'::jsonb),
      '$.** ? (@.type() == "string")'
    ) as content_row(content_value)
    where not (
      lower(coalesce(block_json->>'type', '')) = 'reference'
      and public.csp11_search_normalize(coalesce(block_json->'data'->>'title', '')) =
        'csp source traceability'
    )

    union all

    select s.package_key, s.package_version, s.source_version,
      s.domain_id, s.domain_title, s.competency_id, s.competency_title,
      s.topic_id, s.topic_title, s.subtopic_id, s.subtopic_title,
      'Key point', item_text, 820, false
    from subtopics s
    cross join lateral jsonb_array_elements_text(
      case when jsonb_typeof(s.subtopic_json->'keyPoints') = 'array'
        then s.subtopic_json->'keyPoints' else '[]'::jsonb end
    ) as item_row(item_text)

    union all

    select s.package_key, s.package_version, s.source_version,
      s.domain_id, s.domain_title, s.competency_id, s.competency_title,
      s.topic_id, s.topic_title, s.subtopic_id, s.subtopic_title,
      'Key takeaway', item_text, 810, false
    from subtopics s
    cross join lateral jsonb_array_elements_text(
      case when jsonb_typeof(s.subtopic_json->'keyTakeaways') = 'array'
        then s.subtopic_json->'keyTakeaways' else '[]'::jsonb end
    ) as item_row(item_text)

    union all

    select s.package_key, s.package_version, s.source_version,
      s.domain_id, s.domain_title, s.competency_id, s.competency_title,
      s.topic_id, s.topic_title, s.subtopic_id, s.subtopic_title,
      'Exam tip', item_text, 790, false
    from subtopics s
    cross join lateral jsonb_array_elements_text(
      case when jsonb_typeof(s.subtopic_json->'examTips') = 'array'
        then s.subtopic_json->'examTips' else '[]'::jsonb end
    ) as item_row(item_text)

    union all

    select s.package_key, s.package_version, s.source_version,
      s.domain_id, s.domain_title, s.competency_id, s.competency_title,
      s.topic_id, s.topic_title, s.subtopic_id, s.subtopic_title,
      'Workplace example', item_text, 770, false
    from subtopics s
    cross join lateral jsonb_array_elements_text(
      case when jsonb_typeof(s.subtopic_json->'examples') = 'array'
        then s.subtopic_json->'examples' else '[]'::jsonb end
    ) as item_row(item_text)

    union all

    select s.package_key, s.package_version, s.source_version,
      s.domain_id, s.domain_title, s.competency_id, s.competency_title,
      s.topic_id, s.topic_title, s.subtopic_id, s.subtopic_title,
      'Common mistake', item_text, 750, false
    from subtopics s
    cross join lateral jsonb_array_elements_text(
      case when jsonb_typeof(s.subtopic_json->'commonMistakes') = 'array'
        then s.subtopic_json->'commonMistakes' else '[]'::jsonb end
    ) as item_row(item_text)

    union all

    select s.package_key, s.package_version, s.source_version,
      s.domain_id, s.domain_title, s.competency_id, s.competency_title,
      s.topic_id, s.topic_title, s.subtopic_id, s.subtopic_title,
      'Case study', item_text, 740, false
    from subtopics s
    cross join lateral jsonb_array_elements_text(
      case when jsonb_typeof(s.subtopic_json->'caseStudies') = 'array'
        then s.subtopic_json->'caseStudies' else '[]'::jsonb end
    ) as item_row(item_text)

    union all

    select s.package_key, s.package_version, s.source_version,
      s.domain_id, s.domain_title, s.competency_id, s.competency_title,
      s.topic_id, s.topic_title, s.subtopic_id, s.subtopic_title,
      'Formula', item_text, 720, false
    from subtopics s
    cross join lateral jsonb_array_elements_text(
      case when jsonb_typeof(s.subtopic_json->'formulas') = 'array'
        then s.subtopic_json->'formulas' else '[]'::jsonb end
    ) as item_row(item_text)

    union all

    select s.package_key, s.package_version, s.source_version,
      s.domain_id, s.domain_title, s.competency_id, s.competency_title,
      s.topic_id, s.topic_title, s.subtopic_id, s.subtopic_title,
      'Reference', item_text, 650, false
    from subtopics s
    cross join lateral jsonb_array_elements_text(
      case when jsonb_typeof(s.subtopic_json->'references') = 'array'
        then s.subtopic_json->'references' else '[]'::jsonb end
    ) as item_row(item_text)

    union all

    select package_key, package_version, source_version,
      domain_id, domain_title, competency_id, competency_title,
      topic_id, topic_title, subtopic_id, subtopic_title,
      'Topic', topic_title, 700, true
    from subtopics

    union all

    select package_key, package_version, source_version,
      domain_id, domain_title, competency_id, competency_title,
      topic_id, topic_title, subtopic_id, subtopic_title,
      'Competency', competency_title, 640, true
    from subtopics

    union all

    select package_key, package_version, source_version,
      domain_id, domain_title, competency_id, competency_title,
      topic_id, topic_title, subtopic_id, subtopic_title,
      'Competency', competency_id, 620, true
    from subtopics

    union all

    select package_key, package_version, source_version,
      domain_id, domain_title, competency_id, competency_title,
      topic_id, topic_title, subtopic_id, subtopic_title,
      'Domain', domain_title, 580, true
    from subtopics

    union all

    select package_key, package_version, source_version,
      domain_id, domain_title, competency_id, competency_title,
      topic_id, topic_title, subtopic_id, subtopic_title,
      'Domain', upper(domain_id), 560, true
    from subtopics
  )
  select distinct
    f.package_key,
    f.package_version,
    f.source_version,
    f.domain_id,
    f.domain_title,
    f.competency_id,
    f.competency_title,
    f.topic_id,
    f.topic_title,
    f.subtopic_id,
    f.subtopic_title,
    f.section_name,
    trim(f.field_text),
    public.csp11_search_normalize(f.field_text),
    replace(public.csp11_search_normalize(f.field_text), ' ', ''),
    f.weight,
    f.contextual
  from fields f
  where coalesce(trim(f.field_text), '') <> ''
    and public.csp11_search_normalize(f.field_text) <> '';

  get diagnostics inserted_count = row_count;
  return inserted_count;
end;
$$;

revoke all on function public.refresh_published_study_search_index() from public;
revoke all on function public.refresh_published_study_search_index() from anon;
revoke all on function public.refresh_published_study_search_index() from authenticated;
grant execute on function public.refresh_published_study_search_index() to service_role;

create or replace function public.search_published_study_content(
  p_query text,
  p_limit integer default 8
)
returns table (
  domain_id text,
  domain_title text,
  competency_id text,
  competency_title text,
  topic_id text,
  topic_title text,
  subtopic_id text,
  subtopic_title text,
  match_section text,
  matched_text text,
  score integer
)
language sql
stable
security definer
set search_path = public
as $$
with params as (
  select
    public.csp11_search_normalize(coalesce(p_query, '')) as query_text,
    greatest(1, least(coalesce(p_limit, 8), 20)) as result_limit
), scored as (
  select
    idx.*,
    case
      when idx.normalized_text = params.query_text
        then idx.weight + 500
      when idx.normalized_text like params.query_text || ' %'
        then idx.weight + 420
      when (' ' || idx.normalized_text || ' ')
        like ('% ' || params.query_text || ' %')
        then idx.weight + 340
      when params.query_text <> '' and not exists (
        select 1
        from regexp_split_to_table(params.query_text, ' ') as qt(token)
        where length(qt.token) >= 2
          and not exists (
            select 1
            from regexp_split_to_table(idx.normalized_text, ' ') as vt(token)
            where vt.token like qt.token || '%'
          )
      )
        then idx.weight + 220
      when length(replace(params.query_text, ' ', '')) >= 4
        and idx.compact_text like '%' || replace(params.query_text, ' ', '') || '%'
        then idx.weight + 180
      else -1
    end as computed_score
  from public.published_study_search_index idx
  cross join params
  where length(params.query_text) >= 2
), best_per_subtopic as (
  select scored.*,
    row_number() over (
      partition by competency_id, subtopic_id
      order by computed_score desc, weight desc, section_name, field_text
    ) as best_rank
  from scored
  where computed_score >= 0
), best_matches as (
  select * from best_per_subtopic where best_rank = 1
), diversity_ranked as (
  select best_matches.*,
    case when contextual then row_number() over (
      partition by competency_id, contextual
      order by computed_score desc, topic_id, subtopic_id
    ) else 1 end as context_rank
  from best_matches
)
select
  domain_id,
  domain_title,
  competency_id,
  competency_title,
  topic_id,
  topic_title,
  subtopic_id,
  subtopic_title,
  section_name as match_section,
  field_text as matched_text,
  computed_score::integer as score
from diversity_ranked
cross join params
where (not contextual or context_rank <= 2)
order by
  computed_score desc,
  domain_id,
  competency_id,
  topic_id,
  lower(subtopic_title),
  subtopic_id
limit (select result_limit from params);
$$;

revoke all on function public.search_published_study_content(text, integer) from public;
revoke all on function public.search_published_study_content(text, integer) from anon;
revoke all on function public.search_published_study_content(text, integer) from authenticated;
grant execute on function public.search_published_study_content(text, integer) to service_role;

select public.refresh_published_study_search_index();
