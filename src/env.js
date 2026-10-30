import { defineEnvVars } from '@sveltejs/kit/env';

export const variables = defineEnvVars({
	VITE_SUPABASE_URL: {},
	NEW_SEGMENTS_SUPABASE_KEY: {}
});
