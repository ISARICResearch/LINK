import '$lib/amplify';
import { fetchAuthSession } from 'aws-amplify/auth/server';
import { TimeoutError, withTimeout } from '$lib/utils/utils';
import { refreshAll } from '$app/navigation';
import { supabase } from '../../supabaseClient';
import type { LayoutLoad } from '../$types';
import { error } from '@sveltejs/kit';

export const ssr = false;

export const load: LayoutLoad = async () => {
	try {
		const res = await withTimeout(fetchAuthSession(), 3000);
		if (!res.tokens) error(404, 'Not found');
	} catch (e) {
		if (e instanceof TimeoutError) refreshAll();
		error(404, 'Not found');
	}

	const { data: profile, error: e } = await supabase.rpc('retrieve_profile');
	if (e) error(404, 'Not found');
	if (!profile?.is_admin) error(404, 'Not found');
};
