<script lang="ts">
	import type { V1AssetSummary, V1AssetDetails, V1ScanResult, ModelDerivedChecklistItem } from '$lib/api/Api';
	import { assetStore } from '$lib/stores/assets.svelte';
	import { checklistStore } from '$lib/stores/checklist.svelte';
	import * as Dialog from '$lib/components/ui/dialog';
	import * as Tabs from '$lib/components/ui/tabs';
	import * as Card from '$lib/components/ui/card';
	import { Badge } from '$lib/components/ui/badge';
	import { Button } from '$lib/components/ui/button';
	import { Progress } from '$lib/components/ui/progress';
	
	// Lucide Icons
	import X from '@lucide/svelte/icons/x';
	import Info from '@lucide/svelte/icons/info';
	import Shield from '@lucide/svelte/icons/shield';
	import Terminal from '@lucide/svelte/icons/terminal';
	import Clock from '@lucide/svelte/icons/clock';
	import CheckCircle from '@lucide/svelte/icons/check-circle';
	import XCircle from '@lucide/svelte/icons/x-circle';
	import AlertCircle from '@lucide/svelte/icons/alert-circle';
	import Play from '@lucide/svelte/icons/play';
	import RefreshCw from '@lucide/svelte/icons/refresh-cw';
	import Globe from '@lucide/svelte/icons/globe';
	import Server from '@lucide/svelte/icons/server';
	import NetworkIcon from '@lucide/svelte/icons/network';
	import Wifi from '@lucide/svelte/icons/wifi';
	import Tag from '@lucide/svelte/icons/tag';
	import Calendar from '@lucide/svelte/icons/calendar';
	import Activity from '@lucide/svelte/icons/activity';
	import FileText from '@lucide/svelte/icons/file-text';

	let { 
		open = $bindable(false),
		asset = $bindable(null),
		assetDetails = $bindable(null),
		checklistItems = $bindable([])
	}: {
		open: boolean;
		asset: V1AssetSummary | null;
		assetDetails: V1AssetDetails | null;
		checklistItems: ModelDerivedChecklistItem[];
	} = $props();

	// Get asset type icon
	function getAssetTypeIcon(type: string) {
		switch (type) {
			case 'domain': return Globe;
			case 'subdomain': return NetworkIcon;
			case 'ip': return Server;
			case 'service': return Wifi;
			default: return FileText;
		}
	}

	// Get status color and icon
	function getStatusInfo(status: string) {
		switch (status) {
			case 'scanned':
				return { color: 'text-green-600 bg-green-50 border-green-200', icon: CheckCircle };
			case 'scanning':
				return { color: 'text-yellow-600 bg-yellow-50 border-yellow-200', icon: RefreshCw };
			case 'error':
				return { color: 'text-red-600 bg-red-50 border-red-200', icon: XCircle };
			default:
				return { color: 'text-gray-600 bg-gray-50 border-gray-200', icon: AlertCircle };
		}
	}

	// Calculate compliance progress
	function getComplianceProgress() {
		if (!checklistItems.length) return { percentage: 0, passed: 0, total: 0 };
		
		const passed = checklistItems.filter(item => item.status === 'yes').length;
		const total = checklistItems.length;
		const percentage = Math.round((passed / total) * 100);
		
		return { percentage, passed, total };
	}

	// Get sorted scan results
	function getSortedScanResults(): V1ScanResult[] {
		if (!assetDetails?.scan_results) return [];
		return [...assetDetails.scan_results].sort((a, b) => 
			new Date(b.executed_at).getTime() - new Date(a.executed_at).getTime()
		);
	}

	// Format date
	function formatDate(dateString: string | undefined): string {
		if (!dateString) return 'Never';
		return new Date(dateString).toLocaleString();
	}

	// Format duration
	function formatDuration(duration: string): string {
		if (!duration) return 'N/A';
		const match = duration.match(/(\d+\.?\d*)(ms|s|m|h)/);
		if (!match) return duration;
		
		const value = parseFloat(match[1]);
		const unit = match[2];
		
		if (unit === 'ms' && value >= 1000) {
			return `${(value / 1000).toFixed(1)}s`;
		}
		return `${value}${unit}`;
	}

	// Handle scan action
	function handleScan() {
		if (asset) {
			assetStore.scanAsset(asset.id);
		}
	}

	// Handle refresh
	function handleRefresh() {
		if (asset) {
			assetStore.loadAssetDetails(asset.id);
		}
	}

	let recentScans = $derived(getSortedScanResults().slice(0, 5));
</script>

<style>
	/* Override Dialog grid layout for this specific modal */
	:global(.asset-modal-content) {
		display: flex !important;
		flex-direction: column !important;
		grid-template-rows: none !important;
		grid-template-columns: none !important;
	}
</style>

<Dialog.Root bind:open>
	<Dialog.Content class="asset-modal-content !max-w-screen !max-h-none !w-screen !h-screen p-0 overflow-hidden m-0 rounded-none border-none flex flex-col">
		{#if asset && assetDetails}
		<!-- Header -->
		<div class="flex items-center justify-between !px-4 !py-3 border-b bg-gray-50 !min-h-0 !h-auto flex-shrink-0">
			<div class="flex items-center gap-3 min-w-0 flex-1">
				<div class="p-1.5 rounded-lg bg-white border flex-shrink-0">
					<svelte:component this={getAssetTypeIcon(asset.type)} class="w-5 h-5 text-gray-700" />
				</div>
				<div class="min-w-0 flex-1">
					<div class="flex items-center gap-2 mb-1">
						<h1 class="text-lg font-bold text-gray-900 truncate">{asset.value}</h1>
						{#if asset.status}
							<div class="flex items-center gap-1 px-1.5 py-0.5 rounded-full text-xs font-medium border {getStatusInfo(asset.status).color} flex-shrink-0">
								<svelte:component this={getStatusInfo(asset.status).icon} class="w-3 h-3" />
								{asset.status.charAt(0).toUpperCase() + asset.status.slice(1)}
							</div>
						{/if}
					</div>
					<div class="flex items-center gap-3 text-xs text-gray-600">
						<span class="flex items-center gap-1">
							<Tag class="w-3 h-3" />
							{asset.type.toUpperCase()}
						</span>
						<span class="flex items-center gap-1">
							<Activity class="w-3 h-3" />
							{asset.scan_count} scans
						</span>
						<span class="flex items-center gap-1 truncate">
							<Calendar class="w-3 h-3" />
							Last: {formatDate(asset.last_scanned_at)}
						</span>
					</div>
				</div>
			</div>
			
			<div class="flex items-center gap-2 flex-shrink-0 mr-8">
				<Button variant="outline" size="sm" onclick={handleRefresh}>
					<RefreshCw class="w-3 h-3 mr-1" />
					Refresh
				</Button>
				<Button size="sm" onclick={handleScan}>
					<Play class="w-3 h-3 mr-1" />
					Start Scan
				</Button>
			</div>
		</div>

			<!-- Content -->
			<div class="flex-1 overflow-hidden max-w-screen">
				<Tabs.Root value="overview" class="h-full flex flex-col">
					<Tabs.List class="grid w-full grid-cols-4 bg-gray-50 px-6">
						<Tabs.Trigger value="overview" class="flex items-center gap-2">
							<Info class="w-4 h-4" />
							Overview
						</Tabs.Trigger>
						<Tabs.Trigger value="compliance" class="flex items-center gap-2">
							<Shield class="w-4 h-4" />
							Compliance ({checklistItems.length})
						</Tabs.Trigger>
						<Tabs.Trigger value="scans" class="flex items-center gap-2">
							<Terminal class="w-4 h-4" />
							Scan Results ({getSortedScanResults().length})
						</Tabs.Trigger>
						<Tabs.Trigger value="details" class="flex items-center gap-2">
							<FileText class="w-4 h-4" />
							Technical Details
						</Tabs.Trigger>
					</Tabs.List>

					<!-- Overview Tab -->
					<Tabs.Content value="overview" class="flex-1 p-6 overflow-auto">
						<div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
							<!-- Key Metrics -->
							<div class="lg:col-span-2 space-y-6">
								<!-- Compliance Overview -->
								{#if checklistItems.length > 0}
									{@const progress = getComplianceProgress()}
									<Card.Root>
										<Card.Header>
											<Card.Title class="flex items-center gap-2">
												<Shield class="w-5 h-5" />
												Compliance Progress
											</Card.Title>
										</Card.Header>
										<Card.Content>
											<div class="space-y-4">
												<div class="flex items-center justify-between">
													<span class="text-sm font-medium">Overall Progress</span>
													<span class="text-sm text-gray-600">{progress.passed}/{progress.total} checks passed</span>
												</div>
												<Progress value={progress.percentage} class="h-2" />
												<div class="flex justify-between text-xs text-gray-600">
													<span>{progress.percentage}% Complete</span>
													<span>{progress.total - progress.passed} remaining</span>
												</div>
											</div>
										</Card.Content>
									</Card.Root>
								{/if}

								<!-- Recent Scan Activity -->
								{#if recentScans.length > 0}
									<Card.Root>
										<Card.Header>
											<Card.Title class="flex items-center gap-2">
												<Clock class="w-5 h-5" />
												Recent Scan Activity
											</Card.Title>
										</Card.Header>
										<Card.Content>
											<div class="space-y-3">
												{#each recentScans as result}
													<div class="flex items-center justify-between py-2 border-b last:border-b-0">
														<div class="flex items-center gap-3">
															{#if result.success}
																<CheckCircle class="w-4 h-4 text-green-500" />
															{:else}
																<XCircle class="w-4 h-4 text-red-500" />
															{/if}
															<span class="font-medium text-sm">{result.script_name}</span>
														</div>
														<div class="text-right text-xs text-gray-600">
															<div>{formatDate(result.executed_at)}</div>
															<div>{formatDuration(result.duration)}</div>
														</div>
													</div>
												{/each}
											</div>
										</Card.Content>
									</Card.Root>
								{/if}
							</div>

							<!-- Asset Info Sidebar -->
							<div class="space-y-6">
								<!-- Basic Information -->
								<Card.Root>
									<Card.Header>
										<Card.Title>Asset Information</Card.Title>
									</Card.Header>
									<Card.Content class="space-y-3">
										<div class="grid grid-cols-3 gap-2 text-sm">
											<span class="text-gray-600">ID:</span>
											<span class="col-span-2 font-mono text-xs">{asset.id}</span>
										</div>
										<div class="grid grid-cols-3 gap-2 text-sm">
											<span class="text-gray-600">Type:</span>
											<span class="col-span-2 font-medium">{asset.type.toUpperCase()}</span>
										</div>
										<div class="grid grid-cols-3 gap-2 text-sm">
											<span class="text-gray-600">Status:</span>
										<span class="col-span-2">
											<Badge variant="outline" class={getStatusInfo(asset.status).color}>
												{asset.status}
											</Badge>
										</span>
										</div>
										<div class="grid grid-cols-3 gap-2 text-sm">
											<span class="text-gray-600">Discovered:</span>
											<span class="col-span-2">{formatDate(asset.discovered_at)}</span>
										</div>
										<div class="grid grid-cols-3 gap-2 text-sm">
											<span class="text-gray-600">Scan Count:</span>
											<span class="col-span-2">{asset.scan_count}</span>
										</div>
									</Card.Content>
								</Card.Root>

								<!-- Tags -->
								{#if assetDetails.tags && assetDetails.tags.length > 0}
									<Card.Root>
										<Card.Header>
											<Card.Title>Tags</Card.Title>
										</Card.Header>
										<Card.Content>
										<div class="flex flex-wrap gap-2">
											{#each assetDetails.tags as tag}
												<Badge variant="secondary" class="text-xs">
													{tag}
												</Badge>
											{/each}
										</div>
										</Card.Content>
									</Card.Root>
								{/if}
							</div>
						</div>
					</Tabs.Content>

					<!-- Compliance Tab -->
					<Tabs.Content value="compliance" class="flex-1 p-6 overflow-auto">
						{#if checklistItems.length > 0}
							<div class="space-y-4">
								{#each checklistItems as item}
									<Card.Root>
										<Card.Content class="p-4">
											<div class="flex items-start justify-between mb-3">
												<div class="flex-1">
													<div class="flex items-center gap-2 mb-2">
														<h3 class="font-semibold text-gray-900">{item.title}</h3>
														<Badge class={checklistStore.getStatusColor(item.status)}>
															{checklistStore.getStatusLabel(item.status)}
														</Badge>
														<Badge variant="outline" class="text-xs">
															{checklistStore.getSourceLabel(item.source)}
														</Badge>
														{#if item.required}
															<Badge variant="destructive" class="text-xs">Required</Badge>
														{/if}
													</div>
													{#if item.description}
														<p class="text-sm text-gray-600 mb-2">{item.description}</p>
													{/if}
													{#if item.notes}
														<div class="text-sm mb-2">
															<span class="font-medium text-gray-700">Notes:</span>
															<span class="text-gray-600">{item.notes}</span>
														</div>
													{/if}
													{#if item.recommendation}
														<div class="text-sm">
															<span class="font-medium text-gray-700">Recommendation:</span>
															<span class="text-gray-600">{item.recommendation}</span>
														</div>
													{/if}
												</div>
											</div>
											{#if item.evidence && Object.keys(item.evidence).length > 0}
												<details class="mt-3">
													<summary class="cursor-pointer text-sm font-medium text-gray-700 hover:text-gray-900">
														View Evidence
													</summary>
													<pre class="mt-2 text-xs bg-gray-50 p-3 rounded border overflow-auto max-h-40">{JSON.stringify(item.evidence, null, 2)}</pre>
												</details>
											{/if}
										</Card.Content>
									</Card.Root>
								{/each}
							</div>
						{:else}
							<div class="text-center py-12">
								<Shield class="w-12 h-12 text-gray-400 mx-auto mb-4" />
								<h3 class="text-lg font-medium text-gray-900 mb-2">No Compliance Checks</h3>
								<p class="text-gray-600">No compliance checklist items found for this asset.</p>
							</div>
						{/if}
					</Tabs.Content>

					<!-- Scan Results Tab -->
					<Tabs.Content value="scans" class="flex-1 p-6 overflow-auto">
						{@const scanResults = getSortedScanResults()}
						{#if scanResults.length > 0}
							<div class="space-y-4">
								{#each scanResults as result}
									<Card.Root>
										<Card.Content class="p-4">
											<div class="flex items-center justify-between mb-3">
												<div class="flex items-center gap-3">
													{#if result.success}
														<CheckCircle class="w-5 h-5 text-green-500" />
													{:else}
														<XCircle class="w-5 h-5 text-red-500" />
													{/if}
													<h3 class="font-semibold text-gray-900">{result.script_name}</h3>
												</div>
												<div class="text-right text-sm text-gray-600">
													<div>{formatDate(result.executed_at)}</div>
													<div class="text-xs">Duration: {formatDuration(result.duration)}</div>
												</div>
											</div>
											
											{#if result.error}
												<div class="mb-3">
													<h4 class="text-sm font-medium text-red-700 mb-1">Error:</h4>
													<pre class="text-xs bg-red-50 text-red-800 p-2 rounded border">{result.error}</pre>
												</div>
											{/if}
											
											{#if result.output && result.output.length > 0}
												<div class="mb-3">
													<h4 class="text-sm font-medium text-gray-700 mb-1">Output:</h4>
													<pre class="text-xs bg-gray-50 p-2 rounded border overflow-auto max-h-32">{result.output.join('\n')}</pre>
												</div>
											{/if}
											
											{#if result.metadata && Object.keys(result.metadata).length > 0}
												<details>
													<summary class="cursor-pointer text-sm font-medium text-gray-700 hover:text-gray-900">
														View Metadata
													</summary>
													<pre class="mt-2 text-xs bg-gray-50 p-3 rounded border overflow-auto max-h-40">{JSON.stringify(result.metadata, null, 2)}</pre>
												</details>
											{/if}
										</Card.Content>
									</Card.Root>
								{/each}
							</div>
						{:else}
							<div class="text-center py-12">
								<Terminal class="w-12 h-12 text-gray-400 mx-auto mb-4" />
								<h3 class="text-lg font-medium text-gray-900 mb-2">No Scan Results</h3>
								<p class="text-gray-600">No scan results available for this asset yet.</p>
								<Button class="mt-4" onclick={handleScan}>
									<Play class="w-4 h-4 mr-2" />
									Start First Scan
								</Button>
							</div>
						{/if}
					</Tabs.Content>

					<!-- Technical Details Tab -->
					<Tabs.Content value="details" class="flex-1 p-6 overflow-auto">
						<div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
							<!-- DNS Records -->
							{#if assetDetails.dns_records}
								<Card.Root>
									<Card.Header>
										<Card.Title>DNS Records</Card.Title>
									</Card.Header>
									<Card.Content class="space-y-4">
										{#if assetDetails.dns_records.a?.length}
											<div>
												<h4 class="font-medium text-sm text-gray-700 mb-2">A Records (IPv4)</h4>
												<div class="space-y-1">
													{#each assetDetails.dns_records.a as record}
														<code class="block text-xs bg-gray-100 px-2 py-1 rounded">{record}</code>
													{/each}
												</div>
											</div>
										{/if}
										
										{#if assetDetails.dns_records.aaaa?.length}
											<div>
												<h4 class="font-medium text-sm text-gray-700 mb-2">AAAA Records (IPv6)</h4>
												<div class="space-y-1">
													{#each assetDetails.dns_records.aaaa as record}
														<code class="block text-xs bg-gray-100 px-2 py-1 rounded">{record}</code>
													{/each}
												</div>
											</div>
										{/if}
										
										{#if assetDetails.dns_records.cname?.length}
											<div>
												<h4 class="font-medium text-sm text-gray-700 mb-2">CNAME Records</h4>
												<div class="space-y-1">
													{#each assetDetails.dns_records.cname as record}
														<code class="block text-xs bg-gray-100 px-2 py-1 rounded">{record}</code>
													{/each}
												</div>
											</div>
										{/if}
										
										{#if assetDetails.dns_records.mx?.length}
											<div>
												<h4 class="font-medium text-sm text-gray-700 mb-2">MX Records</h4>
												<div class="space-y-1">
													{#each assetDetails.dns_records.mx as record}
														<code class="block text-xs bg-gray-100 px-2 py-1 rounded">{record}</code>
													{/each}
												</div>
											</div>
										{/if}
										
										{#if assetDetails.dns_records.txt?.length}
											<div>
												<h4 class="font-medium text-sm text-gray-700 mb-2">TXT Records</h4>
												<div class="space-y-1">
													{#each assetDetails.dns_records.txt as record}
														<code class="block text-xs bg-gray-100 px-2 py-1 rounded break-all">{record}</code>
													{/each}
												</div>
											</div>
										{/if}
										
										{#if assetDetails.dns_records.ns?.length}
											<div>
												<h4 class="font-medium text-sm text-gray-700 mb-2">NS Records</h4>
												<div class="space-y-1">
													{#each assetDetails.dns_records.ns as record}
														<code class="block text-xs bg-gray-100 px-2 py-1 rounded">{record}</code>
													{/each}
												</div>
											</div>
										{/if}
									</Card.Content>
								</Card.Root>
							{/if}

							<!-- Properties -->
							{#if assetDetails.properties && Object.keys(assetDetails.properties).length > 0}
								<Card.Root>
									<Card.Header>
										<Card.Title>Properties</Card.Title>
									</Card.Header>
									<Card.Content>
										<div class="space-y-3">
											{#each Object.entries(assetDetails.properties) as [key, value]}
												<div class="grid grid-cols-3 gap-2 text-sm">
													<span class="text-gray-600 capitalize">{key.replace(/_/g, ' ')}:</span>
													<span class="col-span-2 font-mono text-xs break-all">
														{typeof value === 'object' ? JSON.stringify(value) : String(value)}
													</span>
												</div>
											{/each}
										</div>
									</Card.Content>
								</Card.Root>
							{/if}
						</div>
					</Tabs.Content>
				</Tabs.Root>
			</div>
		{/if}
	</Dialog.Content>
</Dialog.Root>
