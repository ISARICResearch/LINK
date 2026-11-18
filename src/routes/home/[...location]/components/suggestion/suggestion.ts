/*

1. On load a forward segment, first find any and all exact matches with translations with a score of at least 2 (1 human). 

2. For each that you find, check for the one with the best translation (highest score) and push that.

3. If no exact matches found, find the top 5 most similar segments that have translations with minumum score of 2.

4. Show them in order of closesness of fit with 


... To show a translation:
it shouldn't be suggested if unreviewed AI.
it shouldn't be suggested if unreviewed Human.

Only suggest translation if it is YOUR unreviewed translation, you get special permission.
Or if translation is accepted with at least score of 2.

*/

import type { FindSimilarSegmentsResult } from '$lib/types';
import { supabase } from '../../../../../supabaseClient';

export async function getSuggestedTranslations(
	id: number,
	profileId: string,
	language: string
): Promise<FindSimilarSegmentsResult> {
	const result = await supabase.rpc('find_similar_segments', {
		p_segment_id: id,
		p_user_id: profileId,
		p_language: language,
		//min_accepted_score: 2,
		//batch_size: 10,
		//match_count: 3,
		match_threshold: 0.3,
		//max_batches: 10
	});
	if (result.error) console.warn(result.error)
	return result.data ?? [];
}
