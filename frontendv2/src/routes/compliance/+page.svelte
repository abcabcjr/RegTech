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
	import ExportDialog from '$lib/components/compliance/ExportDialog.svelte';
	import { assetStore } from '$lib/stores/assets.svelte';
	import { Radar, Upload, Download } from '@lucide/svelte';
	import { getGuideByIdSync, getAllTemplates } from '$lib/guide/data';

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

	// Export dialog state
	let exportDialogOpen: boolean = $state(false);

	// Update status tracking
	let updatingItems: Set<string> = $state(new Set());
	let updateError: string | null = $state(null);

	// Convert backend templates to sections format, filtered by type
	// Note: This is reactive to activeView, backendTemplates, backendGlobalChecklist, and checklistState
	let displaySections = $derived(() => {
		// Force reactivity to checklistState
		const _ = checklistState.lastUpdated;

		if (activeView === 'scanner') {
			// For scanner view, use backend templates (now enhanced with covered assets) filtered for auto items
			console.log('Scanner view - backendTemplates:', backendTemplates);

			// Filter for automatic templates that are non-compliant and have covered assets
			const autoTemplates = backendTemplates.filter((template) => {
				const isAutomatic =
					template.kind === 'auto' ||
					template.source === 'auto' ||
					template.script_controlled === true ||
					template.read_only === true ||
					template.scope === 'asset'; // Asset-scoped items are often automatic

				const hasNonCompliantAssets =
					template.covered_assets &&
					template.covered_assets.length > 0 &&
					template.covered_assets.some((asset: any) => asset.status === 'no');

				return isAutomatic && hasNonCompliantAssets;
			});
			console.log('Filtered auto templates with non-compliant assets:', autoTemplates);
			console.log('Sample template structure:', backendTemplates[0]);

			// Use the enhanced template conversion that handles covered assets
			return convertTemplatesToSections(autoTemplates);
		} else {
			// For manual view, show only manual templates
			const manualTemplates = backendTemplates.filter((template) => template.kind === 'manual');
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
			const priorityOrder: Record<string, number> = { must: 0, should: 1, other: 2 };

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

		sortedTemplates.forEach((template) => {
			const category = template.category || 'Other';
			if (!categoryMap.has(category)) {
				categoryMap.set(category, {
					id: category
						.toLowerCase()
						.replace(/\s+/g, '-')
						.replace(/[^a-z0-9-]/g, ''),
					title: category,
					description: `${category} compliance requirements`,
					items: []
				});
			}

			// Find saved state for this item
			const savedSection = checklistState.sections.find(
				(s) =>
					s.id ===
					category
						.toLowerCase()
						.replace(/\s+/g, '-')
						.replace(/[^a-z0-9-]/g, '')
			);
			const savedItem = savedSection?.items.find((i) => i.id === template.id);

			// Convert backend template to frontend item format
			const item = {
				id: template.id,
				title: template.title,
				description: template.description,
				helpText: template.help_text || template.description,
				whyMatters: template.why_matters || template.recommendation,
				category: category.toLowerCase(),
				required: template.required,
				status: savedItem?.status || 'no', // Use saved status or default to "no"
				recommendation: template.recommendation,
				kind: template.kind || (template.scope === 'global' ? 'manual' : 'auto'),
				scope: template.scope, // Add scope field
				readOnly: template.read_only || false,
				notes: savedItem?.notes || template.notes || '', // Use saved notes first, then template notes
				lastUpdated: savedItem?.lastUpdated || template.updated_at,
				attachments: savedItem?.attachments || template.attachments || [], // Use saved attachments first, then template attachments
				coveredAssets: template.covered_assets || [], // Templates now include covered assets from backend
				info: template.info
					? {
							whatItMeans: template.info.what_it_means,
							whyItMatters: template.info.why_it_matters,
							lawRefs: template.info.law_refs || [],
							priority: template.info.priority,
							resources: template.info.resources || []
						}
					: undefined
			};

			// Debug logging
			console.log('Converting template to item:', {
				id: template.id,
				title: template.title,
				hasInfo: !!template.info,
				info: template.info
			});

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
			const priorityOrder: Record<string, number> = { must: 0, should: 1, other: 2 };

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

		sortedItems.forEach((item) => {
			const category = item.category || 'Other';
			if (!categoryMap.has(category)) {
				categoryMap.set(category, {
					id: category
						.toLowerCase()
						.replace(/\s+/g, '-')
						.replace(/[^a-z0-9-]/g, ''),
					title: category,
					description: `${category} compliance requirements`,
					items: []
				});
			}

			// Find saved state for this item
			const savedSection = checklistState.sections.find(
				(s) =>
					s.id ===
					category
						.toLowerCase()
						.replace(/\s+/g, '-')
						.replace(/[^a-z0-9-]/g, '')
			);
			const savedItem = savedSection?.items.find((i) => i.id === item.id);

			// Convert backend checklist item to frontend item format (includes asset coverage)
			const frontendItem = {
				id: item.id,
				title: item.title,
				description: item.description,
				helpText: item.help_text || item.description,
				whyMatters: item.why_matters || item.recommendation,
				category: category.toLowerCase(),
				required: item.required,
				status: savedItem?.status || item.status || 'no', // Use saved status first, then backend status
				recommendation: item.recommendation,
				kind: item.kind || item.source || 'auto',
				scope: item.scope, // Add scope field
				readOnly: item.read_only || false, // Use actual read_only field from backend
				notes: savedItem?.notes || item.notes, // Use saved notes first
				lastUpdated: savedItem?.lastUpdated || item.updated_at,
				coveredAssets: item.covered_assets || [], // This is the key difference!
				attachments: savedItem?.attachments || item.attachments || [], // Use saved attachments first
				info: item.info
					? {
							whatItMeans: item.info.what_it_means,
							whyItMatters: item.info.why_it_matters,
							lawRefs: item.info.law_refs || [],
							priority: item.info.priority,
							resources: item.info.resources || []
						}
					: undefined
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

	async function updateChecklistItem(
		sectionId: string,
		itemId: string,
		updates: Partial<ChecklistItem>
	) {
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
					status: updates.status as 'yes' | 'no' | 'na' | undefined,
					notes: updates.notes,
					// asset_id is empty for global items
					asset_id: ''
				});
			}

			// Then update local state
			// Ensure the section exists in checklistState
			const sectionExists = checklistState.sections.some((section) => section.id === sectionId);
			if (!sectionExists) {
				// Add the section from displaySections
				const displaySection = displaySections().find((section) => section.id === sectionId);
				if (displaySection) {
					checklistState = {
						...checklistState,
						sections: [...checklistState.sections, displaySection]
					};
				}
			}

			const newState = {
				...checklistState,
				sections: checklistState.sections.map((section) =>
					section.id === sectionId
						? {
								...section,
								items: section.items.map((item) =>
									item.id === itemId
										? { ...item, ...updates, lastUpdated: new Date().toISOString() }
										: item
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
			updateError =
				error instanceof Error ? error.message : 'Failed to save changes. Please try again.';
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

		const totalRequired = sections.reduce(
			(acc, section) => acc + section.items.filter((item: any) => item.required).length,
			0
		);

		// For manual items, check against saved state; for auto items, they don't have saved state
		let completedRequired = 0;
		if (activeView === 'manual') {
			completedRequired = sections.reduce((acc, section) => {
				const sectionState = checklistState.sections.find((s) => s.id === section.id);
				if (!sectionState) return acc;
				return (
					acc +
					sectionState.items.filter((item: any) => item.required && item.status === 'yes').length
				);
			}, 0);
		}

		return totalRequired > 0 ? Math.round((completedRequired / totalRequired) * 100) : 0;
	});

	// Calculate counts for main tabs
	let manualTemplatesCount = $derived(() => {
		// Force reactivity to checklistState
		const _ = checklistState.lastUpdated;
		
		if (!backendTemplates) return 0;
		
		// Get all manual templates and count those with status 'no' (non-compliant)
		const manualTemplates = backendTemplates.filter((template) => template.kind === 'manual');
		
		return manualTemplates.reduce((count, template) => {
			// Find saved state for this template
			const savedSection = checklistState.sections.find((section) => {
				const sectionId = (template.category || 'Other')
					.toLowerCase()
					.replace(/\s+/g, '-')
					.replace(/[^a-z0-9-]/g, '');
				return section.id === sectionId;
			});
			
			const savedItem = savedSection?.items.find((item) => item.id === template.id);
			const status = savedItem?.status || 'no'; // Default to 'no' if not set
			
			// Only count if status is 'no' (non-compliant)
			return status === 'no' ? count + 1 : count;
		}, 0);
	});

	// Helper function to count non-compliant items in a section
	function getNonCompliantSectionCount(section: any): number {
		if (activeView === 'scanner') {
			// For scanner view, all displayed items are already non-compliant
			return section.items.length;
		} else {
			// For manual view, count items with status 'no' or not set
			const sectionState = checklistState.sections.find((s) => s.id === section.id);
			if (!sectionState) {
				// If no saved state, all items are non-compliant by default
				return section.items.length;
			}
			
			// Count items with status 'no' or not set
			return sectionState.items.filter((item: any) => {
				const status = item.status || 'no';
				return status === 'no';
			}).length;
		}
	}

	let nonCompliantIssuesCount = $derived(() => {
		if (!backendTemplates) return 0;
		const autoTemplates = backendTemplates.filter((template) => {
			const isAutomatic =
				template.kind === 'auto' ||
				template.source === 'auto' ||
				template.script_controlled === true ||
				template.read_only === true ||
				template.scope === 'asset';

			const hasNonCompliantAssets =
				template.covered_assets &&
				template.covered_assets.length > 0 &&
				template.covered_assets.some((asset: any) => asset.status === 'no');

			return isAutomatic && hasNonCompliantAssets;
		});
		return autoTemplates.length;
	});

	// Handle scan discovery
	async function handleScanDiscovery() {
		try {
			const hosts = discoverListString
				.split(',')
				.map((host) => host.trim())
				.filter((host) => host.length > 0);
			if (hosts.length === 0) return;

			await assetStore.discover(hosts);
			scanDialogOpen = false;
			discoverListString = '';
		} catch (error) {
			console.error('Failed to start discovery:', error);
		}
	}

	// Prepare export data - always include both manual and scanner data regardless of current view
	function prepareExportData() {
		const complianceItems: Array<{ section: string; items: any[] }> = [];
		const scannedIssues: Array<{ section: string; items: any[] }> = [];

		// Get manual compliance items
		const manualTemplates = backendTemplates.filter((template) => template.kind === 'manual');
		const manualSections = convertTemplatesToSections(manualTemplates);
		for (const section of manualSections) {
			complianceItems.push({
				section: section.title,
				items: section.items
			});
		}

		// Get scanner/automatic issues
		const autoTemplates = backendTemplates.filter((template) => {
			const isAutomatic =
				template.kind === 'auto' ||
				template.source === 'auto' ||
				template.script_controlled === true ||
				template.read_only === true ||
				template.scope === 'asset';

			const hasNonCompliantAssets =
				template.covered_assets &&
				template.covered_assets.length > 0 &&
				template.covered_assets.some((asset: any) => asset.status === 'no');

			return isAutomatic && hasNonCompliantAssets;
		});

		const scannerSections = convertTemplatesToSections(autoTemplates);
		for (const section of scannerSections) {
			scannedIssues.push({
				section: section.title,
				items: section.items
			});
		}

		return { complianceItems, scannedIssues };
	}

	// Handle export button click
	function handleExportClick() {
		exportDialogOpen = true;
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
			await loadBackendTemplates(); // This now includes covered assets
			await loadBackendGlobalChecklist(); // Still needed for manual view

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
		await loadBackendTemplates(); // Load enhanced templates from backend (now with covered assets)
		await loadBackendGlobalChecklist(); // Load global checklist (still needed for manual view)

		// Load assets and auto-open scan dialog if no assets exist
		await assetStore.load();

		// Check if no assets exist and auto-open scan dialog
		if (!assetStore.data?.assets || assetStore.data.assets.length === 0) {
			scanDialogOpen = true;
		}
	});
</script>

<div class="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
	<div class="mb-8">
		<div class="mb-4 flex items-center justify-between">
			<h1 class="text-foreground text-3xl font-bold">Compliance Checklist</h1>
			<div class="flex items-center gap-4">
				<div class="flex gap-2">
					<!-- Scan Button -->
					<Button variant="default" onclick={() => (scanDialogOpen = true)}>
						<Radar />
						Scan
					</Button>
					<!-- Export Button -->
					<Button variant="secondary" onclick={handleExportClick}>
						<Download />
						Export PDF
					</Button>
					<!-- Template Upload Button -->
					<div class="relative">
						<input
							type="file"
							accept=".json"
							onchange={handleTemplateUpload}
							class="absolute inset-0 h-full w-full cursor-pointer opacity-0"
							disabled={uploading}
						/>
						<Button variant="outline" disabled={uploading}>
							{#if uploading}
								<div class="mr-2 h-4 w-4 animate-spin rounded-full border-b-2 border-current"></div>
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
			<div class="mb-4 rounded-md border border-green-200 bg-green-50 p-3">
				<div class="flex items-center">
					<svg
						class="mr-2 h-4 w-4 text-green-600"
						fill="none"
						stroke="currentColor"
						viewBox="0 0 24 24"
					>
						<path
							stroke-linecap="round"
							stroke-linejoin="round"
							stroke-width="2"
							d="M5 13l4 4L19 7"
						/>
					</svg>
					<span class="text-sm font-medium text-green-800">{uploadSuccess}</span>
				</div>
			</div>
		{/if}

		{#if uploadError}
			<div class="mb-4 rounded-md border border-red-200 bg-red-50 p-3">
				<div class="flex items-center justify-between">
					<div class="flex items-center">
						<svg
							class="mr-2 h-4 w-4 text-red-600"
							fill="none"
							stroke="currentColor"
							viewBox="0 0 24 24"
						>
							<path
								stroke-linecap="round"
								stroke-linejoin="round"
								stroke-width="2"
								d="M6 18L18 6M6 6l12 12"
							/>
						</svg>
						<span class="text-sm font-medium text-red-800">{uploadError}</span>
					</div>
					<button
						onclick={() => (uploadError = null)}
						class="ml-4 text-red-600 hover:text-red-800"
						title="Dismiss"
						aria-label="Dismiss error message"
					>
						<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
							<path
								stroke-linecap="round"
								stroke-linejoin="round"
								stroke-width="2"
								d="M6 18L18 6M6 6l12 12"
							/>
						</svg>
					</button>
				</div>
			</div>
		{/if}

		{#if updateError}
			<div class="mb-4 rounded-md border border-red-200 bg-red-50 p-3">
				<div class="flex items-center justify-between">
					<div class="flex items-center">
						<svg
							class="mr-2 h-4 w-4 text-red-600"
							fill="none"
							stroke="currentColor"
							viewBox="0 0 24 24"
						>
							<path
								stroke-linecap="round"
								stroke-linejoin="round"
								stroke-width="2"
								d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
							/>
						</svg>
						<span class="text-sm font-medium text-red-800">{updateError}</span>
					</div>
					<button
						onclick={() => (updateError = null)}
						class="ml-4 text-red-600 hover:text-red-800"
						title="Dismiss"
						aria-label="Dismiss error message"
					>
						<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
							<path
								stroke-linecap="round"
								stroke-linejoin="round"
								stroke-width="2"
								d="M6 18L18 6M6 6l12 12"
							/>
						</svg>
					</button>
				</div>
			</div>
		{/if}

		<p class="text-muted-foreground mb-6">
			Track your compliance with Moldova's Cybersecurity Law requirements. Complete the checklist
			items below and upload evidence where applicable.
		</p>

		<!-- Manual/Scanner Toggle -->
		<div class="mb-6">
			<Tabs.Root value={activeView} class="w-full">
				<Tabs.List class="mb-6 grid w-full grid-cols-2">
					<Tabs.Trigger
						value="manual"
						onclick={() => (activeView = 'manual')}
						class="flex items-center gap-2 text-sm"
					>
						<span>Compliance Items</span>
						{#if manualTemplatesCount() > 0}
							<Badge variant="destructive" class="h-4 min-w-[16px] px-1 py-0 text-xs">
								{manualTemplatesCount()}
							</Badge>
						{/if}
					</Tabs.Trigger>
					<Tabs.Trigger
						value="scanner"
						onclick={() => (activeView = 'scanner')}
						class="flex items-center gap-2 text-sm"
					>
						<span>Scanned Issues</span>
						{#if nonCompliantIssuesCount() > 0}
							<Badge variant="destructive" class="h-4 min-w-[16px] px-1 py-0 text-xs">
								{nonCompliantIssuesCount()}
							</Badge>
						{/if}
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
								<div class="text-muted-foreground mt-2 flex justify-between text-sm">
									<span>
										{displaySections().reduce((acc, section) => {
											const sectionState = checklistState.sections.find((s) => s.id === section.id);
											if (!sectionState) return acc;
											return (
												acc +
												sectionState.items.filter(
													(item: any) => item.required && item.status === 'yes'
												).length
											);
										}, 0)} of {displaySections().reduce(
											(acc, section) =>
												acc + section.items.filter((item: any) => item.required).length,
											0
										)} required items completed
									</span>
									<span>
										Last updated: {new Date(checklistState.lastUpdated).toLocaleDateString()}
									</span>
								</div>
							{:else}
								<div class="text-muted-foreground bg-muted/30 rounded-md p-4 text-sm">
									<strong>Info:</strong> Manual compliance tracking is not available for automatic templates.
								</div>
							{/if}
						</Card.Content>
					</Card.Root>

					{#if templatesLoading}
						<div class="flex items-center justify-center p-8">
							<div class="border-primary h-8 w-8 animate-spin rounded-full border-b-2"></div>
							<span class="ml-2">Loading checklist templates...</span>
						</div>
					{:else if displaySections().length > 0}
						<Tabs.Root value={displaySections()[0]?.id} class="w-full">
							<Tabs.List class="flex w-full justify-between">
								{#each displaySections() as section}
									<Tabs.Trigger value={section.id} class="flex items-center gap-1 p-1 text-xs">
										<span>{section.title.split(' ')[0]}</span>
										{#if getNonCompliantSectionCount(section) > 0}
											<Badge variant="destructive" class="h-4 min-w-[16px] px-1 py-0 text-xs">
												{getNonCompliantSectionCount(section)}
											</Badge>
										{/if}
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
												{item}
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
						<div class="text-muted-foreground p-8 text-center">
							<p>
								No checklist templates available. Please ensure the backend is running and templates
								are loaded.
							</p>
							<Button variant="outline" class="mt-4" onclick={loadBackendTemplates}>Retry</Button>
						</div>
					{/if}
				</Tabs.Content>

				<!-- Scanner Template View -->
				<Tabs.Content value="scanner">
					<Card.Root class="mb-6">
						<Card.Header>
							<Card.Title>Non-Compliant Automatic Templates</Card.Title>
							<Card.Description>
								Automatic compliance checks that have failed and require attention
							</Card.Description>
						</Card.Header>
						<Card.Content>
							<div class="text-muted-foreground bg-muted/30 rounded-md p-4 text-sm">
								<strong>Note:</strong> Only showing automatic compliance checks that have non-compliant
								assets. These require immediate attention to ensure compliance.
							</div>
						</Card.Content>
					</Card.Root>

					{#if templatesLoading}
						<div class="flex items-center justify-center p-8">
							<div class="border-primary h-8 w-8 animate-spin rounded-full border-b-2"></div>
							<span class="ml-2">Loading automatic templates...</span>
						</div>
					{:else if displaySections().length > 0}
						<Tabs.Root value={displaySections()[0]?.id} class="w-full">
							<Tabs.List class="flex w-full justify-between">
								{#each displaySections() as section}
									<Tabs.Trigger value={section.id} class="flex items-center gap-1 p-1 text-xs">
										<span>{section.title.split(' ')[0]}</span>
										{#if getNonCompliantSectionCount(section) > 0}
											<Badge variant="destructive" class="h-4 min-w-[16px] px-1 py-0 text-xs">
												{getNonCompliantSectionCount(section)}
											</Badge>
										{/if}
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
												{item}
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
						<div class="text-muted-foreground p-8 text-center">
							<p>No non-compliant automatic templates found. This means either:</p>
							<ul class="mt-2 space-y-1 text-sm">
								<li>• All automatic compliance checks are passing</li>
								<li>• No assets have been scanned yet</li>
								<li>• No automatic templates are configured</li>
							</ul>
							<Button variant="outline" class="mt-4" onclick={loadBackendTemplates}>Refresh</Button>
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
		<Input bind:value={discoverListString} placeholder="example.com, example2.com, 1.1.1.1" />
		<Dialog.Footer>
			<Button variant="outline" onclick={() => (scanDialogOpen = false)}>Cancel</Button>
			<Button onclick={handleScanDiscovery} disabled={!discoverListString.trim()}>Scan</Button>
		</Dialog.Footer>
	</Dialog.Content>
</Dialog.Root>

<!-- Export Dialog -->
{#if exportDialogOpen}
	{@const exportData = prepareExportData()}
	<ExportDialog
		bind:open={exportDialogOpen}
		complianceItems={exportData.complianceItems}
		scannedIssues={exportData.scannedIssues}
	/>
{/if}
