import type { Profile } from '$lib/types';

export type GlobalVariables = {
	language: string;
	document: string;
	profile: Profile | null;
};
export const globalVariables: GlobalVariables = $state({
	language: '',
	document: '',
	profile: null
});

export const setLanguage = (l: string) => {
	globalVariables.language = l;
};

export const setDocument = (d: string) => {
	globalVariables.document = d;
};

export const setProfile = (p: Profile) => {
	globalVariables.profile = p;
};
