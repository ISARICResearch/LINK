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
  -- Store information on possible valid suggestion
  v_forward_id int8;
  v_forward_text text;
  v_forward_user uuid;
  v_forward_time timestamptz;
  v_accepted_id int8;
  v_accepted_step "TranslationStep";
  v_accepted_score int2;
  -- Store information on auxillary user-posed suggestion
  v_user_forward_id int8;
  v_user_forward_text text;
begin
  -- A. Get the most recent accepted_translation for this original_segment and language
  select a.id, a.score, a.translation_step, a.translation_id 
    into v_accepted_id, v_accepted_score, v_accepted_step, v_forward_id
  from accepted_translations a
  where a.original_id = p_segment_id
    and a.language = p_language
  order by a.created_at desc
  limit 1;
  
  -- B. Check if score > minimum score: Valid! Get that translation.
  if v_accepted_score is not null and v_accepted_score >= p_min_score then
    select f.user_id, f.translation, f.created_at
      into v_forward_user, v_forward_text, v_forward_time
    from forward_translations as f
    where f.id = v_forward_id;
  end if;

  -- C. Independently, check whether this user already has their own.
  --  If the first attempt was not valid, or if the user's is more 
  --  recent than the valid one: store it.
  select u.id, u.translation 
    into v_user_forward_id, v_user_forward_text 
  from forward_translations as u
  where u.original_id = p_segment_id
    and u.language = p_language
    and u.user_id = p_user_id
    and (v_forward_time is null or ( v_forward_id is distinct from u.id and u.created_at > v_forward_time))
  order by u.created_at desc
  limit 1;

  -- D. If the original one wasn't valid, reset it before pushing so it reads all as null.
  if v_accepted_score < p_min_score or v_accepted_score is null then
    v_forward_id := null;
    v_forward_text := null;
    v_forward_user := null;
    v_accepted_id := null;
    v_accepted_step := null;
    v_accepted_score := null;
  end if;

  -- E. Handle return
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
