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
set search_path = public, extensions, pg_temp
as $$
with params as (
  select
    public.csp11_search_normalize(coalesce(p_query, '')) as query_text,
    greatest(1, least(coalesce(p_limit, 8), 20)) as result_limit
), strict_scored as (
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
    end as computed_score,
    false as fuzzy_match
  from public.published_study_search_index idx
  cross join params
  where length(params.query_text) >= 2
), strict_matches as (
  select *
  from strict_scored
  where computed_score >= 0
), fuzzy_scored as (
  select
    idx.*,
    idx.weight
      + 90
      + floor(extensions.word_similarity(params.query_text, idx.normalized_text) * 120)::integer
      as computed_score,
    true as fuzzy_match
  from public.published_study_search_index idx
  cross join params
  where not exists (select 1 from strict_matches)
    and length(replace(params.query_text, ' ', '')) >= 5
    and idx.normalized_text OPERATOR(extensions.%>) params.query_text
), scored as (
  select * from strict_matches
  union all
  select * from fuzzy_scored
), best_per_subtopic as (
  select
    scored.*,
    row_number() over (
      partition by competency_id, subtopic_id
      order by computed_score desc, weight desc, fuzzy_match, section_name, field_text
    ) as best_rank
  from scored
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
    end as context_rank,
    row_number() over (
      partition by competency_id
      order by computed_score desc, topic_id, subtopic_id
    ) as competency_rank
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
  and competency_rank <= 4
order by
  computed_score desc,
  fuzzy_match,
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
