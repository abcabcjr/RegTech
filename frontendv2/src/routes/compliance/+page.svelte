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
	import * as Dialog from '$lib/components/ui/dialog';
	import { Input } from '$lib/components/ui/input';
	import { Badge } from '$lib/components/ui/badge';
	import { ProgressBar } from '$lib/components/ui/progress-bar';
	import ChecklistItemComponent from '$lib/components/compliance/checklist-item.svelte';
	import { assetStore } from '$lib/stores/assets.svelte';
	import { Radar, Upload } from '@lucide/svelte';

	let checklistState: ChecklistState = $state(loadChecklistState());
	let activeView: 'manual' | 'scanner' = $state('manual');
	let backendTemplates: any[] = $state([]);
	let backendGlobalChecklist: any[] = $state([]);
	let templatesLoading: boolean = $state(false);
	let globalChecklistLoading: boolean = $state(false);
	let uploading: boolean = $state(false);
	let uploadSuccess: string | null = $state(null);
	let uploadError: string | null = $state(null);
	
	// Scan dialog state
	let scanDialogOpen: boolean = $state(false);
	let discoverListString: string = $state('');
	
	// Update status tracking
	let updatingItems: Set<string> = $state(new Set());
	let updateError: string | null = $state(null);
	
	// Convert backend templates to sections format, filtered by type
	// Note: This is reactive to activeView, backendTemplates, backendGlobalChecklist, and checklistState
	let displaySections = $derived(() => {
		// Force reactivity to checklistState
		const _ = checklistState.lastUpdated;
		
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
		
		// Sort templates by priority (must first), then category, then title
		const sortedTemplates = [...templates].sort((a, b) => {
			// Priority order: "must" comes before "should", then others
			const priorityA = a.info?.priority || 'other';
			const priorityB = b.info?.priority || 'other';
			const priorityOrder: Record<string, number> = { 'must': 0, 'should': 1, 'other': 2 };
			
			const priorityComparison = (priorityOrder[priorityB] || 2) - (priorityOrder[priorityA] || 2);
			if (priorityComparison !== 0) return priorityComparison;
			
			// Then by category
			const categoryComparison = (a.category || 'Other').localeCompare(b.category || 'Other');
			if (categoryComparison !== 0) return categoryComparison;
			
			// Finally by title
			return a.title.localeCompare(b.title);
		});
		
		// Group templates by category
		const categoryMap = new Map();
		
		sortedTemplates.forEach(template => {
			const category = template.category || 'Other';
			if (!categoryMap.has(category)) {
				categoryMap.set(category, {
					id: category.toLowerCase().replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, ''),
					title: category,
					description: `${category} compliance requirements`,
					items: []
				});
			}
			
			// Find saved state for this item
			const savedSection = checklistState.sections.find(s => s.id === category.toLowerCase().replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, ''));
			const savedItem = savedSection?.items.find(i => i.id === template.id);
			
			// Convert backend template to frontend item format
			const item = {
				id: template.id,
				title: template.title,
				description: template.description,
				helpText: template.help_text || template.description,
				whyMatters: template.why_matters || template.recommendation,
				category: category.toLowerCase(),
				required: template.required,
				status: savedItem?.status || "no", // Use saved status or default to "no"
				recommendation: template.recommendation,
				kind: template.kind || (template.scope === 'global' ? 'manual' : 'auto'),
				readOnly: template.read_only || false,
				notes: savedItem?.notes || "", // Use saved notes
				lastUpdated: savedItem?.lastUpdated || template.updated_at,
				attachments: savedItem?.attachments || [], // Use saved attachments
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
		
		// Convert to array and sort categories by priority (categories with "must" items first)
		const sections = Array.from(categoryMap.values()).sort((a, b) => {
			// Check if section has any "must" priority items
			const aHasMust = a.items.some((item: any) => item.info?.priority === 'must');
			const bHasMust = b.items.some((item: any) => item.info?.priority === 'must');
			
			if (aHasMust && !bHasMust) return -1;
			if (!aHasMust && bHasMust) return 1;
			
			// If both have must items or both don't, sort by category name
			return a.title.localeCompare(b.title);
		});
		
		return sections;
	}

	// Convert global checklist items (with asset coverage) to frontend sections format
	function convertGlobalChecklistToSections(checklistItems: any[]) {
		if (!checklistItems || checklistItems.length === 0) return [];
		
		// Sort checklist items by priority (must first), then category, then title
		const sortedItems = [...checklistItems].sort((a, b) => {
			// Priority order: "must" comes before "should", then others
			const priorityA = a.info?.priority || 'other';
			const priorityB = b.info?.priority || 'other';
			const priorityOrder: Record<string, number> = { 'must': 0, 'should': 1, 'other': 2 };
			
			const priorityComparison = (priorityOrder[priorityB] || 2) - (priorityOrder[priorityA] || 2);
			if (priorityComparison !== 0) return priorityComparison;
			
			// Then by category
			const categoryComparison = (a.category || 'Other').localeCompare(b.category || 'Other');
			if (categoryComparison !== 0) return categoryComparison;
			
			// Finally by title
			return a.title.localeCompare(b.title);
		});
		
		// Group checklist items by category
		const categoryMap = new Map();
		
		sortedItems.forEach(item => {
			const category = item.category || 'Other';
			if (!categoryMap.has(category)) {
				categoryMap.set(category, {
					id: category.toLowerCase().replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, ''),
					title: category,
					description: `${category} compliance requirements`,
					items: []
				});
			}
			
			// Find saved state for this item
			const savedSection = checklistState.sections.find(s => s.id === category.toLowerCase().replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, ''));
			const savedItem = savedSection?.items.find(i => i.id === item.id);
			
			// Convert backend checklist item to frontend item format (includes asset coverage)
			const frontendItem = {
				id: item.id,
				title: item.title,
				description: item.description,
				helpText: item.help_text || item.description,
				whyMatters: item.why_matters || item.recommendation,
				category: category.toLowerCase(),
				required: item.required,
				status: savedItem?.status || item.status || "no", // Use saved status first, then backend status
				recommendation: item.recommendation,
				kind: item.kind || item.source || 'auto',
				readOnly: item.read_only || false, // Use actual read_only field from backend
				notes: savedItem?.notes || item.notes, // Use saved notes first
				lastUpdated: savedItem?.lastUpdated || item.updated_at,
				coveredAssets: item.covered_assets || [], // This is the key difference!
				attachments: savedItem?.attachments || item.attachments || [], // Use saved attachments first
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
		
		// Convert to array and sort categories by priority (categories with "must" items first)
		const sections = Array.from(categoryMap.values()).sort((a, b) => {
			// Check if section has any "must" priority items
			const aHasMust = a.items.some((item: any) => item.info?.priority === 'must');
			const bHasMust = b.items.some((item: any) => item.info?.priority === 'must');
			
			if (aHasMust && !bHasMust) return -1;
			if (!aHasMust && bHasMust) return 1;
			
			// If both have must items or both don't, sort by category name
			return a.title.localeCompare(b.title);
		});
		
		return sections;
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

	async function updateChecklistItem(sectionId: string, itemId: string, updates: Partial<ChecklistItem>) {
		// Allow updates for all items unless explicitly read-only
		// Note: The readOnly check is handled at the component level
		
		// Clear any previous error
		updateError = null;
		
		// Track this item as updating
		updatingItems.add(itemId);
		updatingItems = new Set(updatingItems); // Trigger reactivity
		
		try {
			// Save to backend first
			if (updates.status !== undefined || updates.notes !== undefined) {
				await apiClient.checklist.statusCreate({
					item_id: itemId,
					status: updates.status as "yes" | "no" | "na" | undefined,
					notes: updates.notes,
					// asset_id is empty for global items
					asset_id: ""
				});
			}
			
			// Then update local state
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
									item.id === itemId ? { ...item, ...updates, lastUpdated: new Date().toISOString() } : item
								)
							}
						: section
				),
				lastUpdated: new Date().toISOString()
			};
			checklistState = newState;
			saveChecklistState(newState);
			
		} catch (error) {
			console.error('Failed to update checklist item:', error);
			updateError = error instanceof Error ? error.message : 'Failed to save changes. Please try again.';
		} finally {
			// Remove from updating set
			updatingItems.delete(itemId);
			updatingItems = new Set(updatingItems); // Trigger reactivity
		}
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


	// Handle scan discovery
	async function handleScanDiscovery() {
		try {
			const hosts = discoverListString.split(',').map(host => host.trim()).filter(host => host.length > 0);
			if (hosts.length === 0) return;
			
			await assetStore.discover(hosts);
			scanDialogOpen = false;
			discoverListString = '';
		} catch (error) {
			console.error('Failed to start discovery:', error);
		}
	}

	// Handle file upload for templates
	async function handleTemplateUpload(event: Event) {
		const input = event.target as HTMLInputElement;
		const file = input.files?.[0];
		
		if (!file) return;
		
		// Clear previous messages
		uploadSuccess = null;
		uploadError = null;
		
		try {
			uploading = true;
			
			// Read and parse the JSON file
			const fileContent = await file.text();
			let templatesData;
			
			try {
				templatesData = JSON.parse(fileContent);
			} catch (parseError) {
				throw new Error('Invalid JSON file. Please check the file format.');
			}
			
			// Ensure the JSON has the expected structure
			let templates = templatesData.templates || templatesData;
			if (!Array.isArray(templates)) {
				throw new Error('JSON file must contain a "templates" array or be an array of templates.');
			}
			
			console.log(`Uploading ${templates.length} templates...`);
			
			// Upload to backend
			const response = await apiClient.checklist.templatesUploadCreate({
				templates: templates
			});
			
			console.log('Upload response:', response);
			
			// Reload templates after successful upload
			await loadBackendTemplates();
			await loadBackendGlobalChecklist();
			
			uploadSuccess = `Successfully uploaded ${templates.length} templates!`;
			
			// Clear the input
			input.value = '';
			
			// Auto-dismiss success message after 5 seconds
			setTimeout(() => {
				uploadSuccess = null;
			}, 5000);
			
		} catch (error) {
			console.error('Template upload failed:', error);
			uploadError = error instanceof Error ? error.message : 'Upload failed. Please try again.';
		} finally {
			uploading = false;
		}
	}

	onMount(async () => {
		checklistState = loadChecklistState();
		await loadBackendTemplates(); // Load templates from backend
		await loadBackendGlobalChecklist(); // Load global checklist with asset coverage
		
		// Load assets and auto-open scan dialog if no assets exist
		await assetStore.load();
		
		// Check if no assets exist and auto-open scan dialog
		if (!assetStore.data?.assets || assetStore.data.assets.length === 0) {
			scanDialogOpen = true;
		}
	});
</script>

<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
	<div class="mb-8">
		<div class="flex items-center justify-between mb-4">
			<h1 class="text-3xl font-bold text-foreground">Compliance Checklist</h1>
			<div class="flex items-center gap-4">
				<div class="flex gap-2">
                    <!-- Scan Button -->
					<Button variant="default" onclick={() => scanDialogOpen = true}>
						<Radar />
						Scan
					</Button>
					<!-- Template Upload Button -->
					<div class="relative">
						<input
							type="file"
							accept=".json"
							onchange={handleTemplateUpload}
							class="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
							disabled={uploading}
						/>
						<Button variant="outline" disabled={uploading}>
							{#if uploading}
								<div class="animate-spin rounded-full h-4 w-4 border-b-2 border-current mr-2"></div>
								Uploading...
							{:else}
								<Upload />
								Upload Templates
							{/if}
						</Button>
					</div>
				</div>
			</div>
		</div>
		
		<!-- Upload Status Messages -->
		{#if uploadSuccess}
			<div class="mb-4 p-3 bg-green-50 border border-green-200 rounded-md">
				<div class="flex items-center">
					<svg class="h-4 w-4 text-green-600 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
						<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
					</svg>
					<span class="text-green-800 text-sm font-medium">{uploadSuccess}</span>
				</div>
			</div>
		{/if}
		
		{#if uploadError}
			<div class="mb-4 p-3 bg-red-50 border border-red-200 rounded-md">
				<div class="flex items-center justify-between">
					<div class="flex items-center">
						<svg class="h-4 w-4 text-red-600 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
							<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
						</svg>
						<span class="text-red-800 text-sm font-medium">{uploadError}</span>
					</div>
					<button
						onclick={() => uploadError = null}
						class="text-red-600 hover:text-red-800 ml-4"
						title="Dismiss"
						aria-label="Dismiss error message"
					>
						<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
							<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
						</svg>
					</button>
				</div>
			</div>
		{/if}
		
		{#if updateError}
			<div class="mb-4 p-3 bg-red-50 border border-red-200 rounded-md">
				<div class="flex items-center justify-between">
					<div class="flex items-center">
						<svg class="h-4 w-4 text-red-600 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
							<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
						</svg>
						<span class="text-red-800 text-sm font-medium">{updateError}</span>
					</div>
					<button
						onclick={() => updateError = null}
						class="text-red-600 hover:text-red-800 ml-4"
						title="Dismiss"
						aria-label="Dismiss error message"
					>
						<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
							<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
						</svg>
					</button>
				</div>
			</div>
		{/if}
		
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
												readOnly={item.readOnly}
												updating={updatingItems.has(item.id)}
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
								<strong>Note:</strong> These are automatic compliance checks that can be verified by the scanner. You can also manually update their status if needed.
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
												readOnly={item.readOnly}
												updating={updatingItems.has(item.id)}
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

<!-- Scan Discovery Dialog -->
<Dialog.Root bind:open={scanDialogOpen}>
	<Dialog.Content>
		<Dialog.Header>
			<Dialog.Title>Scan assets</Dialog.Title>
			<Dialog.Description>Enter domains & hosts, separated by comma.</Dialog.Description>
		</Dialog.Header>
		<Input 
			bind:value={discoverListString} 
			placeholder="example.com, example2.com, 1.1.1.1"
		/>
		<Dialog.Footer>
			<Button variant="outline" onclick={() => scanDialogOpen = false}>
				Cancel
			</Button>
			<Button onclick={handleScanDiscovery} disabled={!discoverListString.trim()}>
				Scan
			</Button>
		</Dialog.Footer>
	</Dialog.Content>
</Dialog.Root>
