import { env } from '$env/dynamic/private';
import { VITE_SUPABASE_URL } from '$env/static/private';
import { createClient } from '@supabase/supabase-js';

export const supabaseAdmin = () => {
	if (!env.NEW_SEGMENTS_SUPABASE_KEY) return undefined;
	return createClient(VITE_SUPABASE_URL, env.NEW_SEGMENTS_SUPABASE_KEY, {
		auth: { persistSession: false, autoRefreshToken: false }
	});
};
