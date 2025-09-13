<script lang="ts">
	import { onMount } from 'svelte';
	import type { ChecklistState, ChecklistItem } from '$lib/types';
	import { loadChecklistState, saveChecklistState } from '$lib/persistence';
	import { Button } from '$lib/components/ui/button';
	import * as Card from '$lib/components/ui/card';
	import * as Tabs from '$lib/components/ui/tabs';
	import { ProgressBar } from '$lib/components/ui/progress-bar';
	import ChecklistItemComponent from '$lib/components/compliance/checklist-item.svelte';

	let checklistState: ChecklistState = $state(loadChecklistState());

	function updateChecklistItem(sectionId: string, itemId: string, updates: Partial<ChecklistItem>) {
		const newState = {
			...checklistState,
			sections: checklistState.sections.map(section => 
				section.id === sectionId 
					? {
							...section,
							items: section.items.map(item => 
								item.id === itemId ? { ...item, ...updates } : item
							)
						}
					: section
			)
		};
		checklistState = newState;
		saveChecklistState(newState);
	}

	onMount(() => {
		checklistState = loadChecklistState();
	});
</script>

<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
	<div class="mb-8">
		<h1 class="text-3xl font-bold text-foreground mb-4">Compliance Checklist</h1>
		<p class="text-muted-foreground mb-6">
			Track your compliance with Moldova's Cybersecurity Law requirements. 
			Complete the checklist items below and upload evidence where applicable.
		</p>
		
		<Card.Root class="mb-6">
			<Card.Header>
				<Card.Title>Overall Compliance Score</Card.Title>
				<Card.Description>
					Your current compliance based on required checklist items
				</Card.Description>
			</Card.Header>
			<Card.Content>
				<ProgressBar value={checklistState.complianceScore} size="lg" />
				<div class="flex justify-between text-sm text-muted-foreground mt-2">
					<span>
						{checklistState.sections.reduce((acc, section) => 
							acc + section.items.filter(item => item.required && item.status === "yes").length, 0
						)} of {checklistState.sections.reduce((acc, section) => 
							acc + section.items.filter(item => item.required).length, 0
						)} required items completed
					</span>
					<span>
						Last updated: {new Date(checklistState.lastUpdated).toLocaleDateString()}
					</span>
				</div>
			</Card.Content>
		</Card.Root>
	</div>

	<Tabs.Root value={checklistState.sections[0]?.id} class="w-full">
		<Tabs.List class="grid w-full grid-cols-3 lg:grid-cols-9 mb-8">
			{#each checklistState.sections as section}
				<Tabs.Trigger 
					value={section.id}
					class="text-xs p-1"
				>
					{section.title.split(' ')[0]}
				</Tabs.Trigger>
			{/each}
		</Tabs.List>

		{#each checklistState.sections as section}
			<Tabs.Content value={section.id}>
				<Card.Root class="mb-6">
					<Card.Header>
						<Card.Title>{section.title}</Card.Title>
						<Card.Description>{section.description}</Card.Description>
					</Card.Header>
				</Card.Root>

				<div class="space-y-4">
					{#each section.items as item}
						<ChecklistItemComponent
							{item}
							onUpdate={(updates) => updateChecklistItem(section.id, item.id, updates)}
						/>
					{/each}
				</div>
			</Tabs.Content>
		{/each}
	</Tabs.Root>
</div>
