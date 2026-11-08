import { env } from '$env/dynamic/private';
import { createClient } from '@supabase/supabase-js';

export const supabaseAdmin = createClient(env.VITE_SUPABASE_URL, env.NEW_SEGMENTS_SUPABASE_KEY, {
	auth: { persistSession: false, autoRefreshToken: false }
});
