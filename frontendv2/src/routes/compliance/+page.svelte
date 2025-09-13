<script lang="ts">
	import { onMount } from 'svelte';
	import { checklistStore } from '$lib/stores/checklist.svelte';
	import { assetStore } from '$lib/stores/assets.svelte';
	import type { ModelDerivedChecklistItem, V1AssetSummary } from '$lib/api/Api';
	import { Button } from '$lib/components/ui/button';
	import * as Card from '$lib/components/ui/card';
	import * as Tabs from '$lib/components/ui/tabs';
	import { Progress } from '$lib/components/ui/progress';
	import { Input } from '$lib/components/ui/input';
	import * as Alert from '$lib/components/ui/alert';

	let globalItems: ModelDerivedChecklistItem[] = $state([]);
	let assetComplianceMap: Record<string, ModelDerivedChecklistItem[]> = $state({});
	let assets: V1AssetSummary[] = $state([]);
	let loading = $state(true);
	
	// File upload state
	let fileInput: HTMLInputElement;
	let uploadMessage = $state('');
	let uploadError = $state('');
	let uploading = $state(false);

	// Computed compliance statistics
	let globalStats = $derived(() => {
		const total = globalItems.length;
		const passed = globalItems.filter(item => item.status === 'yes').length;
		const failed = globalItems.filter(item => item.status === 'no').length;
		const na = globalItems.filter(item => item.status === 'na').length;
		const required = globalItems.filter(item => item.required).length;
		const requiredPassed = globalItems.filter(item => item.required && item.status === 'yes').length;
		
		return {
			total,
			passed,
			failed,
			na,
			required,
			requiredPassed,
			passRate: total > 0 ? Math.round((passed / total) * 100) : 0,
			requiredPassRate: required > 0 ? Math.round((requiredPassed / required) * 100) : 0
		};
	});

	let assetStats = $derived(() => {
		const assetTypes = ['domain', 'subdomain', 'ip', 'service'];
		const stats: Record<string, any> = {};
		
		assetTypes.forEach(type => {
			const typeAssets = assets.filter(a => a.type === type);
			const totalAssets = typeAssets.length;
			let totalItems = 0;
			let passedItems = 0;
			let requiredItems = 0;
			let requiredPassedItems = 0;
			
			typeAssets.forEach(asset => {
				const items = assetComplianceMap[asset.id] || [];
				totalItems += items.length;
				passedItems += items.filter(item => item.status === 'yes').length;
				requiredItems += items.filter(item => item.required).length;
				requiredPassedItems += items.filter(item => item.required && item.status === 'yes').length;
			});
			
			stats[type] = {
				totalAssets,
				totalItems,
				passedItems,
				requiredItems,
				requiredPassedItems,
				passRate: totalItems > 0 ? Math.round((passedItems / totalItems) * 100) : 0,
				requiredPassRate: requiredItems > 0 ? Math.round((requiredPassedItems / requiredItems) * 100) : 0
			};
		});
		
		return stats;
	});

	let overallStats = $derived(() => {
		const totalGlobalPassed = globalStats().passed;
		const totalGlobalItems = globalStats().total;
		
		let totalAssetItems = 0;
		let totalAssetPassed = 0;
		
		Object.values(assetComplianceMap).forEach(items => {
			totalAssetItems += items.length;
			totalAssetPassed += items.filter(item => item.status === 'yes').length;
		});
		
		const grandTotal = totalGlobalItems + totalAssetItems;
		const grandPassed = totalGlobalPassed + totalAssetPassed;
		
		return {
			grandTotal,
			grandPassed,
			overallPassRate: grandTotal > 0 ? Math.round((grandPassed / grandTotal) * 100) : 0
		};
	});

	async function loadComplianceData() {
		loading = true;
		try {
			// Load global checklist items
			await checklistStore.loadGlobal();
			globalItems = checklistStore.globalItems;

			// Load assets
			await assetStore.load();
			assets = assetStore.data?.assets || [];

			// Load asset-specific checklist items for each asset
			const assetPromises = assets.map(async (asset) => {
				const items = await checklistStore.getAssetItems(asset.id);
				assetComplianceMap[asset.id] = items;
			});
			
			await Promise.all(assetPromises);
		} catch (error) {
			console.error('Failed to load compliance data:', error);
		} finally {
			loading = false;
		}
	}

	function getStatusColor(status?: string): string {
		return checklistStore.getStatusColor(status);
	}

	function getStatusLabel(status?: string): string {
		return checklistStore.getStatusLabel(status);
	}

	async function updateGlobalItemStatus(itemId: string, status: 'yes' | 'no' | 'na') {
		try {
			await checklistStore.setStatus(itemId, '', status, '');
			// Create a new array to trigger reactivity
			globalItems = [...checklistStore.globalItems];
		} catch (error) {
			console.error('Failed to update global item status:', error);
		}
	}

	async function updateAssetItemStatus(assetId: string, itemId: string, status: 'yes' | 'no' | 'na') {
		try {
			await checklistStore.setAssignment({
				item_id: itemId,
				scope: 'asset',
				asset_id: assetId,
				status: status,
				notes: ''
			});
			// Reload asset items to reflect the change
			const items = await checklistStore.getAssetItems(assetId);
			// Create a new object to trigger reactivity
			assetComplianceMap = { ...assetComplianceMap, [assetId]: [...items] };
		} catch (error) {
			console.error('Failed to update asset item status:', error);
		}
	}

	// Handle file upload
	async function handleFileUpload(event: Event) {
		console.log('File upload triggered');
		const target = event.target as HTMLInputElement;
		const file = target.files?.[0];
		
		console.log('Selected file:', file);
		if (!file) return;
		
		uploadMessage = '';
		uploadError = '';
		uploading = true;
		
		try {
			console.log('Reading file...');
			const text = await file.text();
			console.log('File content:', text.substring(0, 200) + '...');
			
			const data = JSON.parse(text);
			console.log('Parsed data:', data);
			
			// Validate that it's an array of templates
			if (!Array.isArray(data.templates) && !Array.isArray(data)) {
				throw new Error('Invalid JSON format. Expected an array of templates or an object with a "templates" array.');
			}
			
			const templates = Array.isArray(data) ? data : data.templates;
			console.log('Templates to upload:', templates.length);
			
			// Validate template structure
			for (const template of templates) {
				if (!template.id || !template.title || !template.scope) {
					throw new Error('Invalid template structure. Each template must have id, title, and scope.');
				}
			}
			
			console.log('Calling uploadTemplates...');
			const result = await checklistStore.uploadTemplates(templates);
			console.log('Upload result:', result);
			
			uploadMessage = `Successfully uploaded ${result.count || templates.length} templates!`;
			
			// Reload compliance data
			await loadComplianceData();
			
		} catch (error) {
			console.error('Upload error:', error);
			uploadError = error instanceof Error ? error.message : 'Failed to upload templates';
		} finally {
			uploading = false;
			// Clear the file input
			if (fileInput) {
				fileInput.value = '';
			}
		}
	}

	onMount(() => {
		loadComplianceData();
	});
</script>

<div class="container mx-auto px-4 py-8 max-w-7xl">
	<div class="mb-8">
		<div class="flex justify-between items-start mb-4">
			<div>
				<h1 class="text-3xl font-bold text-gray-900 mb-2">Compliance Overview</h1>
				<p class="text-gray-600">
					Monitor your organization's compliance posture across global policies and asset-specific requirements.
				</p>
			</div>
			
			<!-- File Upload Section -->
			<div class="flex flex-col items-end space-y-2">
				<div class="flex items-center space-x-2">
					<input
						bind:this={fileInput}
						type="file"
						accept=".json"
						onchange={handleFileUpload}
						disabled={uploading}
						class="hidden"
						id="file-upload"
					/>
					<Button 
						disabled={uploading} 
						variant="outline"
						onclick={() => {
							console.log('Button clicked');
							const input = document.getElementById('file-upload') as HTMLInputElement;
							console.log('Input element:', input);
							input?.click();
						}}
					>
						{uploading ? 'Uploading...' : 'Choose JSON File'}
					</Button>
				</div>
				
				{#if uploadMessage}
					<Alert.Root class="w-80">
						<Alert.Description class="text-green-600">
							{uploadMessage}
						</Alert.Description>
					</Alert.Root>
				{/if}
				
				{#if uploadError}
					<Alert.Root class="w-80" variant="destructive">
						<Alert.Description>
							{uploadError}
						</Alert.Description>
					</Alert.Root>
				{/if}
			</div>
		</div>
	</div>

	{#if loading}
		<div class="flex items-center justify-center py-12">
			<div class="text-gray-500">Loading compliance data...</div>
		</div>
	{:else}
		<!-- Overall Compliance Dashboard -->
		<div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
			<Card.Root>
				<Card.Header>
					<Card.Title class="text-lg">Overall Compliance</Card.Title>
					<Card.Description>Across all global and asset-specific checks</Card.Description>
				</Card.Header>
				<Card.Content>
					<div class="text-3xl font-bold text-blue-600 mb-2">{overallStats().overallPassRate}%</div>
					<Progress value={overallStats().overallPassRate} class="mb-2" />
					<div class="text-sm text-gray-600">
						{overallStats().grandPassed} of {overallStats().grandTotal} checks passed
					</div>
				</Card.Content>
			</Card.Root>

			<Card.Root>
				<Card.Header>
					<Card.Title class="text-lg">Global Compliance</Card.Title>
					<Card.Description>Organization-wide policies</Card.Description>
				</Card.Header>
				<Card.Content>
					<div class="text-3xl font-bold text-green-600 mb-2">{globalStats().passRate}%</div>
					<Progress value={globalStats().passRate} class="mb-2" />
					<div class="text-sm text-gray-600">
						{globalStats().passed} of {globalStats().total} global checks passed
					</div>
					{#if globalStats().required > 0}
						<div class="text-xs text-gray-500 mt-1">
							Required: {globalStats().requiredPassed}/{globalStats().required} ({globalStats().requiredPassRate}%)
						</div>
					{/if}
				</Card.Content>
			</Card.Root>

			<Card.Root>
				<Card.Header>
					<Card.Title class="text-lg">Asset Coverage</Card.Title>
					<Card.Description>Assets with compliance data</Card.Description>
				</Card.Header>
				<Card.Content>
					<div class="text-3xl font-bold text-purple-600 mb-2">{assets.length}</div>
					<div class="text-sm text-gray-600 mb-2">Total assets monitored</div>
					<div class="text-xs text-gray-500">
						{Object.keys(assetComplianceMap).length} assets have checklist items
					</div>
				</Card.Content>
			</Card.Root>
		</div>

		<Tabs.Root value="global" class="w-full">
			<Tabs.List class="grid w-full grid-cols-3">
				<Tabs.Trigger value="global">Global Checklist</Tabs.Trigger>
				<Tabs.Trigger value="assets">Asset Compliance</Tabs.Trigger>
				<Tabs.Trigger value="summary">Summary by Type</Tabs.Trigger>
			</Tabs.List>

			<!-- Global Checklist Tab -->
			<Tabs.Content value="global" class="mt-6">
				<Card.Root>
					<Card.Header>
						<Card.Title>Global Compliance Items</Card.Title>
						<Card.Description>
							Organization-wide compliance requirements that apply to your entire infrastructure.
						</Card.Description>
					</Card.Header>
					<Card.Content>
						{#if globalItems.length > 0}
							<div class="space-y-4">
								{#each globalItems as item (item.id)}
									<div class="border border-gray-200 rounded-lg p-4 bg-white">
										<div class="flex items-start justify-between mb-2">
											<div class="flex-1">
												<div class="flex items-center gap-2 mb-1">
													<span class="font-medium text-gray-900">{item.title}</span>
													<span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium {getStatusColor(item.status)}">
														{getStatusLabel(item.status)}
													</span>
													<span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-blue-50 text-blue-700 border border-blue-200">
														{checklistStore.getSourceLabel(item.source)}
													</span>
													{#if item.required}
														<span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-orange-50 text-orange-700 border border-orange-200">
															Required
														</span>
													{/if}
												</div>
												{#if item.category}
													<div class="text-xs text-gray-500 mb-2">{item.category}</div>
												{/if}
											</div>
											{#if item.source === 'manual'}
												<div class="flex gap-2">
													<Button 
														size="sm" 
														variant={item.status === 'yes' ? 'default' : 'outline'}
														onclick={() => updateGlobalItemStatus(item.id || '', 'yes')}
													>
														Yes
													</Button>
													<Button 
														size="sm" 
														variant={item.status === 'no' ? 'default' : 'outline'}
														onclick={() => updateGlobalItemStatus(item.id || '', 'no')}
													>
														No
													</Button>
													<Button 
														size="sm" 
														variant={item.status === 'na' ? 'default' : 'outline'}
														onclick={() => updateGlobalItemStatus(item.id || '', 'na')}
													>
														N/A
													</Button>
												</div>
											{/if}
										</div>
										{#if item.description}
											<div class="text-sm text-gray-600 mb-2">{item.description}</div>
										{/if}
										{#if item.notes}
											<div class="text-sm text-gray-700 mb-2">
												<span class="font-medium">Notes:</span> {item.notes}
											</div>
										{/if}
										{#if item.recommendation}
											<div class="text-sm text-gray-700">
												<span class="font-medium">Recommendation:</span> {item.recommendation}
											</div>
										{/if}
									</div>
								{/each}
							</div>
						{:else}
							<div class="text-center py-8 text-gray-500">
								No global checklist items found. Create templates to get started.
							</div>
						{/if}
					</Card.Content>
				</Card.Root>
			</Tabs.Content>

			<!-- Asset Compliance Tab -->
			<Tabs.Content value="assets" class="mt-6">
				<Card.Root>
					<Card.Header>
						<Card.Title>Asset-Specific Compliance</Card.Title>
						<Card.Description>
							Compliance status for individual assets in your infrastructure.
						</Card.Description>
					</Card.Header>
					<Card.Content>
						{#if assets.length > 0}
							<div class="space-y-4">
								{#each assets as asset (asset.id)}
									{@const items = assetComplianceMap[asset.id] || []}
									{#if items.length > 0}
										<div class="border border-gray-200 rounded-lg p-4 bg-white">
											<div class="flex items-center justify-between mb-3">
												<div>
													<div class="font-medium text-gray-900">{asset.value}</div>
													<div class="text-sm text-gray-500">{asset.type.toUpperCase()} • {asset.id}</div>
												</div>
												<div class="text-right">
													<div class="text-sm font-medium">
														{items.filter(i => i.status === 'yes').length}/{items.length} passed
													</div>
													<div class="text-xs text-gray-500">
														{Math.round((items.filter(i => i.status === 'yes').length / items.length) * 100)}% compliance
													</div>
												</div>
											</div>
											<div class="space-y-2">
												{#each items as item (item.id)}
													<div class="flex items-center justify-between py-2 px-3 bg-gray-50 rounded">
														<div class="flex items-center gap-2">
															<span class="text-sm font-medium">{item.title}</span>
															{#if item.required}
																<span class="inline-flex items-center px-1.5 py-0.5 rounded text-xs font-medium bg-orange-100 text-orange-700">
																	Required
																</span>
															{/if}
															<span class="inline-flex items-center px-1.5 py-0.5 rounded text-xs font-medium bg-blue-100 text-blue-700">
																{checklistStore.getSourceLabel(item.source)}
															</span>
														</div>
														<div class="flex items-center gap-2">
															<span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium {getStatusColor(item.status)}">
																{getStatusLabel(item.status)}
															</span>
															{#if item.source === 'manual'}
																<div class="flex gap-1">
																	<Button 
																		size="sm" 
																		variant={item.status === 'yes' ? 'default' : 'outline'}
																		onclick={() => updateAssetItemStatus(asset.id, item.id || '', 'yes')}
																		class="px-2 py-1 text-xs"
																	>
																		Yes
																	</Button>
																	<Button 
																		size="sm" 
																		variant={item.status === 'no' ? 'default' : 'outline'}
																		onclick={() => updateAssetItemStatus(asset.id, item.id || '', 'no')}
																		class="px-2 py-1 text-xs"
																	>
																		No
																	</Button>
																	<Button 
																		size="sm" 
																		variant={item.status === 'na' ? 'default' : 'outline'}
																		onclick={() => updateAssetItemStatus(asset.id, item.id || '', 'na')}
																		class="px-2 py-1 text-xs"
																	>
																		N/A
																	</Button>
																</div>
															{/if}
														</div>
													</div>
												{/each}
											</div>
										</div>
									{/if}
								{/each}
							</div>
						{:else}
							<div class="text-center py-8 text-gray-500">
								No assets found. Discover assets to see compliance data.
							</div>
						{/if}
					</Card.Content>
				</Card.Root>
			</Tabs.Content>

			<!-- Summary by Type Tab -->
			<Tabs.Content value="summary" class="mt-6">
				<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
					{#each Object.entries(assetStats) as [type, stats]}
						<Card.Root>
							<Card.Header>
								<Card.Title class="text-lg capitalize">{type} Assets</Card.Title>
								<Card.Description>{stats.totalAssets} assets</Card.Description>
							</Card.Header>
							<Card.Content>
								<div class="text-2xl font-bold text-blue-600 mb-2">{stats.passRate}%</div>
								<Progress value={stats.passRate} class="mb-2" />
								<div class="text-sm text-gray-600 mb-2">
									{stats.passedItems} of {stats.totalItems} checks passed
								</div>
								{#if stats.requiredItems > 0}
									<div class="text-xs text-gray-500">
										Required: {stats.requiredPassedItems}/{stats.requiredItems} ({stats.requiredPassRate}%)
									</div>
								{/if}
							</Card.Content>
						</Card.Root>
					{/each}
				</div>
			</Tabs.Content>
		</Tabs.Root>

		<!-- Action Buttons -->
		<div class="mt-8 flex gap-4">
			<Button onclick={loadComplianceData}>
				Refresh Data
			</Button>
			<Button variant="outline" onclick={() => checklistStore.loadTemplates()}>
				Manage Templates
			</Button>
		</div>
	{/if}
</div>
