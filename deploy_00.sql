

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE EXTENSION IF NOT EXISTS "pgsodium";






COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pg_trgm" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE TYPE "public"."LabelType" AS ENUM (
    'form',
    'section'
);


ALTER TYPE "public"."LabelType" OWNER TO "postgres";


COMMENT ON TYPE "public"."LabelType" IS 'Type of label for arch; form or sections, at the moment';



CREATE TYPE "public"."Language" AS ENUM (
    'spanish',
    'french',
    'portuguese'
);


ALTER TYPE "public"."Language" OWNER TO "postgres";


CREATE TYPE "public"."SegmentType" AS ENUM (
    'listItem',
    'question',
    'answerOption',
    'definition',
    'completionGuide',
    'formLabel',
    'sectionLabel'
);


ALTER TYPE "public"."SegmentType" OWNER TO "postgres";


COMMENT ON TYPE "public"."SegmentType" IS 'Define what part of ARC the segment is from';



CREATE TYPE "public"."TranslationStep" AS ENUM (
    'forward',
    'review',
    'backward',
    'adjudication',
    'admin'
);


ALTER TYPE "public"."TranslationStep" OWNER TO "postgres";


COMMENT ON TYPE "public"."TranslationStep" IS 'Step that for what part of translation a segment is in';



CREATE OR REPLACE FUNCTION "public"."find_similar_segments"("p_segment_id" bigint, "p_user_id" "uuid", "match_threshold" double precision DEFAULT 0.7, "match_count" smallint DEFAULT 3, "min_accepted_score" smallint DEFAULT 2, "batch_size" smallint DEFAULT 5, "max_batches" smallint DEFAULT 5) RETURNS TABLE("segment_id" bigint, "segment_text" "text", "score" double precision, "forward_translation_id" bigint, "forward_translation_text" "text", "accepted_translation_id" bigint, "accepted_translation_step" "public"."TranslationStep")
    LANGUAGE "plpgsql"
    AS $$
declare
  v_segment_id int8;
  v_segment_text text;
  v_segment_hash text;
  v_user_language "Language";
  v_offset int2 := 0;
  v_batch int2 := 0;
  v_found int2 := 0;
begin
  select segment, segment_hash into v_segment_text, v_segment_hash
  from original_segments where id = p_segment_id;

  select language into v_user_language
  from profiles where id = p_user_id;

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
      os.id, min_accepted_score, v_user_language, p_user_id
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
        c.id, min_accepted_score, v_user_language, p_user_id
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
$$;


ALTER FUNCTION "public"."find_similar_segments"("p_segment_id" bigint, "p_user_id" "uuid", "match_threshold" double precision, "match_count" smallint, "min_accepted_score" smallint, "batch_size" smallint, "max_batches" smallint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_valid_and_user_suggestion"("p_segment_id" bigint, "p_min_score" smallint, "p_language" "public"."Language", "p_user_id" "uuid") RETURNS TABLE("valid_forward_id" bigint, "valid_forward_text" "text", "valid_forward_user" "uuid", "valid_accepted_id" bigint, "valid_accepted_step" "public"."TranslationStep", "valid_accepted_score" smallint, "user_forward_id" bigint, "user_forward_text" "text")
    LANGUAGE "plpgsql" STABLE
    AS $$
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
$$;


ALTER FUNCTION "public"."get_valid_and_user_suggestion"("p_segment_id" bigint, "p_min_score" smallint, "p_language" "public"."Language", "p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
begin
  insert into public.profiles (id, name, language, profession)
  values (
    new.id, 
    new.raw_user_meta_data->>'name', 
    new.raw_user_meta_data->>'language', 
    new.raw_user_meta_data->>'profession');
  return new;
end;
$$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."accepted_translations" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "original_id" bigint NOT NULL,
    "translation_id" bigint NOT NULL,
    "language" "public"."Language" NOT NULL,
    "translation_step" "public"."TranslationStep" NOT NULL,
    "score" "text" DEFAULT ''::"text" NOT NULL
);


ALTER TABLE "public"."accepted_translations" OWNER TO "postgres";


COMMENT ON TABLE "public"."accepted_translations" IS 'Translations accepted and pushed to ARC. Serves as record for all changes made and current best translation.';



ALTER TABLE "public"."accepted_translations" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."accepted_translations_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."backward_translations" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "original_id" bigint NOT NULL,
    "language" "public"."Language" NOT NULL,
    "translation" "text",
    "user_id" "uuid" NOT NULL,
    "comment" "text",
    "skipped" boolean DEFAULT false NOT NULL,
    "translation_id" bigint NOT NULL
);


ALTER TABLE "public"."backward_translations" OWNER TO "postgres";


COMMENT ON TABLE "public"."backward_translations" IS 'Store translations of Forward Translation back to Original Segment';



ALTER TABLE "public"."backward_translations" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."backward_translations_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."documents" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "title" "text" NOT NULL,
    "version" "text" NOT NULL,
    "original_ids" bigint[] NOT NULL
);


ALTER TABLE "public"."documents" OWNER TO "postgres";


COMMENT ON TABLE "public"."documents" IS 'Store segmetns in each document at each version';



ALTER TABLE "public"."documents" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."documents_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."forward_translations" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "original_id" bigint NOT NULL,
    "language" "public"."Language" NOT NULL,
    "translation" "text",
    "user_id" "uuid",
    "comment" "text" DEFAULT ''::"text" NOT NULL,
    "skipped" boolean NOT NULL
);


ALTER TABLE "public"."forward_translations" OWNER TO "postgres";


COMMENT ON TABLE "public"."forward_translations" IS 'All forward translations made by machines and users';



ALTER TABLE "public"."forward_translations" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."forwardTranslations_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."original_segments" (
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "location" "text"[],
    "type" "public"."SegmentType" NOT NULL,
    "segment" "text" NOT NULL,
    "answer_options" "text"[],
    "id" bigint NOT NULL,
    "segment_hash" "text" GENERATED ALWAYS AS ("md5"("lower"(TRIM(BOTH FROM "segment")))) STORED
);


ALTER TABLE "public"."original_segments" OWNER TO "postgres";


COMMENT ON TABLE "public"."original_segments" IS 'A list of all original segments in ARC with contextual information such as their type and location.';



ALTER TABLE "public"."original_segments" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."original_segments_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "is_admin" boolean DEFAULT false NOT NULL,
    "name" "text",
    "language" "text",
    "clinical_expertise" boolean,
    "selected_preset" "text" DEFAULT 'ARChetype Disease CRF_Chikungunya'::"text" NOT NULL,
    "profession" "text"
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."translation_reviews" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "original_id" bigint NOT NULL,
    "translation_id" bigint,
    "language" "public"."Language" NOT NULL,
    "reviewer_id" "uuid" NOT NULL,
    "comments" "jsonb" NOT NULL
);


ALTER TABLE "public"."translation_reviews" OWNER TO "postgres";


COMMENT ON TABLE "public"."translation_reviews" IS 'User Reviews of Forward Translations';



ALTER TABLE "public"."translation_reviews" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."translationReviews_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."translation_progress" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "original_id" bigint NOT NULL,
    "language" "public"."Language" NOT NULL,
    "translation_step" "public"."TranslationStep" NOT NULL,
    "automated_comments" "text"[],
    "admin_comments" "text"[]
);


ALTER TABLE "public"."translation_progress" OWNER TO "postgres";


COMMENT ON TABLE "public"."translation_progress" IS 'State that each original segment is in to being translated into a given language.';



ALTER TABLE "public"."translation_progress" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."translation_progress_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



ALTER TABLE ONLY "public"."accepted_translations"
    ADD CONSTRAINT "accepted_translations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."backward_translations"
    ADD CONSTRAINT "backward_translations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."documents"
    ADD CONSTRAINT "documents_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."forward_translations"
    ADD CONSTRAINT "forwardTranslations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."original_segments"
    ADD CONSTRAINT "original_segments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."translation_reviews"
    ADD CONSTRAINT "translationReviews_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."translation_progress"
    ADD CONSTRAINT "translation_progress_pkey" PRIMARY KEY ("id");



CREATE INDEX "idx_segments_segment_hash" ON "public"."original_segments" USING "btree" ("segment_hash");



CREATE INDEX "idx_segments_trgm" ON "public"."original_segments" USING "gin" ("segment" "extensions"."gin_trgm_ops");



ALTER TABLE ONLY "public"."accepted_translations"
    ADD CONSTRAINT "accepted_translations_original_id_fkey" FOREIGN KEY ("original_id") REFERENCES "public"."original_segments"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."accepted_translations"
    ADD CONSTRAINT "accepted_translations_translation_id_fkey" FOREIGN KEY ("translation_id") REFERENCES "public"."forward_translations"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."backward_translations"
    ADD CONSTRAINT "backward_translations_original_id_fkey" FOREIGN KEY ("original_id") REFERENCES "public"."original_segments"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."backward_translations"
    ADD CONSTRAINT "backward_translations_translation_id_fkey" FOREIGN KEY ("translation_id") REFERENCES "public"."forward_translations"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."backward_translations"
    ADD CONSTRAINT "backward_translations_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."forward_translations"
    ADD CONSTRAINT "forward_translations_original_id_fkey" FOREIGN KEY ("original_id") REFERENCES "public"."original_segments"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."forward_translations"
    ADD CONSTRAINT "forward_translations_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."translation_progress"
    ADD CONSTRAINT "translation_progress_original_id_fkey" FOREIGN KEY ("original_id") REFERENCES "public"."original_segments"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."translation_reviews"
    ADD CONSTRAINT "translation_reviews_original_id_fkey" FOREIGN KEY ("original_id") REFERENCES "public"."original_segments"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."translation_reviews"
    ADD CONSTRAINT "translation_reviews_reviewer_id_fkey" FOREIGN KEY ("reviewer_id") REFERENCES "public"."profiles"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."translation_reviews"
    ADD CONSTRAINT "translation_reviews_translation_id_fkey" FOREIGN KEY ("translation_id") REFERENCES "public"."forward_translations"("id") ON UPDATE CASCADE ON DELETE CASCADE;



CREATE POLICY "Allow admins full access to documents" ON "public"."documents" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."is_admin" = true))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."is_admin" = true)))));



CREATE POLICY "Allow admins full access to original_segments" ON "public"."original_segments" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."is_admin" = true))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."is_admin" = true)))));



CREATE POLICY "Allow authenticated users to read profiles" ON "public"."profiles" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Users can update their own selected_preset and profession" ON "public"."profiles" FOR UPDATE USING ((( SELECT "auth"."uid"() AS "uid") = "id")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "id"));



CREATE POLICY "Users can view their own profile" ON "public"."profiles" FOR SELECT USING ((( SELECT "auth"."uid"() AS "uid") = "id"));



ALTER TABLE "public"."accepted_translations" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "authenticated can insert to accepted_translations" ON "public"."accepted_translations" FOR INSERT TO "authenticated" WITH CHECK (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "authenticated can insert to backward_translations" ON "public"."backward_translations" FOR INSERT TO "authenticated" WITH CHECK (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "authenticated can insert to forward_translations" ON "public"."forward_translations" FOR INSERT TO "authenticated" WITH CHECK (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "authenticated can insert to translation_progress" ON "public"."translation_progress" FOR INSERT TO "authenticated" WITH CHECK (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "authenticated can insert to translation_reviews" ON "public"."translation_reviews" FOR INSERT TO "authenticated" WITH CHECK (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "authenticated can select accepted_translations" ON "public"."accepted_translations" FOR SELECT TO "authenticated" USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "authenticated can select backward_translations" ON "public"."backward_translations" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "authenticated can select documents" ON "public"."documents" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "authenticated can select forward_translations" ON "public"."forward_translations" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "authenticated can select original_segments" ON "public"."original_segments" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "authenticated can select translation_progress" ON "public"."translation_progress" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "authenticated can select translation_reviews" ON "public"."translation_reviews" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "authenticated can update accepted_translations" ON "public"."accepted_translations" FOR UPDATE TO "authenticated" USING (("auth"."role"() = 'authenticated'::"text")) WITH CHECK (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "authenticated can update backward_translations" ON "public"."backward_translations" FOR UPDATE TO "authenticated" USING (("auth"."role"() = 'authenticated'::"text")) WITH CHECK (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "authenticated can update forward_translations" ON "public"."forward_translations" FOR UPDATE TO "authenticated" USING (("auth"."role"() = 'authenticated'::"text")) WITH CHECK (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "authenticated can update translation_progress" ON "public"."translation_progress" FOR UPDATE TO "authenticated" USING (("auth"."role"() = 'authenticated'::"text")) WITH CHECK (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "authenticated can update translation_reviews" ON "public"."translation_reviews" FOR UPDATE TO "authenticated" USING (("auth"."role"() = 'authenticated'::"text")) WITH CHECK (("auth"."role"() = 'authenticated'::"text"));



ALTER TABLE "public"."backward_translations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."documents" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."forward_translations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."original_segments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."translation_progress" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."translation_reviews" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

















































































































































































































































































GRANT ALL ON FUNCTION "public"."find_similar_segments"("p_segment_id" bigint, "p_user_id" "uuid", "match_threshold" double precision, "match_count" smallint, "min_accepted_score" smallint, "batch_size" smallint, "max_batches" smallint) TO "anon";
GRANT ALL ON FUNCTION "public"."find_similar_segments"("p_segment_id" bigint, "p_user_id" "uuid", "match_threshold" double precision, "match_count" smallint, "min_accepted_score" smallint, "batch_size" smallint, "max_batches" smallint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."find_similar_segments"("p_segment_id" bigint, "p_user_id" "uuid", "match_threshold" double precision, "match_count" smallint, "min_accepted_score" smallint, "batch_size" smallint, "max_batches" smallint) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_valid_and_user_suggestion"("p_segment_id" bigint, "p_min_score" smallint, "p_language" "public"."Language", "p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_valid_and_user_suggestion"("p_segment_id" bigint, "p_min_score" smallint, "p_language" "public"."Language", "p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_valid_and_user_suggestion"("p_segment_id" bigint, "p_min_score" smallint, "p_language" "public"."Language", "p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";



























GRANT ALL ON TABLE "public"."accepted_translations" TO "anon";
GRANT ALL ON TABLE "public"."accepted_translations" TO "authenticated";
GRANT ALL ON TABLE "public"."accepted_translations" TO "service_role";



GRANT ALL ON SEQUENCE "public"."accepted_translations_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."accepted_translations_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."accepted_translations_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."backward_translations" TO "anon";
GRANT ALL ON TABLE "public"."backward_translations" TO "authenticated";
GRANT ALL ON TABLE "public"."backward_translations" TO "service_role";



GRANT ALL ON SEQUENCE "public"."backward_translations_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."backward_translations_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."backward_translations_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."documents" TO "anon";
GRANT ALL ON TABLE "public"."documents" TO "authenticated";
GRANT ALL ON TABLE "public"."documents" TO "service_role";



GRANT ALL ON SEQUENCE "public"."documents_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."documents_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."documents_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."forward_translations" TO "anon";
GRANT ALL ON TABLE "public"."forward_translations" TO "authenticated";
GRANT ALL ON TABLE "public"."forward_translations" TO "service_role";



GRANT ALL ON SEQUENCE "public"."forwardTranslations_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."forwardTranslations_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."forwardTranslations_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."original_segments" TO "anon";
GRANT ALL ON TABLE "public"."original_segments" TO "authenticated";
GRANT ALL ON TABLE "public"."original_segments" TO "service_role";



GRANT ALL ON SEQUENCE "public"."original_segments_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."original_segments_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."original_segments_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT ALL ON TABLE "public"."translation_reviews" TO "anon";
GRANT ALL ON TABLE "public"."translation_reviews" TO "authenticated";
GRANT ALL ON TABLE "public"."translation_reviews" TO "service_role";



GRANT ALL ON SEQUENCE "public"."translationReviews_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."translationReviews_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."translationReviews_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."translation_progress" TO "anon";
GRANT ALL ON TABLE "public"."translation_progress" TO "authenticated";
GRANT ALL ON TABLE "public"."translation_progress" TO "service_role";



GRANT ALL ON SEQUENCE "public"."translation_progress_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."translation_progress_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."translation_progress_id_seq" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "service_role";






























