import { createClient } from '@supabase/supabase-js';
import type { Database } from './lib/supabase/database.types.js';
import { env } from '$lib/utils/utils.js';

const supabaseUrl = env('VITE_SUPABASE_URL');
const supabaseAnonKey = env('VITE_SUPABASE_ANON_KEY');

export const supabase = createClient<Database>(supabaseUrl, supabaseAnonKey);
