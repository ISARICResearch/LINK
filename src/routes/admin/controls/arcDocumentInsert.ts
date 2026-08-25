import type { DocumentInsert, OriginalSegmentRow } from '$lib/supabase/types';
import _ from 'lodash';
import { supabase } from '../../../supabaseClient';
import { GetArcPresets } from './findArcPresets';
import type { ArcStructure } from './export/pullArcTranslations';
//import { ListsEnglishToInsert } from './arcSegmentInsert';

async function PullAllDocumentData() {
	console.log('Pull Documnets...');
	const documents = await supabase.from('documents').select('*');
	if (documents.error) console.error('Insert error:', documents.error);

	return documents.data;
}

export async function HandleDocumentInsert(
	version: string,
	segments: OriginalSegmentRow[],
	_arc: ArcStructure
) {
	// = (1) = Pull existing documents
	const existingDocuments = await PullAllDocumentData();
	if (!existingDocuments) return;

	// = (2) = Get documents to insert
	//const filteredSegments: OriginalSegmentRow[] = GetSegmentsInArc(segments, arc);
	//console.log('segments', segments);
	//console.log('filteredSegments', filteredSegments);
	const documentsMaybeInsert = await CreateDocumentInserts(version, segments);
	if (!documentsMaybeInsert) return;

	const documentsToUpdate: DocumentInsert[] = [];
	const documentsToInsert: DocumentInsert[] = [];

	// = (3) = Handle if document exists, update it, otherwise insert it as new
	for (const insert of documentsMaybeInsert) {
		// + store if document insert already exists
		const existingDoc = existingDocuments.find(
			(d) => d.title == insert.title && d.version == insert.version
		);
		// # if this title and version is not in arc, add it.
		if (!existingDoc) {
			documentsToInsert.push(insert);
			continue;
		}
		// # otherwise, let's update the existing document with a union of original ids
		const existingIds = new Set(existingDoc.original_ids);
		const newIds = new Set(insert.original_ids);

		//const allIds = new Set([...existingIds, ...newIds]); // @ removed, ids may have been removed, just use the ones found.
		if (existingIds == newIds) continue; // ! skip if no change upon adding newIds
		const idArray = Array.from(newIds);

		// existing document, just with a new set of original_ids
		const update: DocumentInsert = { ...existingDoc, original_ids: idArray };
		documentsToUpdate.push(update);
	}

	// == Upsert all documents to upsert == //
	if (documentsToUpdate.length > 0) {
		console.log('documentsToUpdate', documentsToUpdate);
		const update = await supabase.from('documents').upsert(documentsToUpdate, { onConflict: 'id' });
		//.select('*');
		if (update.error) console.error('Update error:', update.error);
	}
	if (documentsToInsert.length > 0) {
		console.log('documentsToInsert', documentsToInsert);
		const insert = await supabase.from('documents').insert(documentsToInsert);
		//.select('*');
		if (insert.error) console.error('Insert error:', insert.error);
	}
}

// @ AIDAN LOOK HERE
async function CreateDocumentInserts(version: string, segments: OriginalSegmentRow[]) {
	if (segments.length == 0) return;

	// = (1) = Get arc presets to assign to documents
	const [arcPresetMap, listsPresetMap] = await GetArcPresets(version);
	console.log('arcPresetMap', arcPresetMap);
	console.log('listsPresetMap', listsPresetMap);

	/*
	get arc -> arch -> variable names as Set()
	When it adds any one variable to  the document, first check if it is in my set of arc variables. If not, skip.
	*/

	// if variable_id == [], add simply to "ARC"
	// if variable_id == [preset_name], add to document titled "preset_name"
	// if variable_id == [all], add to all documents // @ do not think this exists

	// = (2) initialize DocumentInserts
	const documentInserts: DocumentInsert[] = [];

	const documentMap: Record<string, Set<number>> = {
		ARC: new Set()
	};

	// = (3) = add Arc variables to document
	for (const [variable, presets] of Object.entries(arcPresetMap)) {
		// Get variable(s)
		for (const s of segments) {
			// ! if not a variable type, skip
			if (!(s.type == 'question' || s.type == 'definition' || s.type == 'completionGuide'))
				continue;

			// ! if not my variable, forget it.
			if (s.location?.at(-1) != variable) continue;

			// == if this is my variable, add the variable and relavent Form, Section, and Answer Options == //

			// + initialize varible set of related ids
			const variableSet = new Set<number>();

			// + add form and sectio labels
			const loc = s.location;
			if (loc) {
				const formLab = segments.find((seg) => seg.type == 'formLabel' && seg.segment == loc[1]);
				if (formLab) variableSet.add(formLab.id);
				const secLabel = segments.find(
					(seg) => seg.type == 'sectionLabel' && seg.segment == loc[2]
				);
				if (secLabel) variableSet.add(secLabel.id);
			}

			// + add variable id
			variableSet.add(s.id);

			// + add answer option ids, if necessary
			const ao_array = s.answer_options;
			if (ao_array !== null && ao_array.length > 0) {
				for (const ao of ao_array) {
					const ao_s = segments.find((seg) => seg.type == 'answerOption' && seg.segment == ao);
					if (ao_s) variableSet.add(ao_s.id);
				}
			}

			// == Finally, add variable's set to document and presets == //
			documentMap['ARC'] = new Set([...documentMap['ARC'], ...variableSet]);
			for (const preset of presets) {
				if (!documentMap[preset]) documentMap[preset] = new Set();
				documentMap[preset] = new Set([...documentMap[preset], ...variableSet]);
			}
		}
	}

	// = (4) = add List items to document
	for (const [_list, sublists] of Object.entries(listsPresetMap)) {
		for (const [_subList, items] of Object.entries(sublists)) {
			for (const [_item, _presets] of Object.entries(items)) {
				const loc = ['Lists', _list.trim(), _subList.trim(), _item.trim()];
				const listItem = segments.find((seg) => {
					if (seg.type != 'listItem') return false;
					if (!seg.location) return false;
					return _.isEqual(seg.location, loc);
				});
				if (!listItem) continue;
				documentMap['ARC'].add(listItem.id);
				for (const preset of _presets) {
					if (!documentMap[preset]) continue;
					//if (!documentMap[preset]) documentMap[preset] = new Set();
					documentMap[preset].add(listItem.id);
				}
			}
		}
	}

	console.log('documentMap', documentMap);

	for (const [title, ids] of Object.entries(documentMap)) {
		documentInserts.push({ title: title, version: version, original_ids: Array.from(ids) });
	}

	//console.log('documentInserts', documentInserts);

	if (documentInserts.length == 0) return null;

	return documentInserts;
}

/*
const GetSegmentsInArc = (
	segments: OriginalSegmentRow[],
	arc: ArcStructure
): OriginalSegmentRow[] => {
	return [];
	const getArcSegments = (): OriginalSegmentRow[] => {
		const arcVariables = arc['ARCH.csv'];
		if (!arcVariables) return [];
		const _variableNames = Object.keys(arcVariables);

		return segments.filter((_s) => {
			/*
			if ([question].includes(s.type)) const v = s.location?.at(-1);
			if (!v) return false;
			if (variableNames.includes(v)) if (s) return true;
			if (v.includes(' ')) return true;*/
			// @ AIDAN COME BACK - this makes all labels always add, so long as they were in the document. But maybe we don't want that?
			/*return false;
		});
	};

	const archSegments = getArcSegments();

	const getListSegments = (): OriginalSegmentRow[] => {
		const lists = arc.Lists;
		if (!lists) return [];
		const inserts = ListsEnglishToInsert(lists);

		return segments.filter((s) => {
			const sLoc = s.location;
			if (!sLoc) return false;
			for (const insert of inserts) {
				const iloc = insert.location;
				if (!iloc) return false;
				if (_.isEqual(iloc, sLoc)) return true;
			}
			// @ AIDAN COME BACK - this makes all labels always add, so long as they were in the document. But maybe we don't want that?
			return false;
		});
	};

	const listSegments = getListSegments();

	const allSegments = [...archSegments, ...listSegments];
	return allSegments;
};*/
