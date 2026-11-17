import { env } from '$env/dynamic/private';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

let client: SupabaseClient | undefined;

export const supabaseAdmin = () => {
	if (!client) {
		console.log('no client');
		const url = env.VITE_SUPABASE_URL;
		const key = env.SUPABASE_ADMIN_KEY;
		if (!url || !key) throw new Error('Supabase admin env vars are not set');
		client = createClient(url, key, {
			auth: { persistSession: false, autoRefreshToken: false }
		});
	}
	return client;
};
