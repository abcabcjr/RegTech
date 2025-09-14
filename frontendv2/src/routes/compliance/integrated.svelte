<!-- Simple integration example using the new ChecklistManager component -->
<script lang="ts">
	import { onMount } from 'svelte';
	import ChecklistManager from '$lib/components/ChecklistManager.svelte';
	import type { ChecklistItem } from '$lib/types';
	
	let selectedCategory: string | null = $state(null);
	
	function handleItemUpdate(item: ChecklistItem) {
		console.log('Item updated:', item);
		// Here you would typically save to your backend or local storage
	}
</script>

<div class="container mx-auto px-4 py-8 max-w-7xl">
	<header class="mb-8">
		<h1 class="text-3xl font-bold text-foreground mb-4">
			Compliance Checklist - Integrated Components
		</h1>
		<p class="text-muted-foreground">
			This demonstrates the new integrated checklist components working together like butter and bread.
		</p>
	</header>

	<main class="space-y-6">
		<!-- The integrated ChecklistManager handles everything -->
		<ChecklistManager 
			{selectedCategory}
			showInfoPanels={true}
			enableFiltering={true}
			onItemUpdate={handleItemUpdate}
		/>
	</main>
</div>