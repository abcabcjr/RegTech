<script lang="ts">
	import { onMount } from 'svelte';
	import type { ChecklistState, ChecklistItem } from '$lib/types';
	import { loadChecklistState, saveChecklistState } from '$lib/persistence';
	// Remove hardcoded imports - we'll load from backend instead
	// import { manualChecklistSections } from '$lib/checklist/items.manual';
	// import { autoTemplateSections } from '$lib/checklist/items.auto.template';
	import { apiClient } from '$lib/api/client';
	import { Button } from '$lib/components/ui/button';
	import * as Card from '$lib/components/ui/card';
	import * as Tabs from '$lib/components/ui/tabs';
	import { Badge } from '$lib/components/ui/badge';
	import { ProgressBar } from '$lib/components/ui/progress-bar';
	import ChecklistItemComponent from '$lib/components/compliance/checklist-item.svelte';

	let checklistState: ChecklistState = $state(loadChecklistState());
	let activeView: 'manual' | 'scanner' = $state('manual');
	let backendTemplates: any[] = $state([]);
	let backendGlobalChecklist: any[] = $state([]);
	let templatesLoading: boolean = $state(false);
	let globalChecklistLoading: boolean = $state(false);
	
	// Convert backend templates to sections format, filtered by type
	let displaySections = $derived(() => {
		if (activeView === 'scanner') {
			// For scanner view, use global checklist (with asset coverage) filtered for auto items
			console.log('Scanner view - backendGlobalChecklist:', backendGlobalChecklist);
			
			// Try multiple filtering approaches to find auto items
			const autoItems = backendGlobalChecklist.filter(item => 
				item.kind === 'auto' || 
				item.source === 'auto' || 
				item.script_controlled === true ||
				item.read_only === true ||
				(item.scope === 'asset') // Asset-scoped items are often automatic
			);
			console.log('Filtered auto items:', autoItems);
			console.log('Sample item structure:', backendGlobalChecklist[0]);
			
			// If no auto items from global checklist, fall back to auto templates
			if (autoItems.length === 0 && backendTemplates.length > 0) {
				console.log('No auto items in global checklist, falling back to auto templates');
				const autoTemplates = backendTemplates.filter(template => template.kind === 'auto');
				return convertTemplatesToSections(autoTemplates);
			}
			
			return convertGlobalChecklistToSections(autoItems);
		} else {
			// For manual view, show only manual templates
			const manualTemplates = backendTemplates.filter(template => template.kind === 'manual');
			return convertTemplatesToSections(manualTemplates);
		}
	});

	// Convert backend templates to frontend sections format
	function convertTemplatesToSections(templates: any[]) {
		if (!templates || templates.length === 0) return [];
		
		// Group templates by category
		const categoryMap = new Map();
		
		templates.forEach(template => {
			const category = template.category || 'Other';
			if (!categoryMap.has(category)) {
				categoryMap.set(category, {
					id: category.toLowerCase().replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, ''),
					title: category,
					description: `${category} compliance requirements`,
					items: []
				});
			}
			
			// Convert backend template to frontend item format
			const item = {
				id: template.id,
				title: template.title,
				description: template.description,
				helpText: template.help_text || template.description,
				whyMatters: template.why_matters || template.recommendation,
				category: category.toLowerCase(),
				required: template.required,
				status: "no", // Default status, will be overridden by checklistState
				recommendation: template.recommendation,
				kind: template.kind || (template.scope === 'global' ? 'manual' : 'auto'),
				readOnly: template.read_only || false,
				info: template.info ? {
					whatItMeans: template.info.what_it_means,
					whyItMatters: template.info.why_it_matters,
					lawRefs: template.info.law_refs || [],
					priority: template.info.priority,
					resources: template.info.resources || []
				} : undefined
			};
			
			categoryMap.get(category).items.push(item);
		});
		
		return Array.from(categoryMap.values());
	}

	// Convert global checklist items (with asset coverage) to frontend sections format
	function convertGlobalChecklistToSections(checklistItems: any[]) {
		if (!checklistItems || checklistItems.length === 0) return [];
		
		// Group checklist items by category
		const categoryMap = new Map();
		
		checklistItems.forEach(item => {
			const category = item.category || 'Other';
			if (!categoryMap.has(category)) {
				categoryMap.set(category, {
					id: category.toLowerCase().replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, ''),
					title: category,
					description: `${category} compliance requirements`,
					items: []
				});
			}
			
			// Convert backend checklist item to frontend item format (includes asset coverage)
			const frontendItem = {
				id: item.id,
				title: item.title,
				description: item.description,
				helpText: item.help_text || item.description,
				whyMatters: item.why_matters || item.recommendation,
				category: category.toLowerCase(),
				required: item.required,
				status: item.status || "no",
				recommendation: item.recommendation,
				kind: item.kind || item.source || 'auto',
				readOnly: item.read_only || true, // Auto items are typically read-only
				notes: item.notes,
				lastUpdated: item.updated_at,
				coveredAssets: item.covered_assets || [], // This is the key difference!
				info: item.info ? {
					whatItMeans: item.info.what_it_means,
					whyItMatters: item.info.why_it_matters,
					lawRefs: item.info.law_refs || [],
					priority: item.info.priority,
					resources: item.info.resources || []
				} : undefined
			};
			
			categoryMap.get(category).items.push(frontendItem);
		});
		
		return Array.from(categoryMap.values());
	}

	// Load backend templates
	async function loadBackendTemplates() {
		templatesLoading = true;
		try {
			const response = await apiClient.checklist.templatesList();
			backendTemplates = response.data || [];
			console.log('Loaded backend templates:', backendTemplates);
		} catch (err) {
			console.error('Failed to load backend templates:', err);
			// Fallback to empty array if backend is not available
			backendTemplates = [];
		} finally {
			templatesLoading = false;
		}
	}

	// Load backend global checklist (includes asset coverage)
	async function loadBackendGlobalChecklist() {
		globalChecklistLoading = true;
		try {
			const response = await apiClient.checklist.globalList();
			backendGlobalChecklist = response.data || [];
			console.log('Loaded backend global checklist:', backendGlobalChecklist);
		} catch (err) {
			console.error('Failed to load backend global checklist:', err);
			// Fallback to empty array if backend is not available
			backendGlobalChecklist = [];
		} finally {
			globalChecklistLoading = false;
		}
	}

	function updateChecklistItem(sectionId: string, itemId: string, updates: Partial<ChecklistItem>) {
		// Only allow updates for manual items
		if (activeView !== 'manual') return;
		
		// Ensure the section exists in checklistState
		const sectionExists = checklistState.sections.some(section => section.id === sectionId);
		if (!sectionExists) {
			// Add the section from displaySections
			const displaySection = displaySections().find(section => section.id === sectionId);
			if (displaySection) {
				checklistState = {
					...checklistState,
					sections: [...checklistState.sections, displaySection]
				};
			}
		}
		
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
			),
			lastUpdated: new Date().toISOString()
		};
		checklistState = newState;
		saveChecklistState(newState);
	}

	// Calculate compliance score for current view
	let complianceScore = $derived(() => {
		const sections = displaySections();
		if (sections.length === 0) return 0;
		
		const totalRequired = sections.reduce((acc, section) => 
			acc + section.items.filter((item: any) => item.required).length, 0
		);
		
		// For manual items, check against saved state; for auto items, they don't have saved state
		let completedRequired = 0;
		if (activeView === 'manual') {
			completedRequired = sections.reduce((acc, section) => {
				const sectionState = checklistState.sections.find(s => s.id === section.id);
				if (!sectionState) return acc;
				return acc + sectionState.items.filter((item: any) => item.required && item.status === "yes").length;
			}, 0);
		}
		
		return totalRequired > 0 ? Math.round((completedRequired / totalRequired) * 100) : 0;
	});


	onMount(() => {
		checklistState = loadChecklistState();
		loadBackendTemplates(); // Load templates from backend
		loadBackendGlobalChecklist(); // Load global checklist with asset coverage
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
						Manual Templates
					</Tabs.Trigger>
					<Tabs.Trigger 
						value="scanner"
						onclick={() => activeView = 'scanner'}
						class="text-sm"
					>
						Automatic Templates
					</Tabs.Trigger>
				</Tabs.List>

				<!-- Manual View -->
				<Tabs.Content value="manual">
					<Card.Root class="mb-6">
				<Card.Header>
							<Card.Title>Manual Compliance Templates</Card.Title>
							<Card.Description>
								Manual compliance items that require human verification and documentation
							</Card.Description>
				</Card.Header>
				<Card.Content>
							{#if activeView === 'manual'}
								<ProgressBar value={complianceScore()} size="lg" />
								<div class="flex justify-between text-sm text-muted-foreground mt-2">
									<span>
										{displaySections().reduce((acc, section) => {
											const sectionState = checklistState.sections.find(s => s.id === section.id);
											if (!sectionState) return acc;
											return acc + sectionState.items.filter((item: any) => item.required && item.status === "yes").length;
										}, 0)} of {displaySections().reduce((acc, section) => 
											acc + section.items.filter((item: any) => item.required).length, 0
										)} required items completed
									</span>
									<span>
										Last updated: {new Date(checklistState.lastUpdated).toLocaleDateString()}
									</span>
								</div>
							{:else}
								<div class="text-sm text-muted-foreground p-4 bg-muted/30 rounded-md">
									<strong>Info:</strong> Manual compliance tracking is not available for automatic templates.
								</div>
							{/if}
				</Card.Content>
			</Card.Root>

					{#if templatesLoading}
						<div class="flex items-center justify-center p-8">
							<div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
							<span class="ml-2">Loading checklist templates...</span>
						</div>
					{:else if displaySections().length > 0}
						<Tabs.Root value={displaySections()[0]?.id} class="w-full">
							<Tabs.List class="grid w-full grid-cols-3 lg:grid-cols-9 mb-8">
								{#each displaySections() as section}
									<Tabs.Trigger 
										value={section.id}
										class="text-xs p-1"
									>
										{section.title.split(' ')[0]}
									</Tabs.Trigger>
								{/each}
							</Tabs.List>

							{#each displaySections() as section}
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
					{:else}
						<div class="text-center p-8 text-muted-foreground">
							<p>No checklist templates available. Please ensure the backend is running and templates are loaded.</p>
							<Button 
								variant="outline" 
								class="mt-4" 
								onclick={loadBackendTemplates}
							>
								Retry
							</Button>
						</div>
					{/if}
			</Tabs.Content>

				<!-- Scanner Template View -->
				<Tabs.Content value="scanner">
					<Card.Root class="mb-6">
					<Card.Header>
							<Card.Title>Automatic Compliance Templates</Card.Title>
						<Card.Description>
								Automated compliance checks that can be performed by the scanner
						</Card.Description>
					</Card.Header>
					<Card.Content>
							<div class="text-sm text-muted-foreground p-4 bg-muted/30 rounded-md">
								<strong>Note:</strong> These are read-only templates that would be automatically checked by the compliance scanner.
							</div>
					</Card.Content>
				</Card.Root>

					{#if globalChecklistLoading || templatesLoading}
						<div class="flex items-center justify-center p-8">
							<div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
							<span class="ml-2">Loading automatic templates...</span>
						</div>
					{:else if displaySections().length > 0}
						<Tabs.Root value={displaySections()[0]?.id} class="w-full">
							<Tabs.List class="grid w-full grid-cols-3 lg:grid-cols-9 mb-8">
								{#each displaySections() as section}
									<Tabs.Trigger 
										value={section.id}
										class="text-xs p-1"
									>
										{section.title.split(' ')[0]}
									</Tabs.Trigger>
								{/each}
							</Tabs.List>

							{#each displaySections() as section}
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
					{:else}
						<div class="text-center p-8 text-muted-foreground">
							<p>No automatic templates available. Please ensure the backend is running and templates are loaded.</p>
							<Button 
								variant="outline" 
								class="mt-4" 
								onclick={() => {
									loadBackendGlobalChecklist();
									loadBackendTemplates();
								}}
							>
								Retry
							</Button>
						</div>
					{/if}
			</Tabs.Content>
		</Tabs.Root>
		</div>
		</div>
</div>
