-- CSP11 Phase FR7 atomic publication boundary candidate.
-- Apply with Supabase migration name: fr7_atomic_publication.
-- After live apply, record the returned migration version in supabase/migrations.

create or replace function public.fr7_commit_competency_publication(
  p_payload jsonb
)
returns void
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  v_competency text := btrim(p_payload ->> 'competencyId');
  v_published_at timestamptz := (p_payload ->> 'publishedAt')::timestamptz;
  v_content jsonb := p_payload -> 'content';
  v_questions jsonb := p_payload -> 'questions';
  v_content_version integer;
  v_question_version integer;
  v_existing public.published_packages%rowtype;
  v_changed integer;
begin
  if v_competency is null or v_competency = '' then
    raise exception 'FR7 competencyId is required';
  end if;
  if v_published_at is null then
    raise exception 'FR7 publishedAt is required';
  end if;
  if v_content is null or v_questions is null then
    raise exception 'FR7 content and questions package metadata are required';
  end if;

  if v_content ->> 'kind' <> 'content'
     or v_questions ->> 'kind' <> 'questions' then
    raise exception 'FR7 package kinds are invalid';
  end if;

  v_content_version := (v_content ->> 'version')::integer;
  v_question_version := (v_questions ->> 'version')::integer;

  if v_content_version <= 0 or v_question_version <= 0 then
    raise exception 'FR7 package versions must be positive';
  end if;

  if (v_content ->> 'storageBucket') <> 'csp11-published-packages'
     or (v_questions ->> 'storageBucket') <> 'csp11-published-packages' then
    raise exception 'FR7 package bucket mismatch';
  end if;

  if (v_content ->> 'checksumSha256') !~ '^[0-9a-f]{64}$'
     or (v_questions ->> 'checksumSha256') !~ '^[0-9a-f]{64}$' then
    raise exception 'FR7 package checksum must be lowercase SHA-256';
  end if;

  if btrim(v_content ->> 'storagePath') = ''
     or btrim(v_questions ->> 'storagePath') = '' then
    raise exception 'FR7 package paths are required';
  end if;

  if (v_content ->> 'compressedBytes')::bigint < 0
     or (v_questions ->> 'compressedBytes')::bigint < 0
     or (v_content ->> 'itemCount')::integer < 0
     or (v_questions ->> 'itemCount')::integer < 0 then
    raise exception 'FR7 package sizes and item counts cannot be negative';
  end if;

  perform pg_advisory_xact_lock(hashtext('fr7|' || v_competency));

  select *
    into v_existing
    from public.published_packages
   where package_kind = 'content'
     and package_key = v_competency
     and version = v_content_version;

  if found then
    if v_existing.storage_bucket <> v_content ->> 'storageBucket'
       or v_existing.storage_path <> v_content ->> 'storagePath'
       or v_existing.checksum_sha256 <> v_content ->> 'checksumSha256'
       or v_existing.compressed_bytes is distinct from
          (v_content ->> 'compressedBytes')::bigint
       or v_existing.item_count is distinct from
          (v_content ->> 'itemCount')::integer then
      raise exception 'FR7 immutable content metadata collision for % v%',
        v_competency, v_content_version;
    end if;
  else
    insert into public.published_packages (
      package_kind,
      package_key,
      version,
      competency_id,
      storage_bucket,
      storage_path,
      checksum_sha256,
      compressed_bytes,
      item_count,
      is_current,
      metadata,
      published_at
    )
    values (
      'content',
      v_competency,
      v_content_version,
      v_competency,
      v_content ->> 'storageBucket',
      v_content ->> 'storagePath',
      v_content ->> 'checksumSha256',
      (v_content ->> 'compressedBytes')::bigint,
      (v_content ->> 'itemCount')::integer,
      false,
      coalesce(v_content -> 'metadata', '{}'::jsonb),
      v_published_at
    );
  end if;

  select *
    into v_existing
    from public.published_packages
   where package_kind = 'questions'
     and package_key = v_competency
     and version = v_question_version;

  if found then
    if v_existing.storage_bucket <> v_questions ->> 'storageBucket'
       or v_existing.storage_path <> v_questions ->> 'storagePath'
       or v_existing.checksum_sha256 <> v_questions ->> 'checksumSha256'
       or v_existing.compressed_bytes is distinct from
          (v_questions ->> 'compressedBytes')::bigint
       or v_existing.item_count is distinct from
          (v_questions ->> 'itemCount')::integer then
      raise exception 'FR7 immutable question metadata collision for % v%',
        v_competency, v_question_version;
    end if;
  else
    insert into public.published_packages (
      package_kind,
      package_key,
      version,
      competency_id,
      storage_bucket,
      storage_path,
      checksum_sha256,
      compressed_bytes,
      item_count,
      is_current,
      metadata,
      published_at
    )
    values (
      'questions',
      v_competency,
      v_question_version,
      v_competency,
      v_questions ->> 'storageBucket',
      v_questions ->> 'storagePath',
      v_questions ->> 'checksumSha256',
      (v_questions ->> 'compressedBytes')::bigint,
      (v_questions ->> 'itemCount')::integer,
      false,
      coalesce(v_questions -> 'metadata', '{}'::jsonb),
      v_published_at
    );
  end if;

  update public.published_packages
     set is_current = false
   where package_kind = 'content'
     and package_key = v_competency
     and is_current;

  update public.published_packages
     set is_current = true
   where package_kind = 'content'
     and package_key = v_competency
     and version = v_content_version;
  get diagnostics v_changed = row_count;
  if v_changed <> 1 then
    raise exception 'FR7 content current switch did not affect exactly one row';
  end if;

  update public.published_packages
     set is_current = false
   where package_kind = 'questions'
     and package_key = v_competency
     and is_current;

  update public.published_packages
     set is_current = true
   where package_kind = 'questions'
     and package_key = v_competency
     and version = v_question_version;
  get diagnostics v_changed = row_count;
  if v_changed <> 1 then
    raise exception 'FR7 question current switch did not affect exactly one row';
  end if;

  -- Catalogue switch is deliberately last inside this transaction.
  insert into public.published_catalog (
    competency_id,
    content_version,
    content_checksum_sha256,
    content_object_path,
    content_size_bytes,
    question_version,
    question_checksum_sha256,
    question_object_path,
    question_size_bytes,
    published_question_count,
    active,
    published_at
  )
  values (
    v_competency,
    v_content_version,
    v_content ->> 'checksumSha256',
    v_content ->> 'storagePath',
    (v_content ->> 'compressedBytes')::bigint,
    v_question_version,
    v_questions ->> 'checksumSha256',
    v_questions ->> 'storagePath',
    (v_questions ->> 'compressedBytes')::bigint,
    (v_questions ->> 'itemCount')::integer,
    true,
    v_published_at
  )
  on conflict (competency_id) do update
  set
    content_version = excluded.content_version,
    content_checksum_sha256 = excluded.content_checksum_sha256,
    content_object_path = excluded.content_object_path,
    content_size_bytes = excluded.content_size_bytes,
    question_version = excluded.question_version,
    question_checksum_sha256 = excluded.question_checksum_sha256,
    question_object_path = excluded.question_object_path,
    question_size_bytes = excluded.question_size_bytes,
    published_question_count = excluded.published_question_count,
    active = true,
    published_at = excluded.published_at;
end;
$$;

revoke execute on function public.fr7_commit_competency_publication(jsonb)
  from public, anon, authenticated;
grant execute on function public.fr7_commit_competency_publication(jsonb) to service_role;

create or replace function public.fr7_rollback_competency_publication(
  p_competency_id text,
  p_content_version integer,
  p_question_version integer
)
returns void
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  v_competency text := btrim(p_competency_id);
  v_content public.published_packages%rowtype;
  v_questions public.published_packages%rowtype;
  v_changed integer;
begin
  if v_competency is null or v_competency = ''
     or p_content_version <= 0
     or p_question_version <= 0 then
    raise exception 'FR7 rollback requires competency and positive package versions';
  end if;

  perform pg_advisory_xact_lock(hashtext('fr7|' || v_competency));

  select *
    into v_content
    from public.published_packages
   where package_kind = 'content'
     and package_key = v_competency
     and version = p_content_version;
  if not found then
    raise exception 'FR7 rollback content package not found';
  end if;

  select *
    into v_questions
    from public.published_packages
   where package_kind = 'questions'
     and package_key = v_competency
     and version = p_question_version;
  if not found then
    raise exception 'FR7 rollback question package not found';
  end if;

  if v_content.storage_bucket <> 'csp11-published-packages'
     or v_questions.storage_bucket <> 'csp11-published-packages' then
    raise exception 'FR7 rollback package bucket mismatch';
  end if;

  update public.published_packages
     set is_current = false
   where package_kind = 'content'
     and package_key = v_competency
     and is_current;
  update public.published_packages
     set is_current = true
   where package_kind = 'content'
     and package_key = v_competency
     and version = p_content_version;
  get diagnostics v_changed = row_count;
  if v_changed <> 1 then
    raise exception 'FR7 rollback content switch failed';
  end if;

  update public.published_packages
     set is_current = false
   where package_kind = 'questions'
     and package_key = v_competency
     and is_current;
  update public.published_packages
     set is_current = true
   where package_kind = 'questions'
     and package_key = v_competency
     and version = p_question_version;
  get diagnostics v_changed = row_count;
  if v_changed <> 1 then
    raise exception 'FR7 rollback question switch failed';
  end if;

  -- Catalogue switch is deliberately last inside this transaction.
  insert into public.published_catalog (
    competency_id,
    content_version,
    content_checksum_sha256,
    content_object_path,
    content_size_bytes,
    question_version,
    question_checksum_sha256,
    question_object_path,
    question_size_bytes,
    published_question_count,
    active,
    published_at
  )
  values (
    v_competency,
    p_content_version,
    v_content.checksum_sha256,
    v_content.storage_path,
    coalesce(v_content.compressed_bytes, 0),
    p_question_version,
    v_questions.checksum_sha256,
    v_questions.storage_path,
    coalesce(v_questions.compressed_bytes, 0),
    coalesce(v_questions.item_count, 0),
    true,
    now()
  )
  on conflict (competency_id) do update
  set
    content_version = excluded.content_version,
    content_checksum_sha256 = excluded.content_checksum_sha256,
    content_object_path = excluded.content_object_path,
    content_size_bytes = excluded.content_size_bytes,
    question_version = excluded.question_version,
    question_checksum_sha256 = excluded.question_checksum_sha256,
    question_object_path = excluded.question_object_path,
    question_size_bytes = excluded.question_size_bytes,
    published_question_count = excluded.published_question_count,
    active = true,
    published_at = excluded.published_at;
end;
$$;

revoke execute on function public.fr7_rollback_competency_publication(
  text,
  integer,
  integer
) from public, anon, authenticated;
grant execute on function public.fr7_rollback_competency_publication(
  text,
  integer,
  integer
) to service_role;
