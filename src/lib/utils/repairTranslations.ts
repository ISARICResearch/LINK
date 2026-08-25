/*
Done with get link

== check progess exists for each language and og_segment ==
== check existing progress is correct for each language and og_segment == (If they are in review, do they have at least 1 human reviewer in forward translations)
--> modify progress with what you find.

== check accepted_translation exists for each language and og_segment ==
== check existing accepted_t reffered to f_translation exists, 
    and then that it really is the best one, 
    and that the review count matches. ==
--> modify a_translations with what you find.

*/

import type { Database } from '$lib/supabase/database.types';
import { getAcceptedTranslation } from '$lib/supabase/translationProgress';
import type {
	AcceptedTranslationInsert,
	AcceptedTranslationRow,
	TranslationProgressInsert,
	TranslationProgressRow
} from '$lib/supabase/types';
import { getLatestEvent } from '$lib/supabase/utils';
import { supabase } from '../../supabaseClient';
import { pullLink } from './pullLink';

export async function repairLink(version: string) {
	const startT = performance.now();
	const link = await pullLink(version);
	const linkTranslations = link[1];
	const progressUpsert: (TranslationProgressInsert | TranslationProgressRow)[] = [];
	const acceptedUpsert: (AcceptedTranslationInsert | AcceptedTranslationRow)[] = [];

	// i itterate throughout the translations
	for (const language of Object.keys(linkTranslations)) {
		const l = language as Database['public']['Enums']['Language'];
		for (const [id, obj] of Object.entries(linkTranslations[language])) {
			// + get obj's translation_step
			const objStep = obj.translationProgress?.translation_step;
			if (objStep == 'admin' || objStep == 'adjudication') continue;
			// + calculate obj's translation_step from info provided
			let calculatedStep: Database['public']['Enums']['TranslationStep'] = 'forward';
			if (obj.forwardTranslations?.find((t) => t.user_id != null)) calculatedStep = 'review';

			// * create a new progress if missing
			const noProgress = obj.translationProgress == undefined;
			if (noProgress)
				progressUpsert.push({
					language: l,
					original_id: +id,
					translation_step: calculatedStep
				});

			// * update progress if in wrong step
			if (obj.translationProgress) {
				const rightSteps: Database['public']['Enums']['TranslationStep'][] = [
					'adjudication',
					'admin',
					'backward',
					calculatedStep
				];
				const rightStep = rightSteps.includes(obj.translationProgress.translation_step);
				if (rightStep) {
					calculatedStep = obj.translationProgress.translation_step;
				} else {
					const row = obj.translationProgress;
					row.translation_step = calculatedStep;
					console.log('progressUpsert', row);
					progressUpsert.push(row);
				}
			}

			// * create a new acceptedInsert if missing
			// Re-calculate Accepted Translation
			const at = getLatestEvent(obj.acceptedTranslations ?? []);
			const ft = obj.forwardTranslations ?? [];
			const tr = obj.translationReviews ?? [];
			const reClacAT = getAcceptedTranslation(at, ft, tr, calculatedStep);
			// ! Only update or insiert Accepted Translaitons if we could calculate one
			if (reClacAT) {
				const badId = reClacAT.translation_id != at?.translation_id;
				const badScore = reClacAT.score != at?.score;
				if (!at || badId || badScore) acceptedUpsert.push(reClacAT);
			} else
				console.log("reClac null, couldn't find best translation.", {
					original: link[0][+id],
					translation: obj
				});
		}
	}

	if (progressUpsert.length > 0) {
		console.log('progressUpsert', progressUpsert);
		const { error: progressError } = await supabase
			.from('translation_progress')
			.upsert(progressUpsert, { onConflict: 'id' });
		if (progressError) console.error('Error upserting translation progresses', progressError);
	}

	if (acceptedUpsert.length > 0) {
		console.log('acceptedUpsert', acceptedUpsert);
		const inserts = acceptedUpsert.filter((r): r is AcceptedTranslationInsert => r.id === undefined);
		const updates = acceptedUpsert.filter((r): r is AcceptedTranslationRow => r.id !== undefined);

		if (inserts.length > 0) {
			const { error } = await supabase.from('accepted_translations').insert(inserts);
			if (error) return error;
		}

		if (updates.length > 0) {
			const { error } = await supabase
				.from('accepted_translations')
				.upsert(updates, { onConflict: 'id' });
			if (error) return error;
		}
		/*  - old code -

		const { error: acceptedError } = await supabase
			.from('accepted_translations')
			.upsert(acceptedUpsert as AcceptedTranslationInsert[], { onConflict: 'id' });
		if (acceptedError) console.error('Error upserting accepted translations', acceptedError); // line 102
		*/
	}

	const endT = performance.now();
	console.log('Done! in ' + String((endT - startT) / 1000) + 's');
}
