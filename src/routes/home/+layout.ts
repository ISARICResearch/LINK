import { buildLocationTree, computeCompletion, type LocationNode } from '$lib/utils/locationTree';
//import { createSlugMapping } from '$lib/utils/slug';
import type { LayoutLoad } from './$types';
//import { redirect } from '@sveltejs/kit';

import type {
	DocumentRow,
	ForwardTranslationRow,
	SegmentMap,
	TranslationProgressRow,
	TranslationReviewRow
} from '$lib/supabase/types';
import { pullOriginalRowsById, pullRowsForOriginalId } from '$lib/supabase/utils';
import { supabase } from '../../supabaseClient';
import { redirect } from '@sveltejs/kit';
import { loading } from '../components/loading/loadingState.svelte';
import { setDocument, setLanguage } from './global.svelte';

export const ssr = false; // Force client-side for authentication

const timeStamps: number[] = [];

// & print time since last call + a message
const printTime = (message: string = '') => {
	timeStamps.push(performance.now());
	const A = timeStamps.at(-1);
	const B = timeStamps.at(-2);
	if (A && B) console.log(message + ' - ' + String(A - B));
	else if (message != '') console.log(message);
};

// == on load home page or children == //
export const load: LayoutLoad = async ({ parent, depends }) => {
	loading.message = 'Getting document...';
	loading.active = true;
	printTime();

	const { session, profile, document } = await parent();

	printTime('loaded session, profile, document');

	// ! catch not logged in
	if (!session || !profile) {
		console.warn(session, profile);
		if (!profile && session) await supabase.auth.signOut();
		redirect(302, '/login');
	}

	if (!profile.language) {
		console.warn('No language set');
		if (!profile && session) await supabase.auth.signOut();
		redirect(302, '/login');
	}

	depends('app:data');
	setLanguage(profile.language);
	setDocument(profile.selected_preset);

	loading.active = false;
	return {
		profile,
		document,
		dataPromise: loadDataProgressively(session.user.id, profile.language, document)
	};
};

async function loadDataProgressively(
	userId: string,
	language: string,
	document: DocumentRow | null
) {
	loading.message = 'Pulling segments...';
	loading.active = true;
	const segmentMap: SegmentMap = {};
	const original_ids = document ? document.original_ids : [];

	// = ( 1 ) = Promise.all data --  Paginated and broken up for the given segmentIds.
	const [
		original_segments,
		translation_progress,
		forward_translations,
		translation_reviews,
		document_rows
	] = await Promise.all([
		pullOriginalRowsById(original_ids),
		pullRowsForOriginalId<TranslationProgressRow>('translation_progress', original_ids, language),
		pullRowsForOriginalId<ForwardTranslationRow>(
			'forward_translations',
			original_ids,
			undefined,
			userId
		),
		pullRowsForOriginalId<TranslationReviewRow>(
			'translation_reviews',
			original_ids,
			undefined,
			userId
		),
		await supabase.from('documents').select('id, title, version')
	]);
	printTime('pulled all data');

	// = ( 2 ) = Create Segment map from original segments
	(original_segments || []).forEach((segment) => {
		// @ not really about presets, this just creates a map to put translation data with an original segment
		segmentMap[segment.id] = {
			originalSegment: segment,
			translationProgress: undefined as never,
			forwardTranslation: null,
			translationReview: null
		};
	});

	// = ( 3 ) = Build location tree and slug mapping
	const locationTree = buildLocationTree(original_segments || []);
	console.log('locationTree', locationTree);
	//const slugMapping = createSlugMapping(original_segments || []);
	//const locationList =

	// * Add progress to segmentMap
	(translation_progress || []).forEach((t) => {
		if (segmentMap[t.original_id]) {
			segmentMap[t.original_id].translationProgress = t;
		}
	});

	// * Add translations to segmentMap
	(forward_translations || []).forEach((ft) => {
		if (segmentMap[ft.original_id]) {
			segmentMap[ft.original_id].forwardTranslation = ft;
		}
	});

	// * Add reviews to the segmentMap
	(translation_reviews || []).forEach((review) => {
		if (segmentMap[review.original_id]) {
			segmentMap[review.original_id].translationReview = review;
		}
	});

	// = ( 4 ) = Compute completion for all nodes
	function computeNodeCompletions(node: LocationNode) {
		node.completion = computeCompletion(node, segmentMap);
		node.children.forEach((child) => computeNodeCompletions(child));
	}
	computeNodeCompletions(locationTree);

	// = ( 5 ) = Map documents by title
	let documents: { id: number; title: string; version: string }[] = [];
	if (document_rows.data) documents = document_rows.data;
	/*
	{
		for (const document of document_rows.data) {
			if (!documentMap[document.title]) documentMap[document.title] = [];
			documentMap[document.title].push(document);
		}
	}*/

	printTime('computed node completions');
	console.log('== complete ==');

	loading.active = false;
	return {
		segmentMap,
		locationTree,

		//slugMapping,
		documents
	};
}
