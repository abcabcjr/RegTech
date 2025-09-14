<script lang="ts">
	import { onMount } from 'svelte';
	import { templateLoader } from '$lib/data/template-loader.js';
	import type { ChecklistItem, ChecklistSection } from '$lib/types';
	import ChecklistItemCard from './ChecklistItemCard.svelte';
	import InlineInfoPanel from './InlineInfoPanel.svelte';
	import LoadingSpinner from './LoadingSpinner.svelte';
	
	// Props using Svelte 5 runes syntax
	interface Props {
		selectedCategory?: string | null;
		showInfoPanels?: boolean;
		enableFiltering?: boolean;
		onItemUpdate?: (item: ChecklistItem) => void;
	}
	
	let {
		selectedCategory = null,
		showInfoPanels = true,
		enableFiltering = true,
		onItemUpdate
	}: Props = $props();

	// State
	let sections: ChecklistSection[] = $state([]);
	let loading = $state(true);
	let error: string | null = $state(null);
	let expandedInfoPanels = $state(new Set<string>());
	let searchTerm = $state('');

	// Computed values
	let filteredSections = $derived.by(() => {
		if (!sections) return [];
		
		let filtered = sections;
		
		// Filter by category
		if (selectedCategory) {
			filtered = filtered.filter(section => 
				section.items.some(item => item.category === selectedCategory)
			);
		}
		
		// Filter by search term
		if (searchTerm.trim()) {
			const term = searchTerm.toLowerCase();
			filtered = filtered.map(section => ({
				...section,
				items: section.items.filter(item =>
					item.title.toLowerCase().includes(term) ||
					item.description.toLowerCase().includes(term) ||
					item.category.toLowerCase().includes(term)
				)
			})).filter(section => section.items.length > 0);
		}
		
		return filtered;
	});

	// Initialize template loader and load data
	onMount(async () => {
		try {
			await templateLoader.loadTemplates();
			const processedData = templateLoader.getProcessedData();
			
			// Convert processed data to sections format
			sections = processedData.categories.map(category => ({
				id: category.name.toLowerCase().replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, ''),
				title: category.name,
				description: `${category.name} compliance requirements`,
				items: category.items
			}));
			
			loading = false;
		} catch (err) {
			error = err instanceof Error ? err.message : 'Failed to load checklist data';
			loading = false;
		}
	});

	// Event handlers
	function handleItemUpdate(item: ChecklistItem) {
		// Update the item in our local state
		sections = sections.map(section => ({
			...section,
			items: section.items.map(i => i.id === item.id ? item : i)
		}));
		
		// Call the optional callback
		onItemUpdate?.(item);
	}

	function toggleInfoPanel(itemId: string) {
		if (expandedInfoPanels.has(itemId)) {
			expandedInfoPanels.delete(itemId);
		} else {
			expandedInfoPanels.add(itemId);
		}
		expandedInfoPanels = new Set(expandedInfoPanels);
	}

	function getItemInfo(itemId: string) {
		return templateLoader.getTemplateInfo(itemId) || null;
	}

	// Categories for filtering
	let categories = $derived.by(() => {
		const cats = new Set<string>();
		sections.forEach(section => {
			section.items.forEach(item => {
				cats.add(item.category);
			});
		});
		return Array.from(cats).sort();
	});
</script>

<!-- Loading State -->
{#if loading}
	<div class="flex items-center justify-center p-8">
		<LoadingSpinner />
		<span class="ml-3 text-muted-foreground">Loading checklist...</span>
	</div>
{/if}

<!-- Error State -->
{#if error}
	<div class="p-4 border border-destructive/50 rounded-lg bg-destructive/10">
		<h3 class="font-semibold text-destructive">Error Loading Checklist</h3>
		<p class="text-sm text-destructive/80 mt-1">{error}</p>
		<button 
			class="mt-3 px-3 py-1 bg-destructive text-destructive-foreground rounded text-sm hover:bg-destructive/90"
			onclick={() => location.reload()}
		>
			Retry
		</button>
	</div>
{/if}

<!-- Main Content -->
{#if !loading && !error}
	<!-- Controls -->
	<div class="space-y-4 mb-6">
		<!-- Search -->
		{#if enableFiltering}
			<div class="relative">
				<input
					type="text"
					bind:value={searchTerm}
					placeholder="Search checklist items..."
					class="w-full px-4 py-2 pl-10 border border-input rounded-md bg-background focus:outline-none focus:ring-2 focus:ring-ring"
				/>
				<svg class="absolute left-3 top-2.5 h-4 w-4 text-muted-foreground" fill="none" stroke="currentColor" viewBox="0 0 24 24">
					<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
				</svg>
			</div>

			<!-- Category Filter -->
			{#if categories && categories.length > 1}
				<div class="flex flex-wrap gap-2">
					<button
						class="px-3 py-1 rounded-full text-sm border transition-colors {selectedCategory === null ? 'bg-primary text-primary-foreground' : 'bg-background hover:bg-muted'}"
						onclick={() => selectedCategory = null}
					>
						All Categories
					</button>
					{#each categories as category}
						<button
							class="px-3 py-1 rounded-full text-sm border transition-colors {selectedCategory === category ? 'bg-primary text-primary-foreground' : 'bg-background hover:bg-muted'}"
							onclick={() => selectedCategory = category}
						>
							{category}
						</button>
					{/each}
				</div>
			{/if}
		{/if}
	</div>

	<!-- Checklist Sections -->
	<div class="space-y-6">
		{#each filteredSections as section (section.id)}
			<section class="space-y-3">
				<div class="border-b pb-2">
					<h2 class="text-xl font-semibold">{section.title}</h2>
					{#if section.description}
						<p class="text-muted-foreground text-sm mt-1">{section.description}</p>
					{/if}
				</div>

				<div class="space-y-3">
					{#each section.items as item (item.id)}
						<div class="space-y-2">
							<!-- Main Item Card -->
							<ChecklistItemCard 
								{item}
								onUpdate={handleItemUpdate}
								onToggleInfo={() => toggleInfoPanel(item.id)}
								showInfoButton={showInfoPanels}
								infoExpanded={expandedInfoPanels.has(item.id)}
							/>

							<!-- Inline Info Panel -->
							{#if showInfoPanels && expandedInfoPanels.has(item.id)}
								{@const info = getItemInfo(item.id)}
								{#if info}
									<InlineInfoPanel {info} />
								{/if}
							{/if}
						</div>
					{/each}
				</div>
			</section>
		{/each}

		<!-- No Results -->
		{#if filteredSections && filteredSections.length === 0}
			<div class="text-center py-8 text-muted-foreground">
				<p class="text-lg">No checklist items found</p>
				{#if searchTerm || selectedCategory}
					<p class="text-sm mt-2">Try adjusting your search or filter criteria</p>
				{/if}
			</div>
		{/if}
	</div>
{/if}

<style>
	/* Custom scrollbar for long lists */
	:global(.checklist-scroll) {
		scrollbar-width: thin;
		scrollbar-color: hsl(var(--muted)) transparent;
	}
	
	:global(.checklist-scroll::-webkit-scrollbar) {
		width: 6px;
	}
	
	:global(.checklist-scroll::-webkit-scrollbar-track) {
		background: transparent;
	}
	
	:global(.checklist-scroll::-webkit-scrollbar-thumb) {
		background: hsl(var(--muted));
		border-radius: 3px;
	}
</style>