<script lang="ts">
	import { onMount } from 'svelte';
	import type { ChecklistState, ChecklistItem } from '$lib/types';
	import { loadChecklistState, saveChecklistState } from '$lib/persistence';
	import { manualChecklistSections } from '$lib/checklist/items.manual';
	import { autoTemplateSections } from '$lib/checklist/items.auto.template';
	import { Button } from '$lib/components/ui/button';
	import * as Card from '$lib/components/ui/card';
	import * as Tabs from '$lib/components/ui/tabs';
	import { ProgressBar } from '$lib/components/ui/progress-bar';
	import ChecklistItemComponent from '$lib/components/compliance/checklist-item.svelte';

	let checklistState: ChecklistState = $state(loadChecklistState());
	let activeView: 'manual' | 'scanner' = $state('manual');
	
	// Use the correct data source based on active view
	let displaySections = $derived(activeView === 'manual' ? manualChecklistSections : autoTemplateSections);

	function updateChecklistItem(sectionId: string, itemId: string, updates: Partial<ChecklistItem>) {
		// Only allow updates for manual items
		if (activeView !== 'manual') return;
		
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

	// Calculate compliance score only for manual items
	let complianceScore = $derived(() => {
		if (activeView !== 'manual') return 0;
		
		const totalRequired = checklistState.sections.reduce((acc, section) => 
			acc + section.items.filter(item => item.required && item.kind === 'manual').length, 0
		);
		const completedRequired = checklistState.sections.reduce((acc, section) => 
			acc + section.items.filter(item => item.required && item.kind === 'manual' && item.status === "yes").length, 0
		);
		
		return totalRequired > 0 ? Math.round((completedRequired / totalRequired) * 100) : 0;
	});

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
		
		<!-- Manual/Scanner Toggle -->
		<div class="mb-6">
			<Tabs.Root value={activeView} class="w-full">
				<Tabs.List class="grid w-full grid-cols-2 mb-6">
					<Tabs.Trigger 
						value="manual"
						onclick={() => activeView = 'manual'}
						class="text-sm"
					>
						Manual
					</Tabs.Trigger>
					<Tabs.Trigger 
						value="scanner"
						onclick={() => activeView = 'scanner'}
						class="text-sm"
					>
						Scanner (Template)
					</Tabs.Trigger>
				</Tabs.List>

				<!-- Manual View -->
				<Tabs.Content value="manual">
					<Card.Root class="mb-6">
				<Card.Header>
							<Card.Title>Overall Compliance Score</Card.Title>
							<Card.Description>
								Your current compliance based on required manual checklist items
							</Card.Description>
				</Card.Header>
				<Card.Content>
							<ProgressBar value={complianceScore()} size="lg" />
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

					<Tabs.Root value={displaySections[0]?.id} class="w-full">
						<Tabs.List class="grid w-full grid-cols-3 lg:grid-cols-9 mb-8">
							{#each displaySections as section}
								<Tabs.Trigger 
									value={section.id}
									class="text-xs p-1"
								>
									{section.title.split(' ')[0]}
								</Tabs.Trigger>
							{/each}
						</Tabs.List>

						{#each displaySections as section}
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
											item={item}
											onUpdate={(updates) => updateChecklistItem(section.id, item.id, updates)}
											readOnly={item.readOnly || activeView === 'scanner'}
										/>
								{/each}
							</div>
							</Tabs.Content>
						{/each}
					</Tabs.Root>
			</Tabs.Content>

				<!-- Scanner Template View -->
				<Tabs.Content value="scanner">
					<Card.Root class="mb-6">
					<Card.Header>
							<Card.Title>Scanner Template</Card.Title>
						<Card.Description>
								Preview of automated security checks that will be implemented
						</Card.Description>
					</Card.Header>
					<Card.Content>
							<div class="text-sm text-muted-foreground p-4 bg-muted/30 rounded-md">
								<strong>Note:</strong> These are template items showing what automated security checks will look like when implemented. 
								The scanner functionality is not yet available.
							</div>
					</Card.Content>
				</Card.Root>

					<Tabs.Root value={displaySections[0]?.id} class="w-full">
						<Tabs.List class="grid w-full grid-cols-3 mb-8">
							{#each displaySections as section}
								<Tabs.Trigger 
									value={section.id}
									class="text-xs p-1"
								>
									{section.title.split(' ')[0]}
								</Tabs.Trigger>
							{/each}
						</Tabs.List>

						{#each displaySections as section}
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
											item={item}
											onUpdate={() => {}} 
											readOnly={item.readOnly || activeView === 'scanner'}
										/>
					{/each}
				</div>
							</Tabs.Content>
						{/each}
					</Tabs.Root>
			</Tabs.Content>
		</Tabs.Root>
		</div>
		</div>
</div>
