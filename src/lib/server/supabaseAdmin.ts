import { NEW_SEGMENTS_SUPABASE_KEY, VITE_SUPABASE_URL } from "$env/static/private";
import { createClient } from "@supabase/supabase-js";

export const supabaseAdmin = createClient(
  VITE_SUPABASE_URL,
  NEW_SEGMENTS_SUPABASE_KEY,
  { auth: { persistSession: false, autoRefreshToken: false } }
);