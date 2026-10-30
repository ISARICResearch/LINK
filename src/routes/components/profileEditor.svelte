<script lang="ts">
	import { button, form_element, shadow } from '$lib/styles';
	import type { Profile } from '$lib/types';
	import { onMount } from 'svelte';
	import { supabase } from '../../supabaseClient';
	import { capitalizeFirstLetter } from '$lib/utils/utils';
	import { fetchAuthSession } from 'aws-amplify/auth';
	import { invalidateAll } from '$app/navigation';

	let {
		profile
	}: {
		profile: Profile | null;
	} = $props();

	type ProfileSettings = {
		language: string | null;
		profession: string | null;
	};

	const editedProfile: ProfileSettings = $derived(
		profile != null
			? { language: profile.language, profession: profile.profession }
			: { language: null, profession: null }
	);
	let languages: string[] = $state([]);

	onMount(async () => {
		const { data, error } = await supabase.from('languages').select('id');
		console.log(data);
		if (error) console.error('Error pulling languages');
		languages = data ? data.map((r) => r.id) : [];
	});

	const labelStyle = 'grid items-center w-full font-bold text-stone-800 dark:text-stone-300 ';

	const updateProfile = async (event: Event) => {
		event.preventDefault();
		if (!event.isTrusted) return;
		if (!editedProfile.language || !editedProfile.profession) return;

		const { tokens } = await fetchAuthSession();
		const idToken = tokens?.idToken?.toString();
		const accessToken = tokens?.accessToken?.toString();

		if (!idToken || !accessToken) throw new Error('not signed in');

		const res = await fetch('/api/update-profile', {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({
				idToken,
				accessToken,
				language: editedProfile.language,
				profession: editedProfile.profession
			})
		});

		if (!res.ok) {
			const { error } = await res.json();
			console.error('Error updating profile:', error.message);
		}

		await invalidateAll();
	};
</script>

<div
	class="w-xs p-5 flex-col rounded-xl border border-stone-600 dark:border-stone-600 justify-center items-center flex mx-auto {shadow.color} shadow bg-stone-200 dark:bg-stone-900"
>
	<h1 class="text-lg mb-3 font-semibold">Profile Settings</h1>
	<form method="post" onsubmit={updateProfile} class="w-full px-5 flex flex-col justify-center">
		<label
			title="Please select which language you are a native speaker or have bilingual fluency"
			class="{labelStyle} mb-3"
		>
			Language
			<select
				class="{form_element} w-full cursor-pointer"
				bind:value={editedProfile.language}
				name="language"
				required
			>
				{#each languages as language}
					<option value={language}>{capitalizeFirstLetter(language)}</option>
				{/each}
				<option value="test">{capitalizeFirstLetter('test')}</option>
				<option value="spanish">{capitalizeFirstLetter('spanish')}</option>
			</select>
		</label>

		<label
			title="Please select your profession, if not offered simply select 'Other'"
			class="{labelStyle} mb-3"
		>
			Profession
			<select
				class="{form_element} w-full cursor-pointer"
				bind:value={editedProfile.profession}
				name="profession"
				required
			>
				<option value="clinical">Clinical Staff</option>
				<option value="researcher">Disease/Clinical Researcher</option>
				<option value="translator">Translator</option>
				<option value="survey">Survey/Questionnaire Expert</option>
				<option value="other">Other</option>
			</select>
		</label>
		<button
			type="submit"
			class="{button.green
				.default} cursor-pointer text-xl border-3 mx-auto px-5 font-semibold mt-2 rounded-xl {button
				.green.hover}">Save</button
		>
	</form>
</div>
