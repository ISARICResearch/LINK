<script lang="ts">
	import '../app.css';
	import Footer from './components/footer.svelte';
	import { loading } from './components/loading/loadingState.svelte';
	import LoadingModal from './components/loading/loadingModal.svelte';
	let { children } = $props();
</script>

<span
	class="font-normal border-stone-600 dark:border-stone-600 bg-stone-200 dark:bg-stone-950 text-stone-950 dark:text-stone-100"
>
	<div class="w-full fixed z-20">
		{#if loading.active}
			<LoadingModal />
		{/if}
	</div>

	<!-- Main content -->
	<main class="min-h-[90vh] grow">
		{@render children()}
	</main>

	<Footer />
</span>
