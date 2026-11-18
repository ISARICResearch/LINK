-- =====================================================================
-- get_valid_and_user_suggestion
-- Changes vs. original:
--   1. A translation whose step is 'accepted' is valid even with a score of 0
--      (or a null score). Other steps still need score >= p_min_score.
--   2. A "valid" suggestion with null/blank translation text is discarded.
--      The user's own suggestion must also have non-blank text.
--   3. The reset of the "valid" variables now happens BEFORE the user-suggestion
--      lookup, so an invalid candidate can never hide the user's own suggestion.
-- =====================================================================
create or replace function get_valid_and_user_suggestion(
  p_segment_id int8,
  p_min_score int2,
  p_language text,
  p_user_id uuid
)
returns table (
  valid_forward_id int8,
  valid_forward_text text,
  valid_forward_user uuid,
  valid_accepted_id int8,
  valid_accepted_step "TranslationStep",
  valid_accepted_score int2,
  user_forward_id int8,
  user_forward_text text
)
language plpgsql
stable
as $get_valid$
declare
  -- Possible valid suggestion
  v_forward_id int8;
  v_forward_text text;
  v_forward_user uuid;
  v_forward_time timestamptz;
  v_skipped boolean;
  v_accepted_id int8;
  v_accepted_step "TranslationStep";
  v_accepted_score int2;
  v_is_accepted boolean;
  v_valid boolean := false;
  -- Auxiliary user-posed suggestion
  v_user_forward_id int8;
  v_user_forward_text text;
begin
  -- A. Most recent accepted_translation for this original_segment and language
  select a.id, a.score, a.translation_step, a.translation_id
    into v_accepted_id, v_accepted_score, v_accepted_step, v_forward_id
  from accepted_translations a
  where a.original_id = p_segment_id
    and a.language = p_language
  order by a.created_at desc
  limit 1;

  -- B. Valid if step is 'accepted' (any score), or score >= minimum.
  --    Compared via text so an unexpected enum label can't raise an error.
  v_is_accepted := coalesce(lower(v_accepted_step::text) = 'accepted', false);

  if v_accepted_id is not null
     and (v_is_accepted or v_accepted_score >= p_min_score) then
    select f.user_id, f.translation, f.created_at, f.skipped
      into v_forward_user, v_forward_text, v_forward_time, v_skipped
    from forward_translations as f
    where f.id = v_forward_id;

    -- Never allow null or blank text
    v_valid := nullif(btrim(v_forward_text), '') is not null 
        and not coalesce(v_skipped, false);
  end if;

  -- C. If not valid, reset everything so it reads as all null
  if not v_valid then
    v_forward_id := null;
    v_forward_text := null;
    v_forward_user := null;
    v_forward_time := null;
    v_accepted_id := null;
    v_accepted_step := null;
    v_accepted_score := null;
  end if;

  -- D. Independently, check whether this user already has their own suggestion
  --    (only if there is no valid one, or the user's is more recent than it).
  select u.id, u.translation
    into v_user_forward_id, v_user_forward_text
  from forward_translations as u
  where u.original_id = p_segment_id
    and u.language = p_language
    and u.user_id = p_user_id
    and nullif(btrim(u.translation), '') is not null
    and (v_forward_time is null
         or (v_forward_id is distinct from u.id and u.created_at > v_forward_time))
  order by u.created_at desc
  limit 1;

  -- E. Return
  return query
  select
    v_forward_id,
    v_forward_text,
    v_forward_user,
    v_accepted_id,
    v_accepted_step,
    v_accepted_score,
    v_user_forward_id,
    v_user_forward_text;
end;
$get_valid$;


-- =====================================================================
-- find_similar_segments
-- Changes vs. original:
--   1. Accepted translations rank above everything else (then by score).
--   2. Rows with null/blank translation text are filtered out.
--   3. user_owned: true if the suggestion was posed by p_user_id.
--      (It was declared in RETURNS TABLE but never returned, which would
--       have raised a structure mismatch error.)
--   4. segment_location (text[]) is returned.
--      ASSUMPTION: it lives in original_segments.location -- rename if not.
-- =====================================================================
create or replace function find_similar_segments(
  p_segment_id int8,
  p_user_id uuid,
  p_language text,
  match_threshold float default 0.5,
  match_count int2 default 3,
  min_accepted_score int2 default 2,
  batch_size int2 default 10,
  max_batches int2 default 10
)
returns table (
  segment_id int8,
  segment_text text,
  score float,
  forward_translation_id int8,
  forward_translation_text text,
  accepted_translation_id int8,
  accepted_translation_step "TranslationStep",
  user_owned boolean,
  segment_location text[]
)
language plpgsql
as $find_similar$
declare
  v_segment_text text;
  v_segment_hash text;
  v_offset int2 := 0;
  v_batch int2 := 0;
  v_found int2 := 0;
begin
  select segment, segment_hash into v_segment_text, v_segment_hash
  from original_segments where id = p_segment_id;

  create temporary table if not exists tmp_results (
    segment_id int8,
    segment_text text,
    score float,
    forward_translation_id int8,
    forward_translation_text text,
    accepted_translation_id int8,
    accepted_translation_step "TranslationStep",
    user_owned boolean,
    segment_location text[]
  ) on commit drop;
  truncate tmp_results;

  -- A. Get all exact matches
  insert into tmp_results (segment_id, segment_text, score, forward_translation_id, forward_translation_text, accepted_translation_id, accepted_translation_step, user_owned, segment_location)
  with matches as (
    select os.id, os.segment, os.location, g.*
    from original_segments os
    cross join lateral get_valid_and_user_suggestion(
      os.id, min_accepted_score, p_language, p_user_id
    ) g
    where os.id <> p_segment_id
      and os.segment_hash = v_segment_hash
  )
  select id, segment, 1.0::float, valid_forward_id, valid_forward_text,
         valid_accepted_id, valid_accepted_step,
         coalesce(valid_forward_user = p_user_id, false), location
  from matches
  where valid_forward_id is not null

  union all

  select id, segment, 1.0::float, user_forward_id, user_forward_text,
         null, null, true, location
  from matches
  where user_forward_id is not null;

  -- B. Fuzzy search in growing batches until enough, or out of tries
  select count(*) into v_found from tmp_results;
  while v_batch < max_batches and v_found < match_count loop

    insert into tmp_results (segment_id, segment_text, score, forward_translation_id, forward_translation_text, accepted_translation_id, accepted_translation_step, user_owned, segment_location)
    with candidates as (
      select os.id, os.segment, os.location, similarity(os.segment, v_segment_text) as sim
      from original_segments os
      where os.id <> p_segment_id
        and os.segment_hash <> v_segment_hash   -- exact matches already handled
        and os.segment % v_segment_text         -- uses the GIN trigram index
      order by sim desc
      limit batch_size
      offset v_offset
    ),
    matches as (
      select c.id, c.segment, c.location, c.sim, g.*
      from candidates c
      cross join lateral get_valid_and_user_suggestion(
        c.id, min_accepted_score, p_language, p_user_id
      ) g
    )
    select id, segment, sim, valid_forward_id, valid_forward_text,
           valid_accepted_id, valid_accepted_step,
           coalesce(valid_forward_user = p_user_id, false), location
    from matches
    where valid_forward_id is not null
      and sim >= match_threshold

    union all

    select id, segment, sim, user_forward_id, user_forward_text,
           null, null, true, location
    from matches
    where user_forward_id is not null
      and sim >= match_threshold;

    select count(*) into v_found from tmp_results;
    v_offset := v_offset + batch_size;
    v_batch := v_batch + 1;

  end loop;

  -- C. Return the best of what we found:
  --    accepted translations first, then by score (exact matches = 1.0).
  --    Dedupe by translation text, keeping the best-ranked copy.
  return query
  select
    d.segment_id,
    d.segment_text,
    d.score,
    d.forward_translation_id,
    d.forward_translation_text,
    d.accepted_translation_id,
    d.accepted_translation_step,
    d.user_owned,
    d.segment_location
  from (
    select distinct on (md5(lower(btrim(t.forward_translation_text)))) t.*
    from tmp_results t
    where nullif(btrim(t.forward_translation_text), '') is not null
    order by md5(lower(btrim(t.forward_translation_text))),
             coalesce(lower(t.accepted_translation_step::text) = 'accepted', false) desc,
             t.score desc,
             t.user_owned desc
  ) d
  order by coalesce(lower(d.accepted_translation_step::text) = 'accepted', false) desc,
           d.score desc
  limit match_count;

end;
$find_similar$;