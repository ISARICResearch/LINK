export type GloabalVariables = {
	language: string;
	document: string;
};
export const globalVariables: GloabalVariables = $state({ language: 'spanish', document: '' });

export const setLanguage = (l: string) => {
	globalVariables.language = l;
};

export const setDocument = (d: string) => {
	globalVariables.document = d;
};
