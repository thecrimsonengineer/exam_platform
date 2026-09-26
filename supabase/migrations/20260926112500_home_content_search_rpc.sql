create or replace function public.csp11_search_normalize(value text)
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
            replace(value, '&', ' and '),
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
    public.csp11_search_normalize(coalesce(p_query, '')) as query,
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
    source.domain_id,
    source.domain_title,
    source.competency_id,
    source.competency_title,
    topic->>'id' as topic_id,
    topic->>'title' as topic_title,
    subtopic->>'id' as subtopic_id,
    subtopic->>'title' as subtopic_title,
    subtopic
  from published_sources source
  cross join lateral jsonb_array_elements(
    case
      when jsonb_typeof(source.content_payload->'topics') = 'array'
        then source.content_payload->'topics'
      else '[]'::jsonb
    end
  ) topic
  cross join lateral jsonb_array_elements(
    case
      when jsonb_typeof(topic->'subtopics') = 'array'
        then topic->'subtopics'
      else '[]'::jsonb
    end
  ) subtopic
  where coalesce(topic->>'id', '') <> ''
    and coalesce(subtopic->>'id', '') <> ''
), fields as (
  select
    domain_id, domain_title, competency_id, competency_title,
    topic_id, topic_title, subtopic_id, subtopic_title,
    'Subtopic'::text as section,
    subtopic_title as field_text,
    1100 as weight,
    false as contextual
  from subtopics

  union all

  select
    s.domain_id, s.domain_title, s.competency_id, s.competency_title,
    s.topic_id, s.topic_title, s.subtopic_id, s.subtopic_title,
    'Learning objective', value, 940, false
  from subtopics s
  cross join lateral jsonb_array_elements_text(
    case
      when jsonb_typeof(s.subtopic->'learningObjectives') = 'array'
        then s.subtopic->'learningObjectives'
      else '[]'::jsonb
    end
  ) value

  union all

  select
    s.domain_id, s.domain_title, s.competency_id, s.competency_title,
    s.topic_id, s.topic_title, s.subtopic_id, s.subtopic_title,
    'Main content', value #>> '{}', 840, false
  from subtopics s
  cross join lateral jsonb_array_elements(
    case
      when jsonb_typeof(s.subtopic->'blocks') = 'array'
        then s.subtopic->'blocks'
      else '[]'::jsonb
    end
  ) block
  cross join lateral jsonb_path_query(
    coalesce(block->'data', '{}'::jsonb),
    '$.** ? (@.type() == "string")'
  ) value
  where not (
    lower(coalesce(block->>'type', '')) = 'reference'
    and public.csp11_search_normalize(coalesce(block->'data'->>'title', '')) =
      'csp source traceability'
  )

  union all

  select
    s.domain_id, s.domain_title, s.competency_id, s.competency_title,
    s.topic_id, s.topic_title, s.subtopic_id, s.subtopic_title,
    'Key point', value, 820, false
  from subtopics s
  cross join lateral jsonb_array_elements_text(
    case when jsonb_typeof(s.subtopic->'keyPoints') = 'array'
      then s.subtopic->'keyPoints' else '[]'::jsonb end
  ) value

  union all

  select
    s.domain_id, s.domain_title, s.competency_id, s.competency_title,
    s.topic_id, s.topic_title, s.subtopic_id, s.subtopic_title,
    'Key takeaway', value, 810, false
  from subtopics s
  cross join lateral jsonb_array_elements_text(
    case when jsonb_typeof(s.subtopic->'keyTakeaways') = 'array'
      then s.subtopic->'keyTakeaways' else '[]'::jsonb end
  ) value

  union all

  select
    s.domain_id, s.domain_title, s.competency_id, s.competency_title,
    s.topic_id, s.topic_title, s.subtopic_id, s.subtopic_title,
    'Exam tip', value, 790, false
  from subtopics s
  cross join lateral jsonb_array_elements_text(
    case when jsonb_typeof(s.subtopic->'examTips') = 'array'
      then s.subtopic->'examTips' else '[]'::jsonb end
  ) value

  union all

  select
    s.domain_id, s.domain_title, s.competency_id, s.competency_title,
    s.topic_id, s.topic_title, s.subtopic_id, s.subtopic_title,
    'Workplace example', value, 770, false
  from subtopics s
  cross join lateral jsonb_array_elements_text(
    case when jsonb_typeof(s.subtopic->'examples') = 'array'
      then s.subtopic->'examples' else '[]'::jsonb end
  ) value

  union all

  select
    s.domain_id, s.domain_title, s.competency_id, s.competency_title,
    s.topic_id, s.topic_title, s.subtopic_id, s.subtopic_title,
    'Common mistake', value, 750, false
  from subtopics s
  cross join lateral jsonb_array_elements_text(
    case when jsonb_typeof(s.subtopic->'commonMistakes') = 'array'
      then s.subtopic->'commonMistakes' else '[]'::jsonb end
  ) value

  union all

  select
    s.domain_id, s.domain_title, s.competency_id, s.competency_title,
    s.topic_id, s.topic_title, s.subtopic_id, s.subtopic_title,
    'Case study', value, 740, false
  from subtopics s
  cross join lateral jsonb_array_elements_text(
    case when jsonb_typeof(s.subtopic->'caseStudies') = 'array'
      then s.subtopic->'caseStudies' else '[]'::jsonb end
  ) value

  union all

  select
    s.domain_id, s.domain_title, s.competency_id, s.competency_title,
    s.topic_id, s.topic_title, s.subtopic_id, s.subtopic_title,
    'Formula', value, 720, false
  from subtopics s
  cross join lateral jsonb_array_elements_text(
    case when jsonb_typeof(s.subtopic->'formulas') = 'array'
      then s.subtopic->'formulas' else '[]'::jsonb end
  ) value

  union all

  select
    s.domain_id, s.domain_title, s.competency_id, s.competency_title,
    s.topic_id, s.topic_title, s.subtopic_id, s.subtopic_title,
    'Reference', value, 650, false
  from subtopics s
  cross join lateral jsonb_array_elements_text(
    case when jsonb_typeof(s.subtopic->'references') = 'array'
      then s.subtopic->'references' else '[]'::jsonb end
  ) value

  union all

  select
    domain_id, domain_title, competency_id, competency_title,
    topic_id, topic_title, subtopic_id, subtopic_title,
    'Topic', topic_title, 700, true
  from subtopics

  union all

  select
    domain_id, domain_title, competency_id, competency_title,
    topic_id, topic_title, subtopic_id, subtopic_title,
    'Competency', competency_title, 640, true
  from subtopics

  union all

  select
    domain_id, domain_title, competency_id, competency_title,
    topic_id, topic_title, subtopic_id, subtopic_title,
    'Competency', competency_id, 620, true
  from subtopics

  union all

  select
    domain_id, domain_title, competency_id, competency_title,
    topic_id, topic_title, subtopic_id, subtopic_title,
    'Domain', domain_title, 580, true
  from subtopics

  union all

  select
    domain_id, domain_title, competency_id, competency_title,
    topic_id, topic_title, subtopic_id, subtopic_title,
    'Domain', upper(domain_id), 560, true
  from subtopics
), normalized_fields as (
  select
    fields.*,
    public.csp11_search_normalize(field_text) as normalized_text
  from fields
  where coalesce(trim(field_text), '') <> ''
), scored as (
  select
    field.*,
    case
      when field.normalized_text = params.query
        then field.weight + 500
      when field.normalized_text like params.query || ' %'
        then field.weight + 420
      when (' ' || field.normalized_text || ' ')
        like ('% ' || params.query || ' %')
        then field.weight + 340
      when params.query <> ''
        and not exists (
          select 1
          from regexp_split_to_table(params.query, ' ') query_token
          where length(query_token) >= 2
            and not exists (
              select 1
              from regexp_split_to_table(field.normalized_text, ' ') value_token
              where value_token like query_token || '%'
            )
        )
        then field.weight + 220
      when length(replace(params.query, ' ', '')) >= 4
        and replace(field.normalized_text, ' ', '')
          like '%' || replace(params.query, ' ', '') || '%'
        then field.weight + 180
      else -1
    end as computed_score
  from normalized_fields field
  cross join params
  where length(params.query) >= 2
), best_per_subtopic as (
  select
    scored.*,
    row_number() over (
      partition by competency_id, subtopic_id
      order by computed_score desc, weight desc, section, field_text
    ) as best_rank
  from scored
  where computed_score >= 0
), best_matches as (
  select *
  from best_per_subtopic
  where best_rank = 1
), diversity_ranked as (
  select
    best_matches.*,
    case
      when contextual then row_number() over (
        partition by competency_id, contextual
        order by computed_score desc, topic_id, subtopic_id
      )
      else 1
    end as context_rank
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
  section as match_section,
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

revoke all on function public.csp11_search_normalize(text) from public;
revoke all on function public.search_published_study_content(text, integer) from public;
revoke all on function public.search_published_study_content(text, integer) from anon;
revoke all on function public.search_published_study_content(text, integer) from authenticated;
grant execute on function public.search_published_study_content(text, integer) to service_role;
