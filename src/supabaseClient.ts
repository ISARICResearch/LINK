import '$lib/amplify'
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import type { Database } from './lib/supabase/database.types.js';
import { env } from '$lib/utils/utils.js';
import { fetchAuthSession } from 'aws-amplify/auth';

const supabaseUrl = env('VITE_SUPABASE_URL');
const supabaseAnonKey = env('VITE_SUPABASE_ANON_KEY');
const fetchCognito = {
	accessToken: async () => {
		const { tokens } = await fetchAuthSession();
		return tokens?.accessToken?.toString() ?? null;
	}
};

export let supabase = createClient<Database>(supabaseUrl, supabaseAnonKey, fetchCognito);

export const overrideClient = (client: SupabaseClient) => {
	supabase = client;
};
