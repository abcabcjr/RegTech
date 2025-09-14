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

			// Debug: Log the data being exported
			console.log('Export data:', { complianceItems, scannedIssues });
			console.log('Compliance items count:', complianceItems.length);
			console.log('Scanned issues count:', scannedIssues.length);
			
			// Debug asset data structure
			if (scannedIssues.length > 0 && scannedIssues[0].items.length > 0) {
				console.log('Sample scanned item:', scannedIssues[0].items[0]);
				if (scannedIssues[0].items[0].coveredAssets) {
					console.log('Sample covered assets:', scannedIssues[0].items[0].coveredAssets);
				}
			}

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

			// Generate PDF using the same method as incident reports
			const printWindow = window.open('', '_blank');
			if (printWindow) {
				const formatDate = (dateStr: string) => {
					return new Date(dateStr).toLocaleString();
				};

				const formatBadge = (status: string) => {
					const variants = {
						'yes': 'background: #dcfce7; color: #166534; padding: 4px 8px; border-radius: 4px; font-size: 12px;',
						'no': 'background: #fef2f2; color: #dc2626; padding: 4px 8px; border-radius: 4px; font-size: 12px;',
						'na': 'background: #f3f4f6; color: #374151; padding: 4px 8px; border-radius: 4px; font-size: 12px;'
					};
					return variants[status as keyof typeof variants] || variants.no;
				};

				const getStatusText = (status: string) => {
					const statusMap = {
						'yes': 'COMPLIANT',
						'no': 'NON-COMPLIANT', 
						'na': 'NOT APPLICABLE'
					};
					return statusMap[status as keyof typeof statusMap] || 'NON-COMPLIANT';
				};

				const getPriorityText = (priority: string, priority_number?: number) => {
					if (priority_number) {
						return priority ? `${priority.toUpperCase()} (P${priority_number})` : 'NORMAL';
					}
					return priority ? priority.toUpperCase() : 'NORMAL';
				};

				const formatAssetInfo = (asset: any) => {
					// Handle different asset data structures
					const value = asset?.asset_value || asset?.value || asset?.name || 'Unknown Asset';
					const type = asset?.asset_type || asset?.type || 'unknown';
					const status = asset?.compliance_status || asset?.status || 'unknown';
					
					return `${value} (${type}) - Status: ${status}`;
				};

				// Generate compliance items HTML
				const complianceItemsHTML = complianceItems.map(section => `
					<div class="section">
						<h3>${section.section}</h3>
						${section.items.map(item => `
							<div class="item">
								<div class="item-header">
									<h4>${item.title}</h4>
									<div class="badges">
										<span class="status-badge" style="${formatBadge(item.status || 'no')}">${getStatusText(item.status || 'no')}</span>
										${item.info?.priority ? `<span class="priority-badge">${getPriorityText(item.info.priority, item.info.priority_number)}</span>` : ''}
									</div>
								</div>
								<p class="description">${item.description || ''}</p>
								${item.info?.whatItMeans ? `<div class="info-section"><strong>What it means:</strong> ${item.info.whatItMeans}</div>` : ''}
								${item.info?.whyItMatters ? `<div class="info-section"><strong>Why it matters:</strong> ${item.info.whyItMatters}</div>` : ''}
								${item.notes ? `<div class="notes"><strong>Notes:</strong> ${item.notes}</div>` : ''}
								${item.recommendation ? `<div class="recommendation"><strong>Recommendation:</strong> ${item.recommendation}</div>` : ''}
								${item.info?.lawRefs && item.info.lawRefs.length > 0 ? `<div class="law-refs"><strong>Legal References:</strong> ${item.info.lawRefs.join(', ')}</div>` : ''}
							</div>
						`).join('')}
					</div>
				`).join('');

				// Generate scanned issues HTML
				const scannedIssuesHTML = scannedIssues.map(section => `
					<div class="section">
						<h3>${section.section}</h3>
						${section.items.map(item => `
							<div class="item">
								<div class="item-header">
									<h4>${item.title}</h4>
									<div class="badges">
										<span class="status-badge" style="${formatBadge('no')}">SECURITY ISSUE</span>
										${item.info?.priority ? `<span class="priority-badge priority-${item.info.priority.toLowerCase()}">${getPriorityText(item.info.priority, item.info.priority_number)}</span>` : ''}
									</div>
								</div>
								<p class="description">${item.description || ''}</p>
								${item.info?.whatItMeans ? `<div class="info-section"><strong>What it means:</strong> ${item.info.whatItMeans}</div>` : ''}
								${item.info?.whyItMatters ? `<div class="info-section"><strong>Why it matters:</strong> ${item.info.whyItMatters}</div>` : ''}
								${item.coveredAssets && item.coveredAssets.length > 0 ? `
									<div class="assets">
										<strong>Affected Assets (${item.coveredAssets.length}):</strong>
										<ul>
											${item.coveredAssets.map((asset: any) => `
												<li>${formatAssetInfo(asset)}</li>
											`).join('')}
										</ul>
									</div>
								` : ''}
								${item.recommendation ? `<div class="recommendation"><strong>Recommendation:</strong> ${item.recommendation}</div>` : ''}
								${item.info?.lawRefs && item.info.lawRefs.length > 0 ? `<div class="law-refs"><strong>Legal References:</strong> ${item.info.lawRefs.join(', ')}</div>` : ''}
							</div>
						`).join('')}
					</div>
				`).join('');

				printWindow.document.write(`
					<!DOCTYPE html>
					<html>
						<head>
							<title>Compliance Report - ${organizationName.trim()}</title>
							<style>
								body {
									font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
									line-height: 1.6;
									color: #374151;
									max-width: 800px;
									margin: 0 auto;
									padding: 20px;
									background: white;
								}
								
								.header {
									border-bottom: 2px solid #e5e7eb;
									padding-bottom: 20px;
									margin-bottom: 30px;
								}
								
								.header h1 {
									color: #111827;
									margin: 0 0 10px 0;
									font-size: 28px;
									font-weight: 700;
								}
								
								.header-info {
									display: flex;
									justify-content: space-between;
									align-items: center;
									flex-wrap: wrap;
									gap: 10px;
								}
								
								.meta-info {
									color: #6b7280;
									font-size: 14px;
								}
								
								.summary-stats {
									background: #f9fafb;
									padding: 20px;
									border-radius: 8px;
									border: 1px solid #e5e7eb;
									margin-bottom: 30px;
									display: grid;
									grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
									gap: 15px;
								}
								
								.stat {
									text-align: center;
								}
								
								.stat-value {
									font-size: 24px;
									font-weight: 700;
									color: #111827;
								}
								
								.stat-label {
									color: #6b7280;
									font-size: 14px;
								}
								
								.section {
									margin-bottom: 40px;
									break-inside: avoid;
								}
								
								.section h2 {
									color: #111827;
									font-size: 24px;
									font-weight: 600;
									margin: 0 0 20px 0;
									border-bottom: 1px solid #e5e7eb;
									padding-bottom: 10px;
								}
								
								.section h3 {
									color: #374151;
									font-size: 18px;
									font-weight: 600;
									margin: 20px 0 15px 0;
								}
								
								.item {
									background: white;
									border: 1px solid #e5e7eb;
									border-radius: 8px;
									padding: 15px;
									margin-bottom: 15px;
									break-inside: avoid;
								}
								
								.item-header {
									display: flex;
									justify-content: space-between;
									align-items: flex-start;
									margin-bottom: 10px;
									gap: 10px;
								}
								
								.item h4 {
									color: #111827;
									font-size: 16px;
									font-weight: 600;
									margin: 0;
									flex: 1;
								}
								
								.badges {
									display: flex;
									gap: 8px;
									flex-wrap: wrap;
								}
								
								.status-badge {
									font-weight: 500;
									text-transform: uppercase;
									white-space: nowrap;
								}
								
								.priority-badge {
									font-weight: 500;
									text-transform: uppercase;
									white-space: nowrap;
									padding: 4px 8px;
									border-radius: 4px;
									font-size: 12px;
									background: #f3f4f6;
									color: #374151;
								}
								
								.priority-badge.priority-critical {
									background: #fef2f2;
									color: #dc2626;
								}
								
								.priority-badge.priority-high {
									background: #fed7aa;
									color: #c2410c;
								}

								.priority-badge.priority-medium {
									background: #fef3c7;
									color: #d97706;
								}

								.priority-badge.priority-low {
									background: #dcfce7;
									color: #166534;
								}
								
								.info-section {
									background: #eff6ff;
									padding: 10px;
									border-radius: 4px;
									margin: 10px 0;
									font-size: 14px;
									border-left: 3px solid #3b82f6;
								}
								
								.law-refs {
									background: #f0f9ff;
									padding: 10px;
									border-radius: 4px;
									margin: 10px 0;
									font-size: 14px;
									border-left: 3px solid #0ea5e9;
								}
								
								.description {
									color: #6b7280;
									margin: 10px 0;
									font-size: 14px;
								}
								
								.notes, .recommendation, .assets {
									background: #f9fafb;
									padding: 10px;
									border-radius: 4px;
									margin: 10px 0;
									font-size: 14px;
								}
								
								.assets ul {
									margin: 5px 0 0 20px;
									padding: 0;
								}
								
								.assets li {
									margin: 2px 0;
								}
								
								.footer {
									text-align: center;
									margin-top: 40px;
									padding-top: 20px;
									border-top: 1px solid #e5e7eb;
									color: #6b7280;
									font-size: 12px;
								}
								
								@media print {
									body { margin: 0; padding: 15px; }
									.section { page-break-inside: avoid; }
									.item { page-break-inside: avoid; }
								}
							</style>
						</head>
						<body>
							<div class="header">
								<h1>Compliance Report</h1>
								<div class="header-info">
									<div class="meta-info">
										<strong>${organizationName.trim()}</strong><br>
										Generated: ${exportData.exportDate}
									</div>
								</div>
							</div>
							
							<div class="summary-stats">
								<div class="stat">
									<div class="stat-value">${complianceScore}%</div>
									<div class="stat-label">Compliance Score</div>
								</div>
								<div class="stat">
									<div class="stat-value">${completedItems}</div>
									<div class="stat-label">Completed Items</div>
								</div>
								<div class="stat">
									<div class="stat-value">${totalComplianceItems}</div>
									<div class="stat-label">Total Items</div>
								</div>
								<div class="stat">
									<div class="stat-value">${totalScannedIssues}</div>
									<div class="stat-label">Security Issues</div>
								</div>
							</div>
							
							${complianceItems.length > 0 ? `
								<div class="section">
									<h2>Manual Compliance Items</h2>
									${complianceItemsHTML}
								</div>
							` : ''}
							
							${scannedIssues.length > 0 ? `
								<div class="section">
									<h2>Automated Security Issues</h2>
									${scannedIssuesHTML}
								</div>
							` : ''}
							
							<div class="footer">
								Generated on ${new Date().toLocaleString()}<br>
								RegTech Compliance Management System
							</div>
						</body>
					</html>
				`);
				printWindow.document.close();
				
				printWindow.print();
			}

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
