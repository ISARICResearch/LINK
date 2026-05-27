<script lang="ts">
	import { button_A_active } from '$lib/styles';

	const footerTextStyle = ' text-stone-600 dark:text-stone-400 text-lg ';
	const footerHeaderStyle = ' italic text-sm ';
	//const footerLinkStyle = ' hover:underline hover:text-stone-800 dark:hover:text-stone-200 ';
</script>

<footer class="w-full flex max-w-lg m-auto flex-col text-center {footerTextStyle} my-25">
	<p class="mb-5 text-md inline-block">
		Have you encountered a bug, issue, or error? <br /><a
			title="Issue Report Form"
			target="_blank"
			class="hover:underline {button_A_active} not-italic p-1 px-3 font-semibold mb-5"
			href="https://ucdenver.co1.qualtrics.com/jfe/form/SV_8Bcvg9YcrkRHkt8"
		>
			Report it here.</a
		>
	</p>
	<span class={footerHeaderStyle}>Brought to you by</span>
	<div class="flex w-full m-auto max-w-md">
		<a
			target="_blank"
			title="CONTAGIO"
			class="cursor-pointer rounded-xl hover:shadow-md border mx-auto overflow-clip opacity-70 w-2/3 m-1 hover:opacity-100"
			href="https://www.contagio.network/"><img alt="CONTAGIO" src="/logos/CONTAGIO_Logo.jpg" /></a
		>
		<div class="w-4"></div>
		<a
			target="_blank"
			title="ISARIC"
			class=" cursor-pointer rounded-xl hover:shadow-md border mx-auto overflow-clip opacity-70 w-2/3 bg-white m-1 hover:opacity-100"
			href="https://isaric.org/"><img alt="ISARIC" src="/logos/ISARIC_logo.png" /></a
		>
	</div>

	<p class="font-serif text-md">
		CONTAGIO is funded by the European Union’s Horizon Europe programme under Grant Agreement N.
		101137283
	</p>

	<div class="h-5"></div>

	<span class={footerHeaderStyle}>Funders</span>
	<div class="flex w-full m-auto max-w-2xs px-5">
		<a
			target="_blank"
			title="European Commission"
			class="cursor-pointer rounded-xl bg-white p-2 border hover:shadow-md mx-auto overflow-clip opacity-70 w-2/3 m-1 hover:opacity-100"
			href="https://commission.europa.eu/index_en"
			><img alt="European Commission" src="/logos/EuroComm_BW.png" /></a
		>
	</div>
	<a title="WHO" target="_blank" class="{button_A_active} mx-auto px-10" href="https://www.who.int/"
		>WHO</a
	>

	<div class="h-5"></div>

	<span class={footerHeaderStyle}>Source Code</span>
	<a
		target="_blank"
		title="Github"
		class="mx-auto px-10 {button_A_active}"
		href="https://github.com/ISARICResearch/LINK">GitHub</a
	>
	<a
		target="_blank"
		title="Github"
		class="mx-auto px-10 {button_A_active}"
		href="https://github.com/aidanmarler/LINK/wiki/LINK-User-Guide">User Guide</a
	>
</footer>
