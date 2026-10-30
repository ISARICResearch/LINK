import '$lib/amplify';
import type { DocumentRow } from '$lib/supabase/types';
import { fetchAuthSession } from 'aws-amplify/auth/server';
import { supabase } from '../supabaseClient';
import type { LayoutLoad } from './home/$types';
import type { Profile } from '$lib/types';

export const ssr = false;

const failed = { profile: null, document: null };

const attemptLinkProfile = async () => {
	console.log('server link-profile');
	const { tokens } = await fetchAuthSession();
	const idToken = tokens?.idToken?.toString();
	const accessToken = tokens?.accessToken?.toString();

	if (!idToken || !accessToken) throw new Error('not signed in');

	const res = await fetch('/api/link-profile', {
		method: 'POST',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify({ idToken, accessToken })
	});

	console.log('link-profile res', res);
	if (!res.ok) return null;

	const { data: profile, error } = await supabase.rpc('retrieve_profile');
	if (error) console.error(error);
	if (profile?.id) return profile;
	return null;
};

const getDocument = async (profile: Profile) => {
	const selectedDocument = profile.selected_preset;
	console.log('selectedDocument:', selectedDocument);
	let document: DocumentRow | null = null;

	// * get my document
	if (selectedDocument) {
		const myDocumentRow = await supabase
			.from('documents')
			.select('*')
			.eq('title', selectedDocument)
			.order('created_at', { ascending: false })
			.limit(1)
			.single();

		if (myDocumentRow) document = myDocumentRow.data;
	}
	// * if I don't have one, get default document
	else {
		console.log('no document yet');
		const defaultDocumentRow = await supabase
			.from('documents')
			.select('*')
			.eq('title', 'ARC')
			.order('created_at', { ascending: false })
			.limit(1)
			.single();

		if (defaultDocumentRow.data) document = defaultDocumentRow.data;
	}
	// * if still failed to get a document, get the first one it can find.
	if (document == null) {
		const defaultDocumentRow = await supabase.from('documents').select('*').limit(1).single();
		if (defaultDocumentRow.data) document = defaultDocumentRow.data;
	}

	return document;
};

export const load: LayoutLoad = async () => {
	console.log('Root Layout Loading...');

	// Check is signed in.
	const { tokens } = await fetchAuthSession();

	console.log('Root Tokens ', tokens);

	if (!tokens?.accessToken) return failed;

	const { data: profile, error } = await supabase.rpc('retrieve_profile');

	if (error) console.error(error);
	if (profile?.id) {
		console.log('LOGIN: Signing in with existing profile', profile);
		const document = await getDocument(profile);
		return {
			profile,
			document
		};
	}
	if (!profile?.id) {
		const linked_profile = await attemptLinkProfile();
		if (linked_profile?.id) {
			console.log('LOGIN: Signing in with newly linked profile', linked_profile);
			const document = await getDocument(linked_profile);
			return {
				profile: linked_profile,
				document
			};
		}
	}
	console.log('LOGIN: Signing in without existing profile');
	return failed;
};
