<script lang="ts">
	import { capitalizeFirstLetter } from '$lib/utils/utils';

	let {
		profile
	}: {
		profile: {
			clinical_expertise: boolean | null;
			created_at: string;
			id: string;
			is_admin: boolean;
			language: string | null;
			name: string | null;
			profession: string | null;
			selected_preset: string | null;
		};
	} = $props();


	let weekOut = new Date().toJSON().slice(0, 8) + (+new Date().toJSON().slice(8, 10) + 7).toString(); 
	let firstSteps = $derived(profile.created_at.slice(0, 10) < weekOut);
	$inspect(
		profile.created_at.slice(0, 10),
		weekOut,
		firstSteps,
		"2026-06-01" < "2026-06-2"
	);

	let instructionsOpen = $derived(firstSteps.valueOf());

	const language = $derived(capitalizeFirstLetter(profile.language ? profile.language : ''));
</script>

<div class="w-full text-stone-800 dark:text-stone-300">
	<div class=" p-0 m-auto text-lg font-normal">
		<h1 class="italic text-3xl p-0 font-medium w-full mb-4 text-center">
			<span class=""
				><span class="font-bold">L</span>anguage
				<span class="font-bold">I</span>ntegration
				<span class="font-bold">N</span>etwork
				<span class="font-bold">K</span>it</span
			>
		</h1>

		<p class="text-center text-xl it p-6 font-serif">
			Welcome, {profile.name}. <br />Thank you for your time and energy translating <b>ARC</b> into <b>{language}</b>. <br />Your
			translations are helping people around the world!
		</p>

		<fieldset
			class=" border {instructionsOpen
				? 'shadow-md border-stone-700'
				: 'border-stone-400'} rounded-lg mb-4"
		>
			<legend class="ml-3 px-1"
				><button
					onclick={() => (instructionsOpen = !instructionsOpen)}
					class="font-bold flex hover:bg-stone-100 hover:shadow-xs translate-y-0 hover:underline object-center text-2xl pr-2 px-1 rounded-lg cursor-pointer"
					><svg
						class="{instructionsOpen
							? 'rotate-90'
							: ''} stroke-stone-900 dark:stroke-stone-200 duration-200 transition-transform h-8 w-8 p-1"
						xmlns="http://www.w3.org/2000/svg"
						width="24"
						height="24"
						viewBox="0 0 24 24"
					>
						<path
							fill="none"
							stroke-linecap="round"
							stroke-linejoin="round"
							stroke-width="3"
							d="m9 5l6 7l-6 7"
						/>
					</svg>
					Instructions
				</button></legend
			>
			<div
				class="{instructionsOpen
					? 'max-h-210 '
					: 'max-h-0 '} transition-all overflow-scroll duration-400"
			>
				{#if instructionsOpen}
					<div class="">
						<div class="w-full flex justify-center">
							<h3 class="font-serif text-center mt-4 border-stone-400 border-y-2 px-2 text-2xl">
								Getting Started
							</h3>
						</div>
						<div class=" text-xl border-b-2 border-dashed border-inherit pb-4 px-4">
							<ol class="p-2">
								<li class="mb-1">
									<span class="font-bold">Choose a CRF to translate</span> by clicking "CRF to Translate"
									and then selecting the CRF you would like to work on.
								</li>
								<li>
									<span class="font-bold">Find a segment</span> by either using "Go to Next Segment" or
									navigating manually from either "ARC Questions" or "Listed Options"
								</li>
							</ol>
						</div>
						<div class="w-full flex justify-center">
							<h3 class="font-serif text-center mt-4 border-stone-400 border-y-2 px-2 text-2xl">
								Translating a Segment
							</h3>
						</div>

						<div class=" text-xl border-dashed border-inherit pb-2 px-4">
							<!--	<p class="">Each segment (a word or pharse) will be translated using two steps:</p>-->

							<ol class="p-2">
								<li class="mb-1">
									<span class="font-bold">Step 1: Translation -></span> Write out the provided
									English segment in {language}.
								</li>
								<li>
									<span class="font-bold">Step 2: Review -></span> Select the correct translation.
									<br /><em class="ml-2 text-lg">
										* If none of the provided translations are correct, write a new one.</em
									>
								</li>
							</ol>
						</div>
						<div class="p-6 pt-0 border-b-0 border-dashed border-inherit">
							<p class="text-xl text-center">
								The translation with most votes will be added to ARC and used around the world!
							</p>
						</div>
						<div class="border-b-2 border-dashed border-inherit p-4">
							<p class="italic text-center font-medium font-serif">More actions...</p>

							<p class="px-2 py-1">
								<span class="font-bold bg-stone-300 rounded-lg px-2 p-0.5"
									>Skip<svg
										class="w-5 h-5 inline mb-0.5 ml-0.5"
										xmlns="http://www.w3.org/2000/svg"
										width="24"
										height="24"
										viewBox="0 0 28 28"
									>
										<path
											fill="currentColor"
											d="M15.637 4.857c-1.066-.845-2.635-.086-2.635 1.273v4.57L5.636 4.858c-1.065-.845-2.634-.086-2.634 1.273V21.87c0 1.359 1.57 2.118 2.634 1.273l7.366-5.84v4.565c0 1.359 1.57 2.118 2.634 1.273l9.637-7.64a1.917 1.917 0 0 0 0-3.004z"
										/>
									</svg></span
								>
								for when you do not know how to best translate something.
							</p>
							<p class="px-2 pb-2">
								<span class="font-bold bg-stone-300 rounded-lg px-2 p-0.5"
									>Leave a comment<svg
										xmlns="http://www.w3.org/2000/svg"
										width="24"
										class="inline mb-0.5 ml-0.5"
										height="24"
										viewBox="0 0 24 24"
									>
										<path
											fill="currentColor"
											class=" h-5 stroke-2 w-5 inline"
											d="M5 8a1 1 0 0 0 2 0V7h1a1 1 0 0 0 0-2H7V4a1 1 0 0 0-2 0v1H4a1 1 0 0 0 0 2h1Zm13-3h-6a1 1 0 0 0 0 2h6a1 1 0 0 1 1 1v9.72l-1.57-1.45a1 1 0 0 0-.68-.27H8a1 1 0 0 1-1-1v-3a1 1 0 0 0-2 0v3a3 3 0 0 0 3 3h8.36l3 2.73A1 1 0 0 0 20 21a1.1 1.1 0 0 0 .4-.08A1 1 0 0 0 21 20V8a3 3 0 0 0-3-3"
										/>
									</svg></span
								> for when you have something to say about a translation, review, or the segment. These
								will be visible for all other reviewers.
							</p>
							<p class="p-2 pl-2 italic text-base">
								* you may leave comments even if you skip a translation.<br />
								** when reviewing you can leave as many comments as you like.
							</p>
						</div>

						<div class="w-full flex justify-center">
							<h3 class="font-serif text-center mt-4 border-stone-400 border-y-2 px-2 text-2xl">
								Additional Resources
							</h3>
						</div>
						<div class="pt-2 pb-2 px-6 text-xl">
							<a
								href="https://github.com/aidanmarler/LINK/wiki/LINK-User-Guide"
								target="_blank"
								title="User Guide"
								class=" bg-stone-100 font-medium p-0.5 px-2 rounded-lg shadow-xs hover:bg-stone-50 hover:shadow-md cursor-pointer hover:underline"
							>
								📘 User Guide
							</a>
							Full instructions on how to use LINK are written here.
						</div>
						<div class="pb-2 px-6 text-xl">
							<a
								target="_blank"
								href="https://ucdenver.co1.qualtrics.com/jfe/form/SV_8Bcvg9YcrkRHkt8"
								title="Video Tutorial"
								class=" bg-stone-100 font-medium p-0.5 px-2 rounded-lg shadow-xs hover:bg-stone-50 hover:shadow-md cursor-pointer hover:underline"
							>
								📺 Video Tutorial</a
							> A video explaining how to use LINK.
						</div>
						<div class="pb-4 px-6 text-xl">
							<a
								target="_blank"
								href="https://ucdenver.co1.qualtrics.com/jfe/form/SV_8Bcvg9YcrkRHkt8"
								title="Issue Report Form"
								class=" bg-stone-100 font-medium p-0.5 px-2 rounded-lg shadow-xs hover:bg-stone-50 hover:shadow-md cursor-pointer hover:underline"
							>
								⚠️ Issue Report Form</a
							> Please report any bugs or issues encountered here.
						</div>
					</div>
				{/if}
			</div>
		</fieldset>
	</div>
</div>

<!--
					<p>High-quality translations require three steps:</p>
					<ol class="p-3">
						<li>
							1. <span class="font-bold"> Forward Translation:</span> translate phrases from English
							into {capitalizeFirstLetter(profile.language ? profile.language : '')}.
						</li>
						<li>
							2. <span class="font-bold"> Review:</span> select the correct translation, or write a new
							one with a justification.
						</li>
						<li>
							3. <span class="font-bold"> Backward Translation:</span> translating reviewed translations
							back into English.
						</li>
					</ol>
					-->
