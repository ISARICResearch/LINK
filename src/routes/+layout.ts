import '$lib/amplify';
import type { DocumentRow } from '$lib/supabase/types';
import { supabase } from '../supabaseClient';
import type { LayoutLoad } from './home/$types';

export const load: LayoutLoad = async () => {
	/*
	const session = (await supabase.auth.getSession()).data.session;
	if (!session) {
		return {
			session: null,
			profile: null,
			document: null
		};
	}
			const { data: profile } = await supabase
		.from('profiles')
		.select('*')
		.eq('id', 'session.user.id')
		.single();
	if (!profile) {
		await supabase.auth.signOut();
		return {
			session: session,
			profile: null,
			document: null
		};
	}*/

	console.log("Root Layout Loading...")
	const { data: profile, error } = await supabase.rpc('retrieve_profile');

	if (error) console.warn(error);

	if (profile) {
		const selectedDocument = profile?.selected_preset;
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
		} // * if I don't have one, get default document
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
	}

	return {
		profile,
		document
	};
};