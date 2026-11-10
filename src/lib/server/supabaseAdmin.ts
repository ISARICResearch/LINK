import { createClient } from "@supabase/supabase-js";

export const supabaseAdmin = createClient(
  process.env.VITE_SUPABASE_URL!,
  process.env.NEW_SEGMENTS_SUPABASE_KEY!,
  { auth: { persistSession: false, autoRefreshToken: false } }
);