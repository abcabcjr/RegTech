<script lang="ts">
	import { Network } from 'vis-network';
	import type { V1AssetSummary } from '$lib/api/Api';
	import type { V1ScanResult, ModelDerivedChecklistItem } from '$lib/api/Api';
	import { Button } from './ui/button';
	import * as Dialog from '$lib/components/ui/dialog';
	import Input from './ui/input/input.svelte';
	import { assetStore } from '$lib/stores/assets.svelte';
	import { checklistStore } from '$lib/stores/checklist.svelte';
	import * as Drawer from '$lib/components/ui/drawer';

	let { assets = [] }: { assets: V1AssetSummary[] } = $props();

	let container: HTMLDivElement;
	let network: Network | null = null;

	// Extract domain from subdomain or service
	function extractDomain(value: string, type: string): string | null {
		if (type === 'subdomain') {
			const parts = value.split('.');
			if (parts.length >= 2) {
				return parts.slice(-2).join('.');
			}
		} else if (type === 'service') {
			const ipPort = value.split(':')[0];
			return ipPort;
		}
		return null;
	}

	// Extract IP from service
	function extractIPFromService(value: string): string {
		return value.split(':')[0];
	}

	// Check if an IP is associated with a domain/subdomain
	function findDomainForIP(ip: string, assets: V1AssetSummary[]): string | null {
		// This is a simplified approach - in a real scenario, you'd need DNS resolution data
		// For now, we'll create connections based on common patterns or if they appear together
		return null;
	}

	function createNetworkData(): { nodes: any[]; edges: any[] } {
		const nodes: any[] = [];
		const edges: any[] = [];
		const nodeMap = new Map<string, boolean>();

		// Create nodes for all assets
		assets.forEach((asset) => {
			if (!nodeMap.has(asset.id)) {
				let color: string;
				let shape: string;
				let size: number;

				switch (asset.type) {
					case 'domain':
						color = '#4CAF50'; // Green
						shape = 'diamond';
						size = 30;
						break;
					case 'subdomain':
						color = '#2196F3'; // Blue
						shape = 'dot';
						size = 20;
						break;
					case 'ip':
						color = '#FF9800'; // Orange
						shape = 'square';
						size = 25;
						break;
					case 'service':
						color = '#9C27B0'; // Purple
						shape = 'triangle';
						size = 15;
						break;
					default:
						color = '#757575'; // Gray
						shape = 'dot';
						size = 15;
				}

				// Add status indicator
				if (asset.status === 'scanned') {
					color = color + 'DD'; // Make it slightly more opaque
				} else if (asset.status === 'scanning') {
					color = '#FFC107'; // Yellow for scanning
				} else if (asset.status === 'error') {
					color = '#F44336'; // Red for error
				}

				nodes.push({
					id: asset.id,
					label: asset.value,
					title: `${asset.type.toUpperCase()}: ${asset.value}\nStatus: ${asset.status}\nScans: ${asset.scan_count}`,
					color: color,
					shape: shape,
					size: size,
					font: {
						size: 12,
						color: '#333333'
					}
				});
				nodeMap.set(asset.id, true);
			}
		});

		// Create edges based on relationships
		assets.forEach((asset) => {
			if (asset.type === 'subdomain') {
				// Connect subdomain to its parent domain
				const parentDomain = extractDomain(asset.value, 'subdomain');
				if (parentDomain) {
					const domainAsset = assets.find((a) => a.type === 'domain' && a.value === parentDomain);
					if (domainAsset) {
						edges.push({
							from: domainAsset.id,
							to: asset.id,
							color: { color: '#2196F3', opacity: 0.6 },
							width: 2,
							arrows: 'to'
						});
					}
				}
			} else if (asset.type === 'service') {
				// Connect service to its IP
				const serviceIP = extractIPFromService(asset.value);
				const ipAsset = assets.find((a) => a.type === 'ip' && a.value === serviceIP);
				if (ipAsset) {
					edges.push({
						from: ipAsset.id,
						to: asset.id,
						color: { color: '#9C27B0', opacity: 0.6 },
						width: 2,
						arrows: 'to'
					});
				}
			}
		});

		// Try to connect IPs to domains/subdomains based on common patterns
		// This is a heuristic approach - in reality you'd use DNS data
		const ipAssets = assets.filter((a) => a.type === 'ip');
		const domainAssets = assets.filter((a) => a.type === 'domain' || a.type === 'subdomain');

		// For demonstration, we'll create some logical connections
		// You might want to implement more sophisticated logic here
		ipAssets.forEach((ipAsset) => {
			// Check if this IP has services
			const hasServices = assets.some(
				(a) => a.type === 'service' && a.value.startsWith(ipAsset.value)
			);
			if (!hasServices) {
				// Try to find a domain that might be related (this is very basic logic)
				const possibleDomain = domainAssets.find((d) => {
					// Very basic heuristic - you'd want more sophisticated matching
					return Math.random() < 0.3; // Random connection for demo
				});

				if (
					possibleDomain &&
					!edges.some((e) => e.from === possibleDomain.id && e.to === ipAsset.id)
				) {
					edges.push({
						from: possibleDomain.id,
						to: ipAsset.id,
						color: { color: '#FF9800', opacity: 0.4 },
						width: 1,
						arrows: 'to',
						dashes: true // Dashed line to indicate uncertain relationship
					});
				}
			}
		});

		return { nodes, edges };
	}

	function initializeNetwork() {
		if (!container || assets.length === 0) return;

		// Destroy existing network if it exists
		if (network) {
			network.destroy();
		}

		// Create new network
		const data = createNetworkData();

		const options: any = {
			nodes: {
				borderWidth: 2,
				shadow: true,
				font: {
					size: 12,
					color: '#333333'
				}
			},
			edges: {
				width: 2,
				shadow: true,
				smooth: {
					type: 'continuous'
				}
			},
			physics: {
				enabled: true,
				stabilization: { iterations: 100 },
				barnesHut: {
					gravitationalConstant: -2000,
					centralGravity: 0.3,
					springLength: 95,
					springConstant: 0.04,
					damping: 0.09,
					avoidOverlap: 0.1
				}
			},
			interaction: {
				hover: true,
				tooltipDelay: 200,
				hideEdgesOnDrag: false,
				hideNodesOnDrag: false
			},
			layout: {
				improvedLayout: true,
				hierarchical: {
					enabled: false
				}
			}
		};

		network = new Network(container, data, options);

		// Add event listeners
		network.on('click', (params: any) => {
			if (params.nodes.length > 0) {
				const nodeId = params.nodes[0];
				const asset = assets.find((a) => a.id === nodeId);
				if (asset) {
					selectedAsset = asset;
					drawerOpen = true;
					assetStore.loadAssetDetails(asset.id);
				}
			}
		});

		network.on('hoverNode', (params: any) => {
			container.style.cursor = 'pointer';
		});

		network.on('blurNode', (params: any) => {
			container.style.cursor = 'default';
		});
	}

	let previousAssetsLength = 0;

	let discoverListString = $state('');

	// Drawer state and selected asset
	let drawerOpen = $state(false);
	let selectedAsset: V1AssetSummary | null = $state(null);
	let discoveryOpen = $state(false);
	let discoveryHosts = $state('');
	let assetChecklistItems: ModelDerivedChecklistItem[] = $state([]);

	// Effect to initialize network when container and assets are available
	$effect(() => {
		if (container && assets.length > 0 && assets.length !== previousAssetsLength) {
			initializeNetwork();
			previousAssetsLength = assets.length;
		}
	});

	// Effect to load checklist items when selected asset changes
	$effect(() => {
		if (selectedAsset) {
			checklistStore.getAssetItems(selectedAsset.id).then(items => {
				assetChecklistItems = items;
			});
		} else {
			assetChecklistItems = [];
		}
	});

	// Cleanup when component unmounts
	$effect(() => {
		return () => {
			if (network) {
				network.destroy();
				network = null;
			}
		};
	});
</script>

<div class="asset-graph-root">
	<div bind:this={container} class="network-container"></div>

	<div class="overlay overlay-top-left">
		<div class="overlay-card">
			<h2 class="overlay-title">Asset Network Graph</h2>
			<div class="legend">
				<div class="legend-item">
					<div class="legend-icon legend-domain"></div>
					<span>Domains</span>
				</div>
				<div class="legend-item">
					<div class="legend-icon legend-subdomain"></div>
					<span>Subdomains</span>
				</div>
				<div class="legend-item">
					<div class="legend-icon legend-ip"></div>
					<span>IP Addresses</span>
				</div>
				<div class="legend-item">
					<div class="legend-icon legend-service"></div>
					<span>Services</span>
				</div>
			</div>
			<Dialog.Root>
				<Dialog.Trigger>Discover</Dialog.Trigger>
				<Dialog.Content>
					<Dialog.Header>
						<Dialog.Title>Discover assets</Dialog.Title>
						<Dialog.Description>Enter domains & hosts, separated by comma.</Dialog.Description>
					</Dialog.Header>
					<Input bind:value={discoverListString} placeholder="example.com, example2.com, 1.1.1.1"
					></Input>
					<Button
						onclick={() => {
							assetStore.discover(discoverListString.split(',').map((host) => host.trim()));
						}}>Discover</Button
					>
				</Dialog.Content>
			</Dialog.Root>

			<!-- Asset details drawer -->
			<Drawer.Root direction="right" open={drawerOpen} onOpenChange={(v: boolean) => (drawerOpen = v)}>
				<Drawer.Content style="max-height: 85vh; overflow: auto;">
					<Drawer.Header>
						<Drawer.Title>Asset details</Drawer.Title>
						<Drawer.Description>
							{selectedAsset ? `${selectedAsset.type.toUpperCase()} • ${selectedAsset.value}` : 'No asset selected'}
						</Drawer.Description>
					</Drawer.Header>
					<div class="drawer-body">
						{#if selectedAsset}
							<div class="asset-details">
								<div><strong>ID:</strong> {selectedAsset.id}</div>
								<div><strong>Type:</strong> {selectedAsset.type}</div>
								<div><strong>Value:</strong> {selectedAsset.value}</div>
								<div><strong>Status:</strong> {selectedAsset.status || 'n/a'}</div>
								<div><strong>Scans:</strong> {selectedAsset.scan_count}</div>
								{#if selectedAsset.last_scanned_at}
									<div><strong>Last scanned:</strong> {selectedAsset.last_scanned_at}</div>
								{/if}
							</div>

							<!-- Live job indicator for this asset -->
							{#if assetStore.jobRunning && assetStore.currentScanAssetId === selectedAsset.id}
								<div class="live-indicator">Updating results…</div>
							{/if}

							<!-- Latest scan results -->
							{#if (assetStore.assetDetails[selectedAsset.id]?.scan_results || []).length}
								<div class="results">
									<h3>Latest results</h3>
									{#each (assetStore.assetDetails[selectedAsset.id]?.scan_results as V1ScanResult[]) ?? [] as r (r.id)}
										<div class="result-item">
											<div class="result-head">
												<span class="script">{r.script_name}</span>
												<span class="status" data-ok={r.success}>{r.success ? 'ok' : 'fail'}</span>
												<span class="decision" data-decision={(r as any)?.decision ?? (r.success ? 'pass' : (r.error ? 'reject' : 'na'))}>
													{(r as any)?.decision ?? (r.success ? 'pass' : (r.error ? 'reject' : 'na'))}
												</span>
											</div>
											<div class="meta">
												<span>{r.executed_at}</span>
												<span>{r.duration}</span>
											</div>
											{#if r.error}
												<pre class="error">{r.error}</pre>
											{/if}
											{#if r.output?.length}
												<pre class="output">{r.output.join('\n')}</pre>
											{/if}
											{#if r.metadata}
												<pre class="metadata">{JSON.stringify(r.metadata, null, 2)}</pre>
											{/if}
										</div>
									{/each}
								</div>
							{:else}
								<div class="results empty">No results yet.</div>
							{/if}

							<!-- Checklist section -->
							{#if assetChecklistItems.length > 0}
								<div class="mt-6">
									<h3 class="text-sm font-semibold text-gray-900 mb-3">Compliance Checklist</h3>
									<div class="space-y-3">
										{#each assetChecklistItems as item (item.id)}
											<div class="border border-gray-200 rounded-lg p-3 bg-white">
												<div class="flex items-start justify-between mb-2">
													<div class="flex-1">
														<div class="flex items-center gap-2 mb-1">
															<span class="font-medium text-gray-900 text-sm">{item.title}</span>
															<span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium {checklistStore.getStatusColor(item.status)}">
																{checklistStore.getStatusLabel(item.status)}
															</span>
															<span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-blue-50 text-blue-700 border border-blue-200">
																{checklistStore.getSourceLabel(item.source)}
															</span>
														</div>
														{#if item.required}
															<span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-orange-50 text-orange-700 border border-orange-200">
																Required
															</span>
														{/if}
													</div>
												</div>
												{#if item.description}
													<div class="text-sm text-gray-600 mb-2">{item.description}</div>
												{/if}
												{#if item.notes}
													<div class="text-sm text-gray-700 mb-2">
														<span class="font-medium">Notes:</span> {item.notes}
													</div>
												{/if}
												{#if item.evidence && Object.keys(item.evidence).length > 0}
													<div class="text-sm mb-2">
														<span class="font-medium text-gray-700">Evidence:</span>
														<pre class="mt-1 text-xs bg-gray-50 p-2 rounded border overflow-auto max-h-32">{JSON.stringify(item.evidence, null, 2)}</pre>
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
								</div>
							{:else if checklistStore.assetLoading[selectedAsset?.id || '']}
								<div class="mt-6">
									<h3 class="text-sm font-semibold text-gray-900 mb-3">Compliance Checklist</h3>
									<div class="text-sm text-gray-500">Loading checklist items...</div>
								</div>
							{:else}
								<div class="mt-6">
									<h3 class="text-sm font-semibold text-gray-900 mb-3">Compliance Checklist</h3>
									<div class="text-sm text-gray-500">No checklist items for this asset type.</div>
								</div>
							{/if}

							<div class="drawer-actions">
								<Button onclick={() => selectedAsset && assetStore.scanAsset(selectedAsset.id)}>
									Start scan
								</Button>
								<Button variant="outline" onclick={() => selectedAsset && assetStore.loadAssetDetails(selectedAsset.id)}>
									Refresh
								</Button>
								<Drawer.Close>Close</Drawer.Close>
							</div>
						{/if}
					</div>
					<Drawer.Footer />
				</Drawer.Content>
			</Drawer.Root>
		</div>
	</div>

	<div class="overlay overlay-bottom">
		<div class="overlay-card">
			<div class="overlay-info">
				<span>Total Assets: {assets.length}</span>
				<span>Click nodes to view details. Drag to explore.</span>
			</div>
		</div>
	</div>
</div>

<style>
	.asset-graph-root {
		position: fixed;
		inset: 0;
		width: 100vw;
		height: 100vh;
		overflow: hidden;
		z-index: 0;
	}

	.network-container {
		position: absolute;
		inset: 0;
		width: 100%;
		height: 100%;
		background: #fafafa;
	}

	.overlay {
		position: absolute;
		z-index: 10;
		pointer-events: none;
	}

	.overlay-top-left {
		top: 1rem;
		left: 1rem;
	}

	.overlay-bottom {
		bottom: 1rem;
		left: 50%;
		transform: translateX(-50%);
	}

	.overlay-card {
		pointer-events: auto;
		background: rgba(255, 255, 255, 0.85);
		backdrop-filter: saturate(1.2) blur(6px);
		-webkit-backdrop-filter: saturate(1.2) blur(6px);
		border: 1px solid rgba(0, 0, 0, 0.08);
		border-radius: 10px;
		box-shadow: 0 4px 24px rgba(0, 0, 0, 0.08);
		padding: 0.75rem 1rem;
	}

	.overlay-title {
		margin: 0 0 0.5rem 0;
		font-size: 1.125rem;
		font-weight: 600;
		color: #111827;
	}

	.legend {
		display: flex;
		gap: 0.75rem;
		flex-wrap: wrap;
		align-items: center;
	}

	.legend-item {
		display: flex;
		align-items: center;
		gap: 0.4rem;
		font-size: 0.85rem;
		color: #374151;
	}

	.legend-icon {
		width: 14px;
		height: 14px;
		border-radius: 4px;
	}

	.legend-domain {
		background: #4caf50;
		clip-path: polygon(50% 0%, 0% 100%, 100% 100%);
		border-radius: 0;
	}

	.legend-subdomain {
		background: #2196f3;
		border-radius: 999px;
	}

	.legend-ip {
		background: #ff9800;
		border-radius: 2px;
	}

	.legend-service {
		background: #9c27b0;
		clip-path: polygon(50% 0%, 0% 100%, 100% 100%);
		border-radius: 0;
	}

	.overlay-info {
		display: flex;
		gap: 1rem;
		font-size: 0.9rem;
		color: #374151;
	}

	.drawer-body {
		padding: 0.5rem 0.25rem 1rem 0.25rem;
		display: grid;
		gap: 0.5rem;
	}

	.drawer-actions {
		margin-top: 0.75rem;
		display: flex;
		gap: 0.5rem;
		align-items: center;
		position: sticky;
		bottom: 0;
		background: #fff;
		padding-top: 0.5rem;
		border-top: 1px solid rgba(0,0,0,0.06);
	}

	.results { margin-top: 0.75rem; display: grid; gap: 0.5rem; }
	.results h3 { margin: 0; font-size: 0.95rem; font-weight: 600; }
	.result-item { border: 1px solid rgba(0,0,0,0.08); border-radius: 8px; padding: 0.5rem; background: #fff; }
	.result-head { display: flex; justify-content: space-between; align-items: center; font-size: 0.9rem; }
	.result-head .script { font-weight: 600; }
	.result-head .status[data-ok="true"] { color: #059669; }
	.result-head .status[data-ok="false"] { color: #dc2626; }
	.result-head .decision { margin-left: 0.5rem; font-size: 0.75rem; padding: 2px 6px; border-radius: 999px; border: 1px solid rgba(0,0,0,0.08); }
	.result-head .decision[data-decision="pass"] { background: #ecfdf5; color: #065f46; border-color: #a7f3d0; }
	.result-head .decision[data-decision="reject"] { background: #fef2f2; color: #7f1d1d; border-color: #fecaca; }
	.result-head .decision[data-decision="na"] { background: #f3f4f6; color: #374151; border-color: #e5e7eb; }
	.meta { display: flex; gap: 0.75rem; font-size: 0.75rem; color: #6b7280; }
	pre.output, pre.error, pre.metadata { margin: 0.25rem 0 0 0; max-height: 140px; overflow: auto; background: #f9fafb; padding: 0.5rem; border-radius: 6px; }
	pre.error { background: #fef2f2; }

	.live-indicator { margin-top: 0.25rem; font-size: 0.8rem; color: #2563eb; }
</style>
