<script lang="ts">
	import { button_A_active } from '$lib/styles';

	const footerTextStyle = ' text-stone-600 dark:text-stone-100 text-lg ';
	const footerHeaderStyle = ' italic text-md ';
	const aStyle =
		'font-semibold hover:underline not-italic active:opacity-60 hover:text-stone-700 dark:hover:text-stone-50';
	//const footerLinkStyle = ' hover:underline hover:text-stone-800 dark:hover:text-stone-200 ';
</script>

<footer class="w-full flex max-w-lg p-8 m-auto flex-col text-center {footerTextStyle} my-25">
	<p class="mb-5 text-md ">
		Have you encountered a bug, issue, or error? <br /><a
			title="Issue Report Form"
			target="_blank"
			class=" {button_A_active} {aStyle} w-full max-w-xs p-1 px-3 mb-5"
			href="https://ucdenver.co1.qualtrics.com/jfe/form/SV_8Bcvg9YcrkRHkt8"
		>
			🐛 Report it here.</a
		>
	</p>

	<div class="mb-15"></div>
	<span class={footerHeaderStyle}>Brought to you by</span>
	<div class="flex w-full m-auto max-w-lg">
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

	<p class="font-serif text-sm">
		CONTAGIO is funded by the European Union’s Horizon Europe programme under Grant Agreement N.
		101137283
	</p>

	<div class="h-5"></div>

	<div class="flex w-full m-auto max-w-2xs px-5">
		<a
			target="_blank"
			title="European Commission"
			class="cursor-pointer rounded-xl bg-white p-2 border hover:shadow-md mx-auto overflow-clip opacity-70 w-2/3 m-1 hover:opacity-100"
			href="https://commission.europa.eu/index_en"
			><img alt="European Commission" src="/logos/EuroComm_BW.png" /></a
		>
	</div>
	<a
		title="WHO"
		target="_blank"
		class="{button_A_active} {aStyle} mx-auto font-semibold px-10"
		href="https://www.who.int/">WHO</a
	>

	<span class="{footerHeaderStyle} mt-20">More</span>
	<div class="max-w-xs w-full mx-auto flex flex-col">
		<a
			target="_blank"
			title="User Guide"
			class="w-full {aStyle} {button_A_active}"
			href="https://github.com/aidanmarler/LINK/wiki/LINK-User-Guide">📘 User Guide</a
		>
		<a
			target="_blank"
			title="Source Code"
			class="w-full {aStyle} {button_A_active}"
			href="https://github.com/ISARICResearch/LINK">⚙️ Source Code</a
		>
		<a
			target="_blank"
			title="Source Code"
			class=" w-full {aStyle} {button_A_active}"
			href="https://github.com/ISARICResearch/LINK">✉️ Contact</a
		>
		<a
			target="_blank"
			title="Source Code"
			class="w-full {aStyle} {button_A_active}"
			href="https://github.com/ISARICResearch/LINK">🌐 Add a Language</a
		>
	</div>
</footer>
