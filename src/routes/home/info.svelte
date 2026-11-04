<script lang="ts">
	let { i }: { i: string } = $props();
</script>

<div
	title={i}
	class="cursor-context-menu opacity-100 rounded-full  group hover:opacity-100 outline-sky-600/0  shadow-sky-600 hover:outline-sky-600"
>
	<svg
		xmlns="http://www.w3.org/2000/svg"
		class="w-full h-full text-sky-600 hover:text-sky-500 dark:text-sky-600 rounded-full"
		width="1em"
		height="1em"
		viewBox="0 0 20 20"
	>
		<path d="M0 0h20v20H0z" fill="none" />
		<path
			fill="currentColor"
			fill-rule="evenodd"
			d="M18 10a8 8 0 1 1-16 0a8 8 0 0 1 16 0m-7-4a1 1 0 1 1-2 0a1 1 0 0 1 2 0M9 9a1 1 0 0 0 0 2v3a1 1 0 0 0 1 1h1a1 1 0 1 0 0-2v-3a1 1 0 0 0-1-1z"
			clip-rule="evenodd"
		/>
	</svg>
</div>
