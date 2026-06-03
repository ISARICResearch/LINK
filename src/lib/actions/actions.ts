import { repairLink } from '$lib/utils/repairTranslations';
import { exportToGit } from '../../routes/admin/controls/export/export';
import { getArcVersions } from '../../routes/admin/controls/getArcVersions';
import { AddArcVersionToLink } from '../../routes/admin/controls/githubToSupabaseNew';

// Runs once arc-translations:main gets an update (not from this)
export const bring_new_arc_version_into_link = async () => {
	const arcVersions = await getArcVersions();
	const newestVersion = Object.keys(arcVersions).reverse()[0];
	console.log("Pulling " + newestVersion + " into LINK");
	await AddArcVersionToLink(newestVersion);
    await repairLink(newestVersion);
    await exportToGit(newestVersion);
};

// Runs once every friday
export const export_link_results_to_arc = async () => {
    const arcVersions = await getArcVersions();
	const newestVersion = Object.keys(arcVersions).reverse()[0];
	console.log(newestVersion);
    console.log("Pushing " + newestVersion + " from LINK to ARC");
    await exportToGit(newestVersion);
};