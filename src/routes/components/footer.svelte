<script lang="ts">
	import { button_A_active, shadow } from '$lib/styles';

	const footerTextStyle = ' text-stone-600 dark:text-stone-100 text-lg ';
	const footerHeaderStyle = ' italic text-md ';
	const aStyle =
		'font-semibold hover:underline not-italic active:opacity-60 hover:text-stone-700 dark:hover:text-stone-50';
	const bStyle = 'hover:underline active:opacity-60 hover:text-stone-700 dark:hover:text-stone-50';
	//const footerLinkStyle = ' hover:underline hover:text-stone-800 dark:hover:text-stone-200 ';
</script>

<footer class="w-full flex p-8 m-auto flex-col text-center {footerTextStyle} my-20">
	<!--
	<svg
		class="rotate-90 opacity-50 m-auto w-8 h-8"
		xmlns="http://www.w3.org/2000/svg"
		width="1em"
		height="1em"
		viewBox="0 0 24 24"
	>
		<path d="M0 0h24v24H0z" fill="none" />
		<path
			fill="currentColor"
			d="M11.05 12L7.175 6.575q-.35-.5-.087-1.037T7.975 5q.25 0 .475.113t.35.312L13.5 12l-4.7 6.575q-.125.2-.35.313T7.975 19q-.6 0-.875-.537t.075-1.038zM17 12l-3.875-5.425q-.35-.5-.088-1.037T13.926 5q.25 0 .475.113t.35.312L19.45 12l-4.7 6.575q-.125.2-.35.313t-.475.112q-.6 0-.875-.537t.075-1.038z"
		/
	</svg>-->
	<hr class=" mb-10 opacity-10 border-3 bg-stone-600 rounded-full max-w-30 mx-auto w-full" />

	<span class="{footerHeaderStyle} mt-20">About Us</span>
	<div class="flex w-full mx-auto max-w-lg">
		<a
			target="_blank"
			title="CONTAGIO"
			class="cursor-pointer text-center rounded-xl overflow-clip hover:underline font-medium hover:bg-white opacity-50 hover:opacity-100 {shadow.color} hover:shadow-md"
			href="https://www.contagio.network/"><img alt="CONTAGIO" src="/logos/CONTAGIO_Logo.jpg" /></a
		>
		<div class="w-6"></div>
		<a
			target="_blank"
			title="ISARIC"
			class="cursor-pointer text-center rounded-xl w-full bg-white overflow-clip hover:underline font-medium hover:bg-white opacity-50 hover:opacity-100 {shadow.color} hover:shadow-md"
			href="https://isaric.org/"><img alt="ISARIC" src="/logos/ISARIC_logo.png" /></a
		>
	</div>
	<div class="flex w-full justify-around mx-auto mt-2 px-4 mb-4 max-w-lg">
		<a
			target="_blank"
			title="ARC"
			class="cursor-pointer text-center text-sm rounded-lg {bStyle} {button_A_active} font-medium hover:bg-white opacity-50 w-full hover:opacity-100 {shadow.color} hover:shadow"
			href="https://arc.docs.isaric.org/">💾 ARC</a
		>
		<a
			target="_blank"
			title="BRIDGE"
			class="cursor-pointer text-center text-sm rounded-lg {bStyle} {button_A_active} font-medium hover:bg-white opacity-50 w-full hover:opacity-100 {shadow.color} hover:shadow"
			href="https://bridge.isaric.org/">📋 BRIDGE</a
		>
		<a
			target="_blank"
			title="VERTEX"
			class="cursor-pointer text-center text-sm rounded-lg {bStyle} {button_A_active} font-medium hover:bg-white opacity-50 w-full hover:opacity-100 {shadow.color} hover:shadow"
			href="https://vertex.isaric.org/">📊 VERTEX</a
		>
		<a
			target="_blank"
			title="ACCOUNTS"
			class="cursor-pointer text-center text-sm rounded-lg {bStyle} {button_A_active} font-medium hover:bg-white opacity-50 w-full hover:opacity-100 {shadow.color} hover:shadow"
			href="https://account.isaric.org/">👤 ACCOUNTS</a
		>
	</div>
	<div class=" max-w-md mx-auto flex">
		<div class="w-full flex">
			<a
				target="_blank"
				title="European Commission"
				class="cursor-pointer text-center rounded-lg p-1 {bStyle} {button_A_active} font-medium hover:bg-white opacity-50 hover:opacity-100 {shadow.color} hover:shadow"
				href="https://commission.europa.eu/index_en"
			>
				<img alt="European Commission" class="w-40" src="/logos/EuroComm_BW.png" />
			</a>
			<div class="flex justify-around items-center">
				<a
					target="_blank"
					href="https://cordis.europa.eu/project/id/101137283"
					title="CONTAGIO EC Project"
					class="ml-2 flex font-serif {bStyle} {button_A_active} cursor-pointer text-sm rounded-lg hover:underline hover:bg-white opacity-50 w-full hover:opacity-100 {shadow.color} hover:shadow"
				>
					CONTAGIO is funded by the European Union’s Horizon Europe programme under Grant Agreement
					N. 101137283
				</a>
			</div>
		</div>
	</div>

	<span class="{footerHeaderStyle} mt-20">More Resources</span>
	<div class="max-w-lg w-full mx-auto flex">
		<div class="flex flex-col w-1/2">
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
		</div>
		<div class=" flex flex-col w-1/2">
			<a
				target="_blank"
				title="Contact"
				class=" w-full {aStyle} {button_A_active}"
				href="mailto:aidan.marler@cuanschutz.edu">✉️ Contact</a
			>
			<a
				target="_blank"
				title="Add a Language"
				class="w-full {aStyle} {button_A_active}"
				href="mailto:aidan.marler@cuanschutz.edu">🌐 Add a Language</a
			>
		</div>
	</div>
	<p class="mt-10 italic text-md">
		Have you encountered a bug, issue, or error? <br /><a
			title="Issue Report Form"
			target="_blank"
			class=" {button_A_active} {aStyle} w-full max-w-xs p-1 px-3 mb-5"
			href="https://ucdenver.co1.qualtrics.com/jfe/form/SV_8Bcvg9YcrkRHkt8"
		>
			🐛 Report it here.</a
		>
	</p>
</footer>
