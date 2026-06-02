<script lang="ts">
	import { button } from '$lib/styles';
	import { fly } from 'svelte/transition';
	import { goto } from '$app/navigation';
	import { exportToZip, exportToGit } from './controls/export/export';
	import { AddArcVersionToLink } from './controls/githubToSupabaseNew';
	import { getArcVersions } from './controls/getArcVersions';
	import { repairLink } from '$lib/utils/repairTranslations';
	import { pullLink, type LinkTranslation } from '$lib/utils/pullLink';
	import type { Database } from '$lib/supabase/database.types';
	import { supabase } from '../../supabaseClient';
	import { update_link_from_arc } from '$lib/actions/update-link-from-arc';
	let arcVersions: Promise<Record<string, string[]>> = $state(getArcVersions());
	let selectedVersion = $derived(Object.keys(arcVersions)[0]);

	const printStatus = async (version: string) => {
		const link = await pullLink(version);
		const profilesRequest = await supabase.from('profiles').select('*');
		const users = profilesRequest.data;

		const userModified: LinkTranslation[] = [];
		const progressCounts: Record<Database['public']['Enums']['TranslationStep'], number> = {
			adjudication: 0,
			admin: 0,
			backward: 0,
			forward: 0,
			review: 0
		};

		const userMap: Record<string, { translations: LinkTranslation[]; reviews: LinkTranslation[] }> =
			{};

		// i itterate throughout the translations
		for (const language of Object.keys(link[1])) {
			const l = language as Database['public']['Enums']['Language'];
			for (const [_id, obj] of Object.entries(link[1][l])) {
				if (obj.forwardTranslations?.find((t) => t.user_id != null)) userModified.push(obj);
				if (obj.forwardTranslations) {
					for (const t of obj.forwardTranslations) {
						if (t.user_id == null) continue;
						if (!userMap[t.user_id]) userMap[t.user_id] = { translations: [], reviews: [] };
						userMap[t.user_id].translations.push(obj);
					}
				}
				if (obj.translationReviews) {
					for (const t of obj.translationReviews) {
						if (t.reviewer_id == null) continue;
						if (!userMap[t.reviewer_id]) userMap[t.reviewer_id] = { translations: [], reviews: [] };
						userMap[t.reviewer_id].reviews.push(obj);
					}
				}
				const step = obj.translationProgress?.translation_step;
				if (step) progressCounts[step] += 1;
			}
		}

		// Count how many in each transaltion step
		// Store translations made by humans
		// Store reviews
		console.log('userModified', userModified);
		console.log('progressCounts', progressCounts);
		console.log('users', users);
		console.log('userMap', userMap);
		if (!users) return;
		for (const id of Object.keys(users)) {
			console.log(users[+id].name, userMap[users[+id].id]);
		}
	};
</script>

{#await arcVersions}
	<p>Retrieving versions of arc...</p>
{:then versions}
	<div in:fly={{ y: 50, duration: 100, opacity: 0 }}>
		<label class="font-semibold text-lg">
			ARCH
			<select
				class={button.stanley + ' px-2 border-2 cursor-pointer rounded-md font-bold '}
				bind:value={selectedVersion}
			>
				{#each Object.keys(versions).reverse() as version}
					<option value={version}>{version}</option>
				{/each}
			</select></label
		>
		<div class="border mt-2 rounded-lg border-stone-400 dark:border-stone-700">
			<div class="sm:flex p-1.5 border-b border-inherit">
				<button
					title="Pull Lists from GitHub"
					class=" w-1/3 mt-1 min-w-60 h-8 border-3 hover:shadow mr-2 font-semibold rounded-lg cursor-pointer
						opacity-80 hover:opacity-100
				  		border-blue-700 hover:bg-blue-700/20
						dark:border-blue-600 dark:hover:bg-blue-600/20
						"
					onclick={async () => await update_link_from_arc()}
				>
					New Update LINK from ARC
				</button>
			</div>
			<div class="sm:flex p-1.5 border-b border-inherit">
				<button
					title="Pull Lists from GitHub"
					class=" w-1/3 mt-1 min-w-60 h-8 border-3 hover:shadow mr-2 font-semibold rounded-lg cursor-pointer
						opacity-80 hover:opacity-100
				  		border-blue-700 hover:bg-blue-700/20
						dark:border-blue-600 dark:hover:bg-blue-600/20
						"
					onclick={async () => {
						//if (selectedVersion) await UpdateFromARC(selectedVersion, versions[selectedVersion] as GithubLanguage[]);
						if (selectedVersion) await AddArcVersionToLink(selectedVersion);
						else console.error('no selected ARCH version');
					}}
				>
					Update LINK from ARC
				</button>
				<ol>
					<li>
						1. Connect to <em>ARC-Translations</em> GitHub Repo.
					</li>
					<li>2. Get most recent ARC version.</li>
					<li>
						3. Pull English version of <em>ARC.csv</em> and <em>Lists folder</em>.
					</li>
					<li>4. Add all new questions, answers, defintions, etc.</li>
					<li>5. Pull each other language.</li>
					<li>6. Add translations for new segemnts.</li>
				</ol>
			</div>

			<div class="sm:flex p-1.5 border-b border-inherit">
				<button
					title="Pull Lists from GitHub"
					class="w-1/3 mt-1 min-w-60 h-8 opacity-80 hover:opacity-100 border-3 hover:shadow mr-2 font-semibold rounded-lg cursor-pointer
						border-green-700 hover:bg-green-700/20
						dark:border-green-600 dark:hover:bg-green-600/20
					"
					onclick={async () => {
						const zipUrl = await exportToZip(selectedVersion);

						// Crazy gpt stuff -> creats an a and href then deletes it.
						if (zipUrl) {
							const a = document.createElement('a');
							a.href = zipUrl;
							a.download = `csv-export-${selectedVersion}.zip`;
							document.body.appendChild(a);
							a.click();
							document.body.removeChild(a);
						}
					}}
				>
					Export LINK to .zip
				</button>
				<button
					title="Push Test"
					class="w-1/3 mt-1 min-w-60 h-8 opacity-80 hover:opacity-100 border-3 hover:shadow mr-2 font-semibold rounded-lg cursor-pointer
						border-green-700 hover:bg-green-700/20
						dark:border-green-600 dark:hover:bg-green-600/20
					"
					onclick={async () => {
						await exportToGit(selectedVersion);
					}}
				>
					Export LINK to GitHub
				</button>
				<ol>
					<li>Exports LINK as a folder of CSVs</li>
				</ol>
			</div>

			<div class="sm:flex p-1.5">
				<button
					title="Pull Lists from GitHub"
					class="w-1/3 mt-1 min-w-60 h-8 border-3 hover:shadow mr-2 font-semibold rounded-lg cursor-pointer
					opacity-80 hover:opacity-100
						border-yellow-600 hover:bg-yellow-600/20
						dark:border-yellow-600 dark:hover:bg-yellow-600/20
					"
					onclick={async () => {
						await repairLink(selectedVersion);
					}}
				>
					Repair Link
				</button>
				<p>
					this runs a script to pull LINK, check that translation progress and accepted transaltions
					are 100% correct. Then if any aren't, fix them.
				</p>
			</div>
			<div class="sm:flex p-1.5">
				<button
					title="Pull Lists from GitHub"
					class="w-1/3 mt-1 min-w-60 h-8 border-3 hover:shadow mr-2 font-semibold rounded-lg cursor-pointer
					opacity-80 hover:opacity-100
						border-yellow-600 hover:bg-yellow-600/20
						dark:border-yellow-600 dark:hover:bg-yellow-600/20
					"
					onclick={async () => {
						await printStatus(selectedVersion);
					}}
				>
					Print Status
				</button>
				<p>
					this runs a script to pull LINK, check that translation progress and accepted transaltions
					are 100% correct. Then if any aren't, fix them.
				</p>
			</div>
			<div class="sm:flex p-1.5">
				<button
					title="Pull Lists from GitHub"
					class="w-1/3 mt-1 min-w-60 h-8 border-3 hover:shadow mr-2 font-semibold rounded-lg cursor-pointer
					opacity-80 hover:opacity-100
						border-yellow-600 hover:bg-yellow-600/20
						dark:border-yellow-600 dark:hover:bg-yellow-600/20
					"
					onclick={async () => {
						goto('/home');
					}}
				>
					User Home
				</button>
				<ol>
					<li>Go to user screen.</li>
					<li>All input will be done as a user</li>
				</ol>
			</div>
		</div>
	</div>
{/await}
