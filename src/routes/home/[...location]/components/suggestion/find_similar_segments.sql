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
  v_segment_id int8;
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
    accepted_translation_step "TranslationStep"
  ) on commit drop;
  truncate tmp_results;

  -- A. Get all exact matches
  insert into tmp_results (segment_id, segment_text, score, forward_translation_id, forward_translation_text, accepted_translation_id, accepted_translation_step)
  with matches as (
    select os.id, os.segment, g.*
    from original_segments os
    cross join lateral get_valid_and_user_suggestion(
      os.id, min_accepted_score, p_language, p_user_id
    ) g
    where os.id <> p_segment_id
      and os.segment_hash = v_segment_hash
  )
  select id, segment, 1.0::float, valid_forward_id, valid_forward_text, valid_accepted_id, valid_accepted_step
  from matches
  where valid_forward_id is not null

  union all

  select id, segment, 1.0::float, user_forward_id, user_forward_text, null, null
  from matches
  where user_forward_id is not null;  

  -- B. Fuzzy search in growing batches until enough, or out of tries
  --perform set_limit(match_threshold);
  select count(*) into v_found from tmp_results;
  while v_batch < max_batches and v_found < match_count loop

    insert into tmp_results (segment_id, segment_text, score, forward_translation_id, forward_translation_text, accepted_translation_id, accepted_translation_step)
    with candidates as (
      select os.id, os.segment, similarity(os.segment, v_segment_text) as sim
      from original_segments os
      where os.id <> p_segment_id
        and os.segment_hash <> v_segment_hash        -- skip exact matches, already handled
        and os.segment % v_segment_text            -- uses the GIN trigram index
      order by sim desc
      limit batch_size
      offset v_offset
    ),
    matches as (
      select c.id, c.segment, c.sim, g.*
      from candidates c
      cross join lateral get_valid_and_user_suggestion(
        c.id, min_accepted_score, p_language, p_user_id
      ) g
    )
    select id, segment, sim, valid_forward_id, valid_forward_text, valid_accepted_id, valid_accepted_step
    from matches
    where valid_forward_id is not null
      and sim >= match_threshold

    union all

    select id, segment, sim, user_forward_id, user_forward_text, null, null
    from matches
    where user_forward_id is not null
      and sim >= match_threshold;

    select count(*) into v_found from tmp_results;
    v_offset := v_offset + batch_size;
    v_batch := v_batch + 1;

  end loop;

-- C. Return the best of what we found, exact matches naturally ranked first (score 1.0)
return query
select
  d.segment_id,
  d.segment_text,
  d.score,
  d.forward_translation_id,
  d.forward_translation_text,
  d.accepted_translation_id,
  d.accepted_translation_step
from (
  select distinct on (md5(lower(trim(t.forward_translation_text))))
    t.segment_id, t.segment_text, t.score, t.forward_translation_id,
    t.forward_translation_text, t.accepted_translation_id, t.accepted_translation_step
  from tmp_results t
  order by md5(lower(trim(t.forward_translation_text))), t.score desc
) d
order by d.score desc
limit match_count;

end;
$find_similar$;