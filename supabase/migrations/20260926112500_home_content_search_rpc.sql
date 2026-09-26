create or replace function public.csp11_search_normalize(input_text text)
returns text
language sql
immutable
strict
set search_path = public
as $$
  select trim(
    regexp_replace(
      regexp_replace(
        lower(
          translate(
            replace(input_text, '&', ' and '),
            '₀₁₂₃₄₅₆₇₈₉',
            '0123456789'
          )
        ),
        '[^a-z0-9]+',
        ' ',
        'g'
      ),
      '\s+',
      ' ',
      'g'
    )
  );
$$;

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
), published_sources as (
  select
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
    and coalesce(subtopic_item->>'id', '') <> ''
), fields as (
  select
    domain_id, domain_title, competency_id, competency_title,
    topic_id, topic_title, subtopic_id, subtopic_title,
    'Subtopic'::text as section_name,
    subtopic_title as field_text,
    1100 as weight,
    false as contextual
  from subtopics

  union all

  select
    s.domain_id, s.domain_title, s.competency_id, s.competency_title,
    s.topic_id, s.topic_title, s.subtopic_id, s.subtopic_title,
    'Learning objective', objective_text, 940, false
  from subtopics s
  cross join lateral jsonb_array_elements_text(
    case when jsonb_typeof(s.subtopic_json->'learningObjectives') = 'array'
      then s.subtopic_json->'learningObjectives' else '[]'::jsonb end
  ) as objective_row(objective_text)

  union all

  select
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

  select
    s.domain_id, s.domain_title, s.competency_id, s.competency_title,
    s.topic_id, s.topic_title, s.subtopic_id, s.subtopic_title,
    'Key point', item_text, 820, false
  from subtopics s
  cross join lateral jsonb_array_elements_text(
    case when jsonb_typeof(s.subtopic_json->'keyPoints') = 'array'
      then s.subtopic_json->'keyPoints' else '[]'::jsonb end
  ) as item_row(item_text)

  union all

  select
    s.domain_id, s.domain_title, s.competency_id, s.competency_title,
    s.topic_id, s.topic_title, s.subtopic_id, s.subtopic_title,
    'Key takeaway', item_text, 810, false
  from subtopics s
  cross join lateral jsonb_array_elements_text(
    case when jsonb_typeof(s.subtopic_json->'keyTakeaways') = 'array'
      then s.subtopic_json->'keyTakeaways' else '[]'::jsonb end
  ) as item_row(item_text)

  union all

  select
    s.domain_id, s.domain_title, s.competency_id, s.competency_title,
    s.topic_id, s.topic_title, s.subtopic_id, s.subtopic_title,
    'Exam tip', item_text, 790, false
  from subtopics s
  cross join lateral jsonb_array_elements_text(
    case when jsonb_typeof(s.subtopic_json->'examTips') = 'array'
      then s.subtopic_json->'examTips' else '[]'::jsonb end
  ) as item_row(item_text)

  union all

  select
    s.domain_id, s.domain_title, s.competency_id, s.competency_title,
    s.topic_id, s.topic_title, s.subtopic_id, s.subtopic_title,
    'Workplace example', item_text, 770, false
  from subtopics s
  cross join lateral jsonb_array_elements_text(
    case when jsonb_typeof(s.subtopic_json->'examples') = 'array'
      then s.subtopic_json->'examples' else '[]'::jsonb end
  ) as item_row(item_text)

  union all

  select
    s.domain_id, s.domain_title, s.competency_id, s.competency_title,
    s.topic_id, s.topic_title, s.subtopic_id, s.subtopic_title,
    'Common mistake', item_text, 750, false
  from subtopics s
  cross join lateral jsonb_array_elements_text(
    case when jsonb_typeof(s.subtopic_json->'commonMistakes') = 'array'
      then s.subtopic_json->'commonMistakes' else '[]'::jsonb end
  ) as item_row(item_text)

  union all

  select
    s.domain_id, s.domain_title, s.competency_id, s.competency_title,
    s.topic_id, s.topic_title, s.subtopic_id, s.subtopic_title,
    'Case study', item_text, 740, false
  from subtopics s
  cross join lateral jsonb_array_elements_text(
    case when jsonb_typeof(s.subtopic_json->'caseStudies') = 'array'
      then s.subtopic_json->'caseStudies' else '[]'::jsonb end
  ) as item_row(item_text)

  union all

  select
    s.domain_id, s.domain_title, s.competency_id, s.competency_title,
    s.topic_id, s.topic_title, s.subtopic_id, s.subtopic_title,
    'Formula', item_text, 720, false
  from subtopics s
  cross join lateral jsonb_array_elements_text(
    case when jsonb_typeof(s.subtopic_json->'formulas') = 'array'
      then s.subtopic_json->'formulas' else '[]'::jsonb end
  ) as item_row(item_text)

  union all

  select
    s.domain_id, s.domain_title, s.competency_id, s.competency_title,
    s.topic_id, s.topic_title, s.subtopic_id, s.subtopic_title,
    'Reference', item_text, 650, false
  from subtopics s
  cross join lateral jsonb_array_elements_text(
    case when jsonb_typeof(s.subtopic_json->'references') = 'array'
      then s.subtopic_json->'references' else '[]'::jsonb end
  ) as item_row(item_text)

  union all

  select domain_id, domain_title, competency_id, competency_title,
    topic_id, topic_title, subtopic_id, subtopic_title,
    'Topic', topic_title, 700, true
  from subtopics

  union all

  select domain_id, domain_title, competency_id, competency_title,
    topic_id, topic_title, subtopic_id, subtopic_title,
    'Competency', competency_title, 640, true
  from subtopics

  union all

  select domain_id, domain_title, competency_id, competency_title,
    topic_id, topic_title, subtopic_id, subtopic_title,
    'Competency', competency_id, 620, true
  from subtopics

  union all

  select domain_id, domain_title, competency_id, competency_title,
    topic_id, topic_title, subtopic_id, subtopic_title,
    'Domain', domain_title, 580, true
  from subtopics

  union all

  select domain_id, domain_title, competency_id, competency_title,
    topic_id, topic_title, subtopic_id, subtopic_title,
    'Domain', upper(domain_id), 560, true
  from subtopics
), normalized_fields as (
  select f.*, public.csp11_search_normalize(f.field_text) as normalized_text
  from fields f
  where coalesce(trim(f.field_text), '') <> ''
), scored as (
  select
    f.*,
    case
      when f.normalized_text = p.query_text then f.weight + 500
      when f.normalized_text like p.query_text || ' %' then f.weight + 420
      when (' ' || f.normalized_text || ' ')
        like ('% ' || p.query_text || ' %') then f.weight + 340
      when p.query_text <> '' and not exists (
        select 1
        from regexp_split_to_table(p.query_text, ' ') as qt(token)
        where length(qt.token) >= 2
          and not exists (
            select 1
            from regexp_split_to_table(f.normalized_text, ' ') as vt(token)
            where vt.token like qt.token || '%'
          )
      ) then f.weight + 220
      when length(replace(p.query_text, ' ', '')) >= 4
        and replace(f.normalized_text, ' ', '')
          like '%' || replace(p.query_text, ' ', '') || '%'
        then f.weight + 180
      else -1
    end as computed_score
  from normalized_fields f
  cross join params p
  where length(p.query_text) >= 2
), best_per_subtopic as (
  select s.*,
    row_number() over (
      partition by s.competency_id, s.subtopic_id
      order by s.computed_score desc, s.weight desc, s.section_name, s.field_text
    ) as best_rank
  from scored s
  where s.computed_score >= 0
), best_matches as (
  select * from best_per_subtopic where best_rank = 1
), diversity_ranked as (
  select b.*,
    case when b.contextual then row_number() over (
      partition by b.competency_id, b.contextual
      order by b.computed_score desc, b.topic_id, b.subtopic_id
    ) else 1 end as context_rank
  from best_matches b
)
select
  d.domain_id,
  d.domain_title,
  d.competency_id,
  d.competency_title,
  d.topic_id,
  d.topic_title,
  d.subtopic_id,
  d.subtopic_title,
  d.section_name as match_section,
  d.field_text as matched_text,
  d.computed_score::integer as score
from diversity_ranked d
cross join params p
where (not d.contextual or d.context_rank <= 2)
order by
  d.computed_score desc,
  d.domain_id,
  d.competency_id,
  d.topic_id,
  lower(d.subtopic_title),
  d.subtopic_id
limit (select result_limit from params);
$$;

revoke all on function public.csp11_search_normalize(text) from public;
revoke all on function public.search_published_study_content(text, integer) from public;
revoke all on function public.search_published_study_content(text, integer) from anon;
revoke all on function public.search_published_study_content(text, integer) from authenticated;
grant execute on function public.search_published_study_content(text, integer) to service_role;
