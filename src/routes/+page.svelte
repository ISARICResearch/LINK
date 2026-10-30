<script lang="ts">
	import { button } from '$lib/styles';
	import { fetchAuthSession, signInWithRedirect, signOut } from 'aws-amplify/auth';
	import ThemeManager from './components/themeManager.svelte';
	import { goto } from '$app/navigation';
	import { supabase } from '../supabaseClient';

	const _buttonStyle =
		'w-full max-w-80 text-xl m-auto block text-center rounded-xl cursor-pointer mb-2 p-0.5 border-2 hover:bg-stone-50 border-stone-500 dark:hover:bg-stone-900 dark:hover:border-stone-300 hover:border-stone-600';
</script>

<div class="p-5">
	<div class="mx-auto w-full text-center mt-15">
		<div class="mx-auto w-full justify-center flex">
			<img alt="LINK icon" class="dark:invert-0 invert w-22 mt-1 opacity-80" src="/link.svg" />
			<h1 class="font-bold text-8xl">LINK</h1>
		</div>
		<h4 class="italic mb-15 mt-3 text-xl">Language Integration Network Kit</h4>
	</div>
	<div class=" rounded-lg w-full mt-10 max-w-2xl mx-auto">
		<div class="flex-wrap px-4">
			<p class="text-2xl font-semibold mb-4 text-center">
				Are you fluent in English and <br />Spanish, French, or Portuguese?
			</p>
			<p class="font-normal text-lg text-center">
				Help translate ISARIC's ARC database of CRF questions so that our Bridge is more accessible
				to researchers and clinicians around the world
			</p>
		</div>
	</div>
	<div class="w-full max-w-96 my-auto mx-auto">
		<div class="flex-wrap border-inherit p-4">
			<p class="font-bold text-stone-700 dark:text-stone-300 w-full text-center mt-15"></p>
			<!--
			<a
				data-sveltekit-preload-code="eager"
				class="w-full block max-w-80 m-auto text-3xl font-semibold rounded-xl border-3 cursor-pointer p-2 text-center {button
					.green.default} {button.green.hover}"
				href="/login"
			>
				Login
			</a>
			<p class="font-bold text-stone-700 dark:text-stone-300 w-full text-center mt-3"></p>
			<a
				data-sveltekit-preload-code="eager"
				class="{button.stoneHover} {buttonStyle} text-md"
				href="/register"
			>
				Create Account
			</a>-->

			<button
				onclick={async () => {
					'Clicked: signInWithRedirect()';
					const session = await fetchAuthSession();
					console.log(
						'session',
						session.tokens?.idToken?.payload.sub,
						session.tokens?.idToken?.payload
					);
					if (session.tokens?.idToken?.payload.sub) goto('/home');
					else await signInWithRedirect();
				}}
				class=" w-full block max-w-80 m-auto text-4xl font-semibold rounded-xl border-4 cursor-pointer p-5 text-center {button
					.green.default} {button.green.hover}">Sign In</button
			>

			<button
				onclick={async () => {
					const { data: profile, error } = await supabase.rpc('retrieve_profile');
					console.log('retrieve_profile BUTTON', profile, error);
				}}
				class=" w-full block max-w-40 m-auto text-xl font-semibold rounded-xl border-4 cursor-pointer p-2 text-center {button
					.green.default} {button.green.hover}"
			>
				retrieve_profile
			</button>
			<button
				onclick={async () => {
					const { data, error } = await supabase.rpc('test_auth');
					console.log('test_auth BUTTON', data, error);
				}}
				class=" w-full block max-w-40 m-auto text-xl font-semibold rounded-xl border-4 cursor-pointer p-2 text-center {button
					.green.default} {button.green.hover}"
			>
				test_auth
			</button>
			<button
				onclick={async () => {
					const { tokens } = await fetchAuthSession();
					console.log(tokens?.idToken?.payload);
				}}
				class=" w-full block max-w-40 m-auto text-xl font-semibold rounded-xl border-4 cursor-pointer p-2 text-center {button
					.green.default} {button.green.hover}"
			>
				tokens
			</button>
			<button
				onclick={() => signOut()}
				class=" w-full block max-w-40 m-auto text-xl font-semibold rounded-xl border-4 cursor-pointer p-2 text-center {button
					.green.default} {button.green.hover}"
			>
				sign out
			</button>

			<button
				onclick={async () => {
					console.log('server link_profile');
					const res = await fetch('api/link_profile', {
						method: 'POST'
					});

					console.log('res', res);
				}}
				class=" w-full block max-w-40 m-auto text-xl font-semibold rounded-xl border-4 cursor-pointer p-2 text-center {button
					.green.default} {button.green.hover}"
			>
				link_profile
			</button>
		</div>
	</div>

	<div class="w-full flex justify-center mt-15"><ThemeManager /></div>
</div>
