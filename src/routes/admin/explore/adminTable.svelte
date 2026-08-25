<script lang="ts">
	let {
		name,
		table
	}: {
		name: string;
		table: Record<string, unknown>[];
	} = $props();

	/*
    Use table data to get type, use type to get actual table from supabase, use table from supabase to get proper columns
    */
</script>

<h2>{name}</h2>
<table class="w-full border-2 border-inherit block max-h-lg overflow-scroll">
	<thead>
		<tr>
			{#each Object.keys(table[0]) as col}
				<th>{col}</th>
			{/each}
		</tr>
	</thead>
	<tbody class="max-h-30">
		{#each Object.values(table) as row}
			<tr>
				{#each Object.values(row) as cell}
					<td>{cell}</td>
				{/each}
			</tr>
		{/each}
	</tbody>
</table>
