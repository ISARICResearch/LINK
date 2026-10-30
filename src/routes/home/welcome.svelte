<script lang="ts">
	import { capitalizeFirstLetter } from '$lib/utils/utils';
	import { globalVariables } from './global.svelte';
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

		<p class="text-center text-xl p-6 font-serif">
			Welcome. <br />Thank you for your time and energy translating <b>ARC</b> into
			<b>{capitalizeFirstLetter(globalVariables.language)}</b>. <br />Your translations are helping
			people around the world!
		</p>
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
