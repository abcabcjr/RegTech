<script lang="ts">
	import { onMount } from 'svelte';
	import { scale, fly } from 'svelte/transition';
	import { quintOut } from 'svelte/easing';
	import type { ChecklistState, ChecklistItem } from '$lib/types';
	import { loadChecklistState, saveChecklistState } from '$lib/persistence';
	// Remove hardcoded imports - we'll load from backend instead
	// import { manualChecklistSections } from '$lib/checklist/items.manual';
	// import { autoTemplateSections } from '$lib/checklist/items.auto.template';
	import { apiClient } from '$lib/api/client';
	import { mapBackendInfoToInfoPanel } from '$lib/guide/mapper';
	import { Button } from '$lib/components/ui/button';
	import * as Card from '$lib/components/ui/card';
	import * as Tabs from '$lib/components/ui/tabs';
	import * as Dialog from '$lib/components/ui/dialog';
	import { Input } from '$lib/components/ui/input';
	import { Badge } from '$lib/components/ui/badge';
	import { ProgressBar } from '$lib/components/ui/progress-bar';
	import { Label } from '$lib/components/ui/label';
	import * as Select from '$lib/components/ui/select';
	import ChecklistItemComponent from '$lib/components/compliance/checklist-item.svelte';
	import ExportDialog from '$lib/components/compliance/ExportDialog.svelte';
	import BusinessUnitCard from '$lib/components/compliance/BusinessUnitCard.svelte';
	import { assetStore } from '$lib/stores/assets.svelte';
	import { businessUnitsStore } from '$lib/stores/businessUnits.svelte';
	import { checklistStore } from '$lib/stores/checklist.svelte';
	import { Radar, Upload, Download, Shield, Building, Users, TrendingUp, ArrowRight, ArrowLeft, CheckCircle } from '@lucide/svelte';
	import { getGuideByIdSync, getAllTemplates } from '$lib/guide/data';

	let checklistState: ChecklistState = $state(loadChecklistState());
	let activeView: 'manual' | 'scanner' = $state('manual');
	let backendTemplates: any[] = $state([]);
	let backendGlobalChecklist: any[] = $state([]);
	let jsonTemplatesData: any = $state(null);
	let templatesLoading: boolean = $state(false);
	let globalChecklistLoading: boolean = $state(false);
	let uploading: boolean = $state(false);
	let uploadSuccess: string | null = $state(null);
	let uploadError: string | null = $state(null);
	let dataRefreshTimestamp: number = $state(Date.now()); // Force reactivity trigger

	// Scan dialog state
	let scanDialogOpen: boolean = $state(false);
	let discoverListString: string = $state('');

	// Export dialog state
	let exportDialogOpen: boolean = $state(false);

	// Intro guide dialog state
	let introDialogOpen: boolean = $state(false);
	let introStep: 'welcome' | 'company-info' | 'discovery' = $state('welcome');
	let introDialogElement: HTMLElement | null = $state(null);
	let companyInfo = $state({
		name: '',
		turnover: '',
		employees: '',
		industry: '',
		country: 'Moldova'
	});

	// Update status tracking
	let updatingItems: Set<string> = $state(new Set());
	let updateError: string | null = $state(null);

	// Floating progress bar state
	let showFloatingProgress: boolean = $state(false);
	let progressBarElement: HTMLElement | null = $state(null);

	// Convert backend templates to sections format, filtered by type
	// Note: This is reactive to activeView, backendTemplates, currentChecklistData, and checklistState
	let displaySections = $derived(() => {
		// Force reactivity to checklistState and data refresh
		const _ = checklistState.lastUpdated;
		const __ = dataRefreshTimestamp;

		if (activeView === 'scanner') {
			// For scanner view, use backend templates (now enhanced with covered assets) filtered for auto items
			// AUTOMATIC ITEMS REMAIN GLOBAL - NOT AFFECTED BY BUSINESS UNIT SELECTION
			console.log('Scanner view - backendTemplates (GLOBAL):', backendTemplates);

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
			// For manual view, use business unit specific checklist data if business unit is selected
			// MANUAL ITEMS ARE PER BUSINESS UNIT
			const currentData = currentChecklistData();
			console.log('📋 Manual view - currentChecklistData length:', currentData.length);
			console.log('📋 Manual view - currentChecklistData sample:', currentData.slice(0, 2));
			console.log(
				'🏢 Business unit selected:',
				businessUnitsStore.selectedBusinessUnit?.name || 'Global'
			);

			// Filter for manual templates only (but also include templates without kind specified)
			const manualTemplates = currentData.filter((template) => 
				template.kind === 'manual' || 
				template.kind === undefined || 
				template.kind === null ||
				template.source === 'manual'
			);
			console.log('📝 Filtered manual templates:', manualTemplates.length);
			console.log('📝 Manual templates sample:', manualTemplates.slice(0, 2));

			// Use the special function that handles backend checklist data with statuses
			return convertGlobalChecklistToSections(manualTemplates);
		}
	});

	// Convert backend templates to frontend sections format
	function convertTemplatesToSections(templates: any[]) {
		if (!templates || templates.length === 0) return [];

		// Sort templates by priority (critical first), then category, then title
		const sortedTemplates = [...templates].sort((a, b) => {
			// Priority order: critical > high > medium > low
			const priorityA = a.priority_number || a.priority || 'other';
			const priorityB = b.priority_number || b.priority || 'other';
			
			// Use priority_number if available, otherwise fall back to priority text
			let priorityComparisonA: number, priorityComparisonB: number;
			
			if (typeof priorityA === 'number') {
				priorityComparisonA = priorityA;
			} else {
				const priorityOrder: Record<string, number> = { critical: 1, high: 2, medium: 3, low: 4, other: 5 };
				priorityComparisonA = priorityOrder[priorityA] || 5;
			}
			
			if (typeof priorityB === 'number') {
				priorityComparisonB = priorityB;
			} else {
				const priorityOrder: Record<string, number> = { critical: 1, high: 2, medium: 3, low: 4, other: 5 };
				priorityComparisonB = priorityOrder[priorityB] || 5;
			}

			const priorityComparison = priorityComparisonA - priorityComparisonB;
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
				info: template.info ? mapBackendInfoToInfoPanel(template.info) : undefined,
				priority: template.priority,
				priority_number: template.priority_number
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

		// Convert to array and sort categories by priority (categories with "critical" items first)
		const sections = Array.from(categoryMap.values()).sort((a, b) => {
			// Get the highest priority in each section (lowest number = highest priority)
			const getHighestPriority = (items: any[]) => {
				return Math.min(...items.map((item: any) => 
					item.priority_number || 
					(item.priority === 'critical' ? 1 : 
					 item.priority === 'high' ? 2 : 
					 item.priority === 'medium' ? 3 : 
					 item.priority === 'low' ? 4 : 5)
				));
			};

			const aPriority = getHighestPriority(a.items);
			const bPriority = getHighestPriority(b.items);

			if (aPriority !== bPriority) return aPriority - bPriority;

			// If same priority, sort by category name
			return a.title.localeCompare(b.title);
		});

		return sections;
	}

	// Convert global checklist items (with asset coverage) to frontend sections format
	function convertGlobalChecklistToSections(checklistItems: any[]) {
		if (!checklistItems || checklistItems.length === 0) return [];


		// Sort checklist items by priority (critical first), then category, then title
		const sortedItems = [...checklistItems].sort((a, b) => {
			// Priority order: critical > high > medium > low
			const priorityA = a.priority_number || a.priority || 'other';
			const priorityB = b.priority_number || b.priority || 'other';
			
			// Use priority_number if available, otherwise fall back to priority text
			let priorityComparisonA: number, priorityComparisonB: number;
			
			if (typeof priorityA === 'number') {
				priorityComparisonA = priorityA;
			} else {
				const priorityOrder: Record<string, number> = { critical: 1, high: 2, medium: 3, low: 4, other: 5 };
				priorityComparisonA = priorityOrder[priorityA] || 5;
			}
			
			if (typeof priorityB === 'number') {
				priorityComparisonB = priorityB;
			} else {
				const priorityOrder: Record<string, number> = { critical: 1, high: 2, medium: 3, low: 4, other: 5 };
				priorityComparisonB = priorityOrder[priorityB] || 5;
			}

			const priorityComparison = priorityComparisonA - priorityComparisonB;
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

			// For business unit context, IGNORE local state and use ONLY backend data
			// For global context, use local state as fallback
			const useBackendDataOnly = businessUnitsStore.selectedBusinessUnit !== null;

			let savedItem = null;
			if (!useBackendDataOnly) {
				// Only use saved state when in global context
				const savedSection = checklistState.sections.find(
					(s) =>
						s.id ===
						category
							.toLowerCase()
							.replace(/\s+/g, '-')
							.replace(/[^a-z0-9-]/g, '')
				);
				savedItem = savedSection?.items.find((i) => i.id === item.id);
			}

			// Get guide data from JSON templates
			let guideInfo = null;
			if (jsonTemplatesData) {
				guideInfo = getGuideByIdSync(item.id, jsonTemplatesData);
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
				// FOR BUSINESS UNITS: Use ONLY backend status, ignore local state
				// FOR GLOBAL: Use saved status first, then backend status
				status: useBackendDataOnly ? item.status || 'na' : savedItem?.status || item.status || 'no',
				recommendation: item.recommendation,
				kind: item.kind || item.source || 'auto',
				priority: item.priority,
				priority_number: item.priority_number,
				scope: item.scope, // Add scope field
				readOnly: item.read_only || false, // Use actual read_only field from backend
				// FOR BUSINESS UNITS: Use ONLY backend notes, ignore local state
				notes: useBackendDataOnly ? item.notes || '' : savedItem?.notes || item.notes || '',
				lastUpdated: useBackendDataOnly
					? item.updated_at
					: savedItem?.lastUpdated || item.updated_at,
				coveredAssets: item.covered_assets || [], // This is the key difference!
				// FOR BUSINESS UNITS: Use ONLY backend attachments, ignore local state
				attachments: useBackendDataOnly
					? item.attachments || []
					: savedItem?.attachments || item.attachments || [],
				info: guideInfo
					? mapBackendInfoToInfoPanel(guideInfo)
					: item.info
						? mapBackendInfoToInfoPanel(item.info)
						: undefined
			};

			console.log(
				`🔍 Item ${item.id}: useBackendDataOnly=${useBackendDataOnly}, status=${frontendItem.status}, notes=${frontendItem.notes}`
			);

			categoryMap.get(category).items.push(frontendItem);
		});

		// Convert to array and sort categories by priority (categories with "critical" items first)
		const sections = Array.from(categoryMap.values()).sort((a, b) => {
			// Get the highest priority in each section (lowest number = highest priority)
			const getHighestPriority = (items: any[]) => {
				return Math.min(...items.map((item: any) => 
					item.priority_number || 
					(item.priority === 'critical' ? 1 : 
					 item.priority === 'high' ? 2 : 
					 item.priority === 'medium' ? 3 : 
					 item.priority === 'low' ? 4 : 5)
				));
			};

			const aPriority = getHighestPriority(a.items);
			const bPriority = getHighestPriority(b.items);

			if (aPriority !== bPriority) return aPriority - bPriority;

			// If same priority, sort by category name
			return a.title.localeCompare(b.title);
		});

		return sections;
	}

	// Load templates from backend API
	async function loadTemplates() {
		templatesLoading = true;
		try {
			const response = await apiClient.checklist.templatesList();
			backendTemplates = response.data || [];
			console.log('Loaded templates from backend:', backendTemplates.length, 'templates');
			
			const securityAudit = backendTemplates.find((t) => t.id === 'security-audit');
			console.log('Security Audit template:', securityAudit);
		} catch (err) {
			console.error('Failed to load templates from backend:', err);
			backendTemplates = [];
		} finally {
			templatesLoading = false;
		}
	}

	// Load JSON templates data
	async function loadJsonTemplates() {
		try {
			jsonTemplatesData = await getAllTemplates();
			console.log('Loaded JSON templates data:', jsonTemplatesData);
		} catch (err) {
			console.error('Failed to load JSON templates data:', err);
			jsonTemplatesData = null;
		}
	}

	// Load backend global checklist (includes asset coverage)
	async function loadBackendGlobalChecklist() {
		globalChecklistLoading = true;
		try {
			const response = await apiClient.checklist.globalList();
			backendGlobalChecklist = response.data || [];
			console.log('Loaded backend global checklist:', backendGlobalChecklist.length, 'items');
		} catch (err) {
			console.error('Failed to load backend global checklist:', err);
			// Fallback to empty array if backend is not available
			backendGlobalChecklist = [];
		} finally {
			globalChecklistLoading = false;
		}
	}

	// Load checklist data based on selected business unit
	async function loadCurrentChecklist() {
		if (businessUnitsStore.selectedBusinessUnit) {
			// Load business unit specific checklist
			await checklistStore.loadBusinessUnit(businessUnitsStore.selectedBusinessUnit.id);
			console.log(
				'Loaded business unit checklist for:',
				businessUnitsStore.selectedBusinessUnit.name
			);
		} else {
			// Load global checklist
			await loadBackendGlobalChecklist();
			console.log('Loaded global checklist');
		}
	}

	// Get the current checklist data based on selected business unit
	// This is ONLY used for MANUAL items - automatic items always use backendTemplates (global)
	let currentChecklistData = $derived(() => {
		// Force reactivity on data refresh timestamp
		const _ = dataRefreshTimestamp;

		if (businessUnitsStore.selectedBusinessUnit) {
			// Return business unit specific manual checklist items
			const businessUnitData =
				checklistStore.businessUnitItems[businessUnitsStore.selectedBusinessUnit.id] || [];
			console.log(
				'🏢 Business Unit Data for',
				businessUnitsStore.selectedBusinessUnit.name,
				':',
				businessUnitData
			);
			return businessUnitData;
		} else {
			// Return global manual checklist items
			console.log('🌍 Global Data:', backendGlobalChecklist);
			return backendGlobalChecklist;
		}
	});

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
				if (businessUnitsStore.selectedBusinessUnit) {
					// Use business unit checklist status endpoint
					await checklistStore.setBusinessUnitStatus(
						itemId,
						businessUnitsStore.selectedBusinessUnit.id,
						updates.status as 'yes' | 'no' | 'na',
						updates.notes || ''
					);
				} else {
					// Use global checklist status endpoint
					await apiClient.checklist.statusCreate({
						item_id: itemId,
						status: updates.status as 'yes' | 'no' | 'na' | undefined,
						notes: updates.notes,
						// asset_id is empty for global items
						asset_id: ''
					});
				}
			}

			// Only update local state when in global context
			// For business unit context, the backend data is the source of truth
			if (!businessUnitsStore.selectedBusinessUnit) {
				// Update local state only for global context
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
			} else {
				console.log(
					'🏢 Business unit context - skipping local state update, using backend data only'
				);
			}

			// Force a data refresh to update the display
			dataRefreshTimestamp = Date.now();
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

		// Count all required items (including "na" - not applicable is still a valid status)
		const totalRequired = sections.reduce(
			(acc, section) => acc + section.items.filter((item: any) => item.required).length,
			0
		);

		// Count completed items: both "yes" and "na" are considered compliant
		const completedRequired = sections.reduce((acc, section) => {
			return (
				acc +
				section.items.filter((item: any) => item.required && (item.status === 'yes' || item.status === 'na')).length
			);
		}, 0);

		const score = totalRequired > 0 ? Math.round((completedRequired / totalRequired) * 100) : 0;
		
		// Debug logging
		console.log('🔍 Progress Bar Debug:', {
			totalRequired,
			completedRequired,
			score,
			sections: sections.map(s => ({
				title: s.title,
				required: s.items.filter(i => i.required).length,
				completed: s.items.filter(i => i.required && (i.status === 'yes' || i.status === 'na')).length
			}))
		});

		return score;
	});

	// Calculate counts for main tabs
	let manualTemplatesCount = $derived(() => {
		// Force reactivity to checklistState and data refresh
		const _ = checklistState.lastUpdated;
		const __ = dataRefreshTimestamp;

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
		// Force reactivity to data changes
		const _ = dataRefreshTimestamp;
		const __ = checklistState.lastUpdated;

		if (activeView === 'scanner') {
			// For scanner view, all displayed items are already non-compliant
			return section.items.length;
		} else {
			// For manual view, count items with status 'no' from the actual section data
			// The section.items already contains the correct status from backend or local state
			// Only 'no' status is non-compliant; 'yes' and 'na' are both considered compliant
			return section.items.filter((item: any) => {
				const status = item.status || 'no';
				return status === 'no';
			}).length;
		}
	}

	let nonCompliantIssuesCount = $derived(() => {
		// Force reactivity to data refresh
		const _ = dataRefreshTimestamp;

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

	// Handle intro modal flow
	function handleIntroNext() {
		if (introStep === 'welcome') {
			introStep = 'company-info';
		} else if (introStep === 'company-info') {
			introStep = 'discovery';
		}
		// Scroll to top when changing steps
		setTimeout(() => {
			if (introDialogElement) {
				introDialogElement.scrollTop = 0;
			}
		}, 50);
	}

	function handleIntroBack() {
		if (introStep === 'company-info') {
			introStep = 'welcome';
		} else if (introStep === 'discovery') {
			introStep = 'company-info';
		}
		// Scroll to top when changing steps
		setTimeout(() => {
			if (introDialogElement) {
				introDialogElement.scrollTop = 0;
			}
		}, 50);
	}

	function handleIntroComplete() {
		// Close intro modal and open scan dialog
		introDialogOpen = false;
		introStep = 'welcome'; // Reset for next time
		scanDialogOpen = true;
	}

	function handleIntroSkip() {
		// Skip directly to scan dialog
		introDialogOpen = false;
		introStep = 'welcome'; // Reset for next time
		scanDialogOpen = true;
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
			await loadTemplates(); // This now includes covered assets
			await loadCurrentChecklist(); // Reload current checklist based on business unit selection

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

	// Create refresh callback function
	async function refreshComplianceData() {
		console.log('Refreshing compliance data...');
		loadTemplates();
		await loadCurrentChecklist();
		// Update timestamp to force reactivity
		dataRefreshTimestamp = Date.now();
		console.log('Compliance data refreshed at:', dataRefreshTimestamp);
	}

	onMount(() => {
		async function init() {
			checklistState = loadChecklistState();
			await loadTemplates(); // Load templates from backend API
			await loadJsonTemplates(); // Load JSON templates data for rich guide information
			await loadCurrentChecklist(); // Load current checklist based on business unit selection

			// Register compliance refresh callback with asset store
			assetStore.registerComplianceRefreshCallback(refreshComplianceData);

			// Load assets and auto-open scan dialog if no assets exist
			await assetStore.load();

			// Check if no assets exist and auto-open intro dialog
			if (!assetStore.data?.assets || assetStore.data.assets.length === 0) {
				introDialogOpen = true;
			}
		}

		init();

		// Setup scroll listener for floating progress bar
		const handleScroll = () => {
			if (progressBarElement && activeView === 'manual') {
				const rect = progressBarElement.getBoundingClientRect();
				// Show floating progress when the original is out of view (above the viewport)
				// Account for the sticky header height (approximately 80px)
				showFloatingProgress = rect.bottom < 80;
			} else {
				showFloatingProgress = false;
			}
		};

		window.addEventListener('scroll', handleScroll);
		
		// Also check on view changes
		const checkFloatingProgress = () => {
			setTimeout(handleScroll, 100); // Small delay to ensure DOM is updated
		};

		// Cleanup function
		return () => {
			assetStore.unregisterComplianceRefreshCallback(refreshComplianceData);
			window.removeEventListener('scroll', handleScroll);
		};
	});

	// Function to handle business unit change and reload data
	async function handleBusinessUnitChange() {
		console.log('🔄 Business unit changed, reloading checklist data...');
		console.log('🏢 New business unit:', businessUnitsStore.selectedBusinessUnit?.name || 'Global');
		await loadCurrentChecklist();
		dataRefreshTimestamp = Date.now();
		console.log('🔄 Data refresh timestamp updated:', dataRefreshTimestamp);
	}

	// Reactive statement to handle view changes
	$effect(() => {
		// When activeView changes, check floating progress after a short delay
		if (typeof window !== 'undefined') {
			setTimeout(() => {
				if (progressBarElement && activeView === 'manual') {
					const rect = progressBarElement.getBoundingClientRect();
					showFloatingProgress = rect.bottom < 80;
				} else {
					showFloatingProgress = false;
				}
			}, 100);
		}
	});

	// Reactive statement to scroll to top when intro dialog opens
	$effect(() => {
		if (introDialogOpen && introDialogElement) {
			setTimeout(() => {
				if (introDialogElement) {
					introDialogElement.scrollTop = 0;
				}
			}, 100);
		}
	});
</script>

<!-- Sticky Header -->
<div class="sticky top-0 z-50 bg-background border-b border-border">
	<div class="mx-auto max-w-7xl px-4 py-4 sm:px-6 lg:px-8">
		<div class="flex items-center justify-between">
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
	</div>
</div>

<!-- Floating Progress Bar (shown when original scrolls out of view) -->
{#if showFloatingProgress && activeView === 'manual'}
	<div 
		class="fixed top-20 left-1/2 transform -translate-x-1/2 z-40 bg-background border border-border rounded-4xl shadow-md px-3 py-2 w-[20rem]"
		in:fly={{ y: -20, duration: 400, easing: quintOut }}
		out:scale={{ start: 0.95, duration: 200, easing: quintOut }}
	>
		<div class="flex items-center justify-between gap-2 mt-1">
			<span class="text-xs text-muted-foreground font-medium">
				{displaySections().reduce((acc, section) => {
					return (
						acc +
						section.items.filter(
							(item: any) => item.required && (item.status === 'yes' || item.status === 'na')
						).length
					);
				}, 0)}/{displaySections().reduce(
					(acc, section) =>
						acc + section.items.filter((item: any) => item.required).length,
					0
				)}
			</span>
			<ProgressBar value={complianceScore()} size="sm" />
			<span class="text-xs text-muted-foreground font-medium">{complianceScore()}%</span>
		</div>
		<div class="text-xs text-muted-foreground mt-1 text-center">
		</div>
	</div>
{/if}

<!-- Main Content -->
<div class="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
	<div class="mb-8">

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
					<!-- Business Unit Management Card -->
					<div class="mb-6">
						<BusinessUnitCard onBusinessUnitChange={handleBusinessUnitChange} />
					</div>
					<div bind:this={progressBarElement}>
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
											return (
												acc +
												section.items.filter(
													(item: any) => item.required && (item.status === 'yes' || item.status === 'na')
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
					</div>

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
										{@const nonCompliantCount = getNonCompliantSectionCount(section)}
										{#if nonCompliantCount > 0}
											<Badge variant="destructive" class="h-4 min-w-[16px] px-1 py-0 text-xs">
												{nonCompliantCount}
											</Badge>
										{:else}
											<Badge class="!bg-green-50 !text-green-700 !border-green-200 h-4 min-w-[16px] px-1 py-0 text-xs">
												✓
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
												businessUnitId={businessUnitsStore.selectedBusinessUnit?.id}
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
							<Button variant="outline" class="mt-4" onclick={loadTemplates}>Retry</Button>
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
							<!-- Priority Overview -->
							{#if displaySections().length > 0}
								{@const priorityCounts = displaySections().reduce((counts, section) => {
									section.items.forEach((item: any) => {
										const priority = item.priority || 'other';
										counts[priority] = (counts[priority] || 0) + 1;
									});
									return counts;
								}, {})}
								
								<div class="mb-4 grid grid-cols-2 gap-4 sm:grid-cols-4">
									{#if priorityCounts.critical > 0}
										<div class="rounded-lg border border-red-200 bg-red-50 p-3">
											<div class="text-center">
												<div class="text-2xl font-bold text-red-700">{priorityCounts.critical}</div>
												<div class="text-xs text-red-600">Critical</div>
											</div>
										</div>
									{/if}
									{#if priorityCounts.high > 0}
										<div class="rounded-lg border border-orange-200 bg-orange-50 p-3">
											<div class="text-center">
												<div class="text-2xl font-bold text-orange-700">{priorityCounts.high}</div>
												<div class="text-xs text-orange-600">High</div>
											</div>
										</div>
									{/if}
									{#if priorityCounts.medium > 0}
										<div class="rounded-lg border border-yellow-200 bg-yellow-50 p-3">
											<div class="text-center">
												<div class="text-2xl font-bold text-yellow-700">{priorityCounts.medium}</div>
												<div class="text-xs text-yellow-600">Medium</div>
											</div>
										</div>
									{/if}
									{#if priorityCounts.low > 0}
										<div class="rounded-lg border border-blue-200 bg-blue-50 p-3">
											<div class="text-center">
												<div class="text-2xl font-bold text-blue-700">{priorityCounts.low}</div>
												<div class="text-xs text-blue-600">Low</div>
											</div>
										</div>
									{/if}
									{#if priorityCounts.other > 0}
										<div class="rounded-lg border border-gray-200 bg-gray-50 p-3">
											<div class="text-center">
												<div class="text-2xl font-bold text-gray-700">{priorityCounts.other}</div>
												<div class="text-xs text-gray-600">Other</div>
											</div>
										</div>
									{/if}
								</div>
							{/if}
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
										{@const nonCompliantCount = getNonCompliantSectionCount(section)}
										{#if nonCompliantCount > 0}
											<Badge variant="destructive" class="h-4 min-w-[16px] px-1 py-0 text-xs">
												{nonCompliantCount}
											</Badge>
										{:else}
											<Badge class="!bg-green-50 !text-green-700 !border-green-200 h-4 min-w-[16px] px-1 py-0 text-xs">
												✓
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
												businessUnitId={businessUnitsStore.selectedBusinessUnit?.id}
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
							<Button variant="outline" class="mt-4" onclick={loadTemplates}>Refresh</Button>
						</div>
					{/if}
				</Tabs.Content>
			</Tabs.Root>
		</div>
	</div>
</div>

<!-- Intro Guide Dialog -->
<Dialog.Root bind:open={introDialogOpen}>
	<Dialog.Content class="max-w-2xl max-h-[90vh] overflow-y-auto" bind:this={introDialogElement}>
		{#if introStep === 'welcome'}
			<Dialog.Header>
				<Dialog.Title class="flex items-center gap-2 text-2xl">
					<Shield class="h-6 w-6 text-blue-600" />
					Welcome to RegTech Compliance
				</Dialog.Title>
				<Dialog.Description>
					Your comprehensive solution for Moldova's Cybersecurity Law compliance
				</Dialog.Description>
			</Dialog.Header>
			
			<div class="space-y-6 py-4">
				<div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
					<h3 class="font-semibold text-blue-900 mb-2">About Moldova's Cybersecurity Law</h3>
					<p class="text-blue-800 text-sm leading-relaxed">
						The Republic of Moldova's Cybersecurity Law establishes comprehensive requirements for organizations to protect their digital infrastructure and sensitive data. This law mandates specific security measures, incident reporting procedures, and compliance documentation.
					</p>
				</div>

				<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
					<div class="border rounded-lg p-4">
						<div class="flex items-center gap-2 mb-2">
							<CheckCircle class="h-5 w-5 text-green-600" />
							<h4 class="font-medium">Automated Scanning</h4>
						</div>
						<p class="text-sm text-muted-foreground">
							Our platform automatically scans your infrastructure to identify potential compliance gaps and security vulnerabilities.
						</p>
					</div>

					<div class="border rounded-lg p-4">
						<div class="flex items-center gap-2 mb-2">
							<CheckCircle class="h-5 w-5 text-green-600" />
							<h4 class="font-medium">Manual Compliance</h4>
						</div>
						<p class="text-sm text-muted-foreground">
							Track manual compliance requirements with guided checklists, documentation templates, and progress monitoring.
						</p>
					</div>

					<div class="border rounded-lg p-4">
						<div class="flex items-center gap-2 mb-2">
							<CheckCircle class="h-5 w-5 text-green-600" />
							<h4 class="font-medium">Reporting & Export</h4>
						</div>
						<p class="text-sm text-muted-foreground">
							Generate comprehensive compliance reports and export documentation for regulatory submissions.
						</p>
					</div>

					<div class="border rounded-lg p-4">
						<div class="flex items-center gap-2 mb-2">
							<CheckCircle class="h-5 w-5 text-green-600" />
							<h4 class="font-medium">Continuous Monitoring</h4>
						</div>
						<p class="text-sm text-muted-foreground">
							Stay up-to-date with ongoing compliance monitoring and alerts for any changes in your security posture.
						</p>
					</div>
				</div>

				<div class="bg-amber-50 border border-amber-200 rounded-lg p-4">
					<h4 class="font-medium text-amber-900 mb-1">Getting Started</h4>
					<p class="text-amber-800 text-sm">
						We'll collect some basic information about your organization and then help you discover your digital assets to begin the compliance assessment.
					</p>
				</div>
			</div>

			<Dialog.Footer class="flex justify-between">
				<Button variant="outline" onclick={handleIntroSkip}>
					Skip Introduction
				</Button>
				<Button onclick={handleIntroNext} class="flex items-center gap-2">
					Get Started
					<ArrowRight class="h-4 w-4" />
				</Button>
			</Dialog.Footer>

		{:else if introStep === 'company-info'}
			<Dialog.Header>
				<Dialog.Title class="flex items-center gap-2 text-xl">
					<Building class="h-5 w-5 text-blue-600" />
					Company Information
				</Dialog.Title>
				<Dialog.Description>
					Help us customize the compliance experience for your organization
				</Dialog.Description>
			</Dialog.Header>

			<div class="space-y-4 py-4">
				<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
					<div class="space-y-2">
						<Label for="company-name">Company Name</Label>
						<Input
							id="company-name"
							bind:value={companyInfo.name}
							placeholder="Enter your company name"
						/>
					</div>

					<div class="space-y-2">
						<Label for="industry">Industry</Label>
						<Input
							id="industry"
							bind:value={companyInfo.industry}
							placeholder="e.g., Financial Services, Healthcare"
						/>
					</div>
				</div>

				<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
					<div class="space-y-2">
						<Label for="employees">Number of Employees</Label>
						<Select.Root>
							<Select.Trigger>
								<Select.Value placeholder="Select employee count" />
							</Select.Trigger>
							<Select.Content>
								<Select.Item value="1-10">1-10 employees</Select.Item>
								<Select.Item value="11-50">11-50 employees</Select.Item>
								<Select.Item value="51-200">51-200 employees</Select.Item>
								<Select.Item value="201-500">201-500 employees</Select.Item>
								<Select.Item value="500+">500+ employees</Select.Item>
							</Select.Content>
						</Select.Root>
					</div>

					<div class="space-y-2">
						<Label for="turnover">Annual Turnover (EUR)</Label>
						<Select.Root>
							<Select.Trigger>
								<Select.Value placeholder="Select turnover range" />
							</Select.Trigger>
							<Select.Content>
								<Select.Item value="under-100k">Under €100,000</Select.Item>
								<Select.Item value="100k-500k">€100,000 - €500,000</Select.Item>
								<Select.Item value="500k-2m">€500,000 - €2,000,000</Select.Item>
								<Select.Item value="2m-10m">€2,000,000 - €10,000,000</Select.Item>
								<Select.Item value="over-10m">Over €10,000,000</Select.Item>
							</Select.Content>
						</Select.Root>
					</div>
				</div>

				<div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
					<div class="flex items-start gap-2">
						<TrendingUp class="h-5 w-5 text-blue-600 mt-0.5 flex-shrink-0" />
						<div>
							<h4 class="font-medium text-blue-900 mb-1">Why we collect this information</h4>
							<p class="text-blue-800 text-sm">
								This information helps us tailor compliance requirements and recommendations specific to your organization's size and industry. All data is stored securely and used only to enhance your compliance experience.
							</p>
						</div>
					</div>
				</div>
			</div>

			<Dialog.Footer class="flex justify-between">
				<Button variant="outline" onclick={handleIntroBack} class="flex items-center gap-2">
					<ArrowLeft class="h-4 w-4" />
					Back
				</Button>
				<Button onclick={handleIntroNext} class="flex items-center gap-2">
					Continue
					<ArrowRight class="h-4 w-4" />
				</Button>
			</Dialog.Footer>

		{:else if introStep === 'discovery'}
			<Dialog.Header>
				<Dialog.Title class="flex items-center gap-2 text-xl">
					<Radar class="h-5 w-5 text-blue-600" />
					Asset Discovery
				</Dialog.Title>
				<Dialog.Description>
					Let's discover your digital assets to begin the compliance assessment
				</Dialog.Description>
			</Dialog.Header>

			<div class="space-y-4 py-4">
				<div class="bg-green-50 border border-green-200 rounded-lg p-4">
					<h4 class="font-medium text-green-900 mb-2">Ready to Start!</h4>
					<p class="text-green-800 text-sm mb-3">
						We'll now scan your network to discover servers, services, and potential security issues. This helps us provide accurate compliance recommendations.
					</p>
					<div class="text-green-700 text-sm">
						<strong>Company:</strong> {companyInfo.name || 'Not specified'}<br>
						<strong>Industry:</strong> {companyInfo.industry || 'Not specified'}
					</div>
				</div>

				<div class="border rounded-lg p-4">
					<h4 class="font-medium mb-2">What happens next?</h4>
					<ul class="text-sm text-muted-foreground space-y-1">
						<li>• Enter your domains and IP addresses for scanning</li>
						<li>• Our platform will discover active services and potential vulnerabilities</li>
						<li>• Review automated compliance findings and manual checklist items</li>
						<li>• Generate reports and track your compliance progress</li>
					</ul>
				</div>
			</div>

			<Dialog.Footer class="flex justify-between">
				<Button variant="outline" onclick={handleIntroBack} class="flex items-center gap-2">
					<ArrowLeft class="h-4 w-4" />
					Back
				</Button>
				<Button onclick={handleIntroComplete} class="flex items-center gap-2">
					Start Asset Discovery
					<Radar class="h-4 w-4" />
				</Button>
			</Dialog.Footer>
		{/if}
	</Dialog.Content>
</Dialog.Root>

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
