import { defineEnvVars } from '@sveltejs/kit/env';

export const variables = defineEnvVars({
	NEW_SEGMENTS_SUPABASE_KEY: {},
	VITE_SUPABASE_URL: {},
	PUBLIC_USER_POOL_ID:{},
	PUBLIC_USER_POOL_CLIENT_ID:{},
	
});
