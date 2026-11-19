<script lang="ts">
	import { page } from '$app/state';
</script>

<div class="mt-20 w-full flex p-1s justify-center flex-col">
	<div class="flex p-2 rounded-lg px-4 m-auto border bg-red-950/50 flex-col text-center">
		<h1 class="font-bold">{page.status}</h1>
		<p>{page.error?.message}</p>
	</div>
	<div class="flex p-2 bg-red-200 flex-col text-center">
		<a class="hover:underline" href="/">LINK</a>
	</div>
</div>
