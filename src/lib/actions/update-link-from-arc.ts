import { getArcVersions } from '../../routes/admin/controls/getArcVersions';
import { AddArcVersionToLink } from '../../routes/admin/controls/githubToSupabaseNew';

export const update_link_from_arc = async () => {
	const arcVersions = await getArcVersions();
	const selectedVersion = Object.keys(arcVersions).reverse()[0];
	console.log(selectedVersion);
	await AddArcVersionToLink(selectedVersion);
};

update_link_from_arc();