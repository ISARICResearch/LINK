import '$lib/amplify';
import { buildLocationTree, computeCompletion, type LocationNode } from '$lib/utils/locationTree';
import type { LayoutLoad } from './$types';
import type {
	DocumentRow,
	ForwardTranslationRow,
	SegmentMap,
	TranslationProgressRow,
	TranslationReviewRow
} from '$lib/supabase/types';
import { pullOriginalRowsById, pullRowsForOriginalId } from '$lib/supabase/utils';
import { supabase } from '../../supabaseClient';
import { loading } from '../components/loading/loadingState.svelte';
import { setDocument, setLanguage } from './global.svelte';
import { getCurrentUser } from 'aws-amplify/auth';

export const ssr = false;

// == on load home page or children == //
export const load: LayoutLoad = async ({ parent, depends }) => {
	loading.message = 'Getting document...';
	loading.active = true;

	console.time('/home/ check user');
	console.log('home, Check user is signed in...');
	const { username, userId, signInDetails } = await getCurrentUser();
	console.log('home, Check user is signed in RESULT:', username, userId, signInDetails);

	console.time('/home/ handle profile');
	const { profile, document } = await parent();
	console.timeEnd('/home/ handle profile');

	loading.active = false;

	depends('app:data');

	if (!profile) return { profile: null, document: null, dataPromise: null };
	if (!profile.language ) return { profile, document: null, dataPromise: null };

	setLanguage(profile.language);
	setDocument(profile.selected_preset);

	return {
		profile,
		document,
		dataPromise: loadDataProgressively(profile.id, profile.language, document)
	};
};

async function loadDataProgressively(
	userId: string,
	language: string,
	document: DocumentRow | null
) {
	console.time('/home/ pulling data');
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
	console.time('/home/ pulling data');
	console.time('/home/ computing data');

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
	console.time('/home/ computing data');
	console.log('/home/ == complete ==');

	loading.active = false;
	return {
		segmentMap,
		locationTree,
		documents
	};
}
