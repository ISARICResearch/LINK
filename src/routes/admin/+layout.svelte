<script lang="ts">
	import { scale } from 'svelte/transition';
	import KabobMenu from '../components/kabobMenu.svelte';
	let { children } = $props();
</script>

<div class="w-full p-4 max-w-3xl md:mx-auto">
	<div in:scale={{ duration: 500, opacity: 0 }} class="w-full flex h-10 justify-between">
		<div class="text-xl pt-2 cursor-default font-medium">Admin</div>
		<KabobMenu />
	</div>
	<hr in:scale={{ duration: 500, opacity: 0 }} class="text-stone-700 mt-1 mb-5" />
	{@render children()}
</div>
