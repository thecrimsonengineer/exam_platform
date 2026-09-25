-- FCC-1 protected Flashcard publication.
-- Registers one immutable Flashcard package version and atomically selects it
-- as the current version for a single CSP11 competency.

create or replace function public.fcc_commit_flashcard_publication(p_payload jsonb)
returns void
language plpgsql
set search_path to 'public', 'pg_temp'
as $function$
declare
  v_competency text := btrim(p_payload ->> 'competencyId');
  v_published_at timestamptz := (p_payload ->> 'publishedAt')::timestamptz;
  v_flashcards jsonb := p_payload -> 'flashcards';
  v_version integer;
  v_domain text;
  v_expected_path text;
  v_existing public.published_packages%rowtype;
  v_changed integer;
begin
  if v_competency is null
     or v_competency !~ '^d0[12]_c[0-9]{2}$' then
    raise exception 'FCC competencyId is invalid';
  end if;

  if v_published_at is null then
    raise exception 'FCC publishedAt is required';
  end if;

  if v_flashcards is null
     or v_flashcards ->> 'kind' <> 'flashcards' then
    raise exception 'FCC flashcards package metadata is required';
  end if;

  v_version := (v_flashcards ->> 'version')::integer;
  v_domain := btrim(v_flashcards ->> 'domainId');
  v_expected_path :=
    'flashcards/' || v_competency || '/v' || v_version::text || '.json.gz';

  if v_version <= 0 then
    raise exception 'FCC package version must be positive';
  end if;

  if v_domain <> substring(v_competency from 1 for 3) then
    raise exception 'FCC domain/competency identity mismatch';
  end if;

  if (v_flashcards ->> 'storageBucket') <> 'csp11-published-packages' then
    raise exception 'FCC package bucket mismatch';
  end if;

  if btrim(v_flashcards ->> 'storagePath') <> v_expected_path then
    raise exception 'FCC package path mismatch';
  end if;

  if (v_flashcards ->> 'checksumSha256') !~ '^[0-9a-f]{64}$' then
    raise exception 'FCC package checksum must be lowercase SHA-256';
  end if;

  if (v_flashcards ->> 'compressedBytes')::bigint <= 0
     or (v_flashcards ->> 'itemCount')::integer <= 0 then
    raise exception 'FCC package size and card count must be positive';
  end if;

  perform pg_advisory_xact_lock(hashtext('fcc|' || v_competency));

  select *
    into v_existing
    from public.published_packages
   where package_kind = 'flashcards'
     and package_key = v_competency
     and version = v_version;

  if found then
    if v_existing.domain_id <> v_domain
       or v_existing.competency_id <> v_competency
       or v_existing.storage_bucket <> v_flashcards ->> 'storageBucket'
       or v_existing.storage_path <> v_flashcards ->> 'storagePath'
       or v_existing.checksum_sha256 <> v_flashcards ->> 'checksumSha256'
       or v_existing.compressed_bytes is distinct from
          (v_flashcards ->> 'compressedBytes')::bigint
       or v_existing.item_count is distinct from
          (v_flashcards ->> 'itemCount')::integer then
      raise exception 'FCC immutable Flashcard metadata collision for % v%',
        v_competency, v_version;
    end if;
  else
    insert into public.published_packages (
      package_kind,
      package_key,
      version,
      domain_id,
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
      'flashcards',
      v_competency,
      v_version,
      v_domain,
      v_competency,
      v_flashcards ->> 'storageBucket',
      v_flashcards ->> 'storagePath',
      v_flashcards ->> 'checksumSha256',
      (v_flashcards ->> 'compressedBytes')::bigint,
      (v_flashcards ->> 'itemCount')::integer,
      false,
      coalesce(v_flashcards -> 'metadata', '{}'::jsonb),
      v_published_at
    );
  end if;

  update public.published_packages
     set is_current = false
   where package_kind = 'flashcards'
     and package_key = v_competency
     and is_current;

  update public.published_packages
     set is_current = true
   where package_kind = 'flashcards'
     and package_key = v_competency
     and version = v_version;
  get diagnostics v_changed = row_count;

  if v_changed <> 1 then
    raise exception 'FCC current-version switch did not affect exactly one row';
  end if;
end;
$function$;

revoke all on function public.fcc_commit_flashcard_publication(jsonb)
  from public, anon, authenticated;
grant execute on function public.fcc_commit_flashcard_publication(jsonb)
  to service_role;
