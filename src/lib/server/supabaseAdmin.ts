import { env } from '$env/dynamic/private';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

/*
export const supabaseAdmin = createClient(env.VITE_SUPABASE_URL, env.NEW_SEGMENTS_SUPABASE_KEY, {
	auth: { persistSession: false, autoRefreshToken: false }
});*/

let client: SupabaseClient | undefined;

export const supabaseAdmin = () =>{
  if (!client) {
    const url = env.VITE_SUPABASE_URL;
    const key = env.NEW_SEGMENTS_SUPABASE_KEY;
    if (!url || !key) throw new Error("Supabase admin env vars are not set");
    client = createClient(url, key, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
  }
  return client;
}