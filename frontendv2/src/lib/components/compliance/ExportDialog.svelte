<script lang="ts">
	import { onMount } from 'svelte';
	import * as Dialog from '$lib/components/ui/dialog';
	import { Button } from '$lib/components/ui/button';
	import { Input } from '$lib/components/ui/input';
	import { Label } from '$lib/components/ui/label';
	import { getOrganizationName, saveOrganizationName } from '$lib/utils/organization';
	import type { ChecklistItem } from '$lib/types';
	import { Download, Building } from '@lucide/svelte';

	// Props
	let { 
		open = $bindable(false),
		complianceItems = [],
		scannedIssues = []
	}: {
		open: boolean;
		complianceItems: Array<{section: string; items: ChecklistItem[]}>;
		scannedIssues: Array<{section: string; items: ChecklistItem[]}>;
	} = $props();

	// State
	let organizationName: string = $state('');
	let isExporting: boolean = $state(false);
	let exportError: string | null = $state(null);

	// Load organization name from local storage on mount
	onMount(() => {
		const savedName = getOrganizationName();
		if (savedName) {
			organizationName = savedName;
		}
	});

	async function handleExport() {
		if (!organizationName.trim()) {
			exportError = 'Please enter an organization name';
			return;
		}

		try {
			isExporting = true;
			exportError = null;

			// Save organization name to local storage
			saveOrganizationName(organizationName.trim());

			// Prepare export data
			const exportData = {
				organizationName: organizationName.trim(),
				complianceItems,
				scannedIssues,
				exportDate: new Date().toLocaleDateString('en-US', {
					year: 'numeric',
					month: 'long',
					day: 'numeric',
					hour: '2-digit',
					minute: '2-digit'
				})
			};

			// Generate PDF


			// Close dialog on success
			open = false;
		} catch (error) {
			console.error('Export failed:', error);
			exportError = error instanceof Error ? error.message : 'Export failed. Please try again.';
		} finally {
			isExporting = false;
		}
	}

	function handleCancel() {
		open = false;
		exportError = null;
	}

	// Calculate summary stats
	let totalComplianceItems = $derived(complianceItems.reduce((acc, section) => acc + section.items.length, 0));
	let completedItems = $derived(complianceItems.reduce((acc, section) => 
		acc + section.items.filter(item => item.status === 'yes').length, 0
	));
	let totalScannedIssues = $derived(scannedIssues.reduce((acc, section) => acc + section.items.length, 0));
	let complianceScore = $derived(totalComplianceItems > 0 ? Math.round((completedItems / totalComplianceItems) * 100) : 0);
</script>

<Dialog.Root bind:open>
	<Dialog.Content class="max-w-md">
		<Dialog.Header>
			<Dialog.Title class="flex items-center gap-2">
				<Download class="h-5 w-5" />
				Export Compliance Report
			</Dialog.Title>
			<Dialog.Description>
				Generate a professional PDF report with CyberCare branding containing your compliance checklist and security issues.
			</Dialog.Description>
		</Dialog.Header>

		<div class="space-y-4">
			<!-- Organization Name Input -->
			<div class="space-y-2">
				<Label for="organization-name" class="flex items-center gap-2">
					<Building class="h-4 w-4" />
					Organization Name
				</Label>
				<Input
					id="organization-name"
					bind:value={organizationName}
					placeholder="Enter your organization name"
					disabled={isExporting}
					class="w-full"
				/>
				<p class="text-sm text-muted-foreground">
					This will be saved for future exports
				</p>
			</div>

			<!-- Export Summary -->
			<div class="bg-muted/30 p-4 rounded-lg space-y-2">
				<h4 class="font-medium text-sm">Export Summary</h4>
				<div class="grid grid-cols-2 gap-2 text-sm">
					<div>
						<span class="text-muted-foreground">Compliance Items:</span>
						<span class="font-medium ml-1">{totalComplianceItems}</span>
					</div>
					<div>
						<span class="text-muted-foreground">Completed:</span>
						<span class="font-medium ml-1">{completedItems}</span>
					</div>
					<div>
						<span class="text-muted-foreground">Compliance Score:</span>
						<span class="font-medium ml-1">{complianceScore}%</span>
					</div>
					<div>
						<span class="text-muted-foreground">Scanned Issues:</span>
						<span class="font-medium ml-1">{totalScannedIssues}</span>
					</div>
				</div>
			</div>

			<!-- Error Message -->
			{#if exportError}
				<div class="bg-red-50 border border-red-200 rounded-md p-3">
					<div class="flex items-center">
						<svg class="h-4 w-4 text-red-600 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
							<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
						</svg>
						<span class="text-red-800 text-sm">{exportError}</span>
					</div>
				</div>
			{/if}
		</div>

		<Dialog.Footer class="flex gap-2">
			<Button variant="outline" onclick={handleCancel} disabled={isExporting}>
				Cancel
			</Button>
			<Button onclick={handleExport} disabled={isExporting || !organizationName.trim()}>
				{#if isExporting}
					<div class="animate-spin rounded-full h-4 w-4 border-b-2 border-current mr-2"></div>
					Generating PDF...
				{:else}
					<Download class="h-4 w-4 mr-2" />
					Export PDF
				{/if}
			</Button>
		</Dialog.Footer>
	</Dialog.Content>
</Dialog.Root>
