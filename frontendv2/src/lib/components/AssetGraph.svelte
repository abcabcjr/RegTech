<script lang="ts">
	import { Network } from 'vis-network';
	import type { V1AssetSummary } from '$lib/api/Api';
	import type { V1ScanResult, ModelDerivedChecklistItem } from '$lib/api/Api';
	import { Button } from './ui/button';
	import * as Dialog from '$lib/components/ui/dialog';
	import * as Select from './ui/select';
	import * as Card from './ui/card';
	import Input from './ui/input/input.svelte';
	import { assetStore } from '$lib/stores/assets.svelte';
	import { checklistStore } from '$lib/stores/checklist.svelte';
	import AssetDetailsModal from './AssetDetailsModal.svelte';

	// Lucide Icons
	import Globe from '@lucide/svelte/icons/globe';
	import NetworkIcon from '@lucide/svelte/icons/network';
	import Server from '@lucide/svelte/icons/server';
	import Wifi from '@lucide/svelte/icons/wifi';
	import Shield from '@lucide/svelte/icons/shield';
	import Lock from '@lucide/svelte/icons/lock';
	import Unlock from '@lucide/svelte/icons/unlock';
	import Cloud from '@lucide/svelte/icons/cloud';
	import Terminal from '@lucide/svelte/icons/terminal';
	import Database from '@lucide/svelte/icons/database';
	import Mail from '@lucide/svelte/icons/mail';
	import FileText from '@lucide/svelte/icons/file-text';

	let { assets = [] }: { assets: V1AssetSummary[] } = $props();

	let container: HTMLDivElement;
	let network: Network | null = null;

	// View and filter controls
	let layoutMode = $state<'force' | 'hierarchical' | 'clustered'>('force');
	let physicsEnabled = $state(true);
	let manualMode = $state(false);
	let edgeOpacity = $state(0.6);
	let nodeSpacing = $state('normal');
	let filterByType = $state<string>('all');
	let filterByTag = $state<string>('all');
	let filterByStatus = $state<string>('all');
	let searchQuery = $state('');
	let showControls = $state(false);
	let clusteringEnabled = $state(false);

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

	// Filter assets based on current filter settings
	function getFilteredAssets(): V1AssetSummary[] {
		let filtered = assets;

		// Filter by type
		if (filterByType !== 'all') {
			filtered = filtered.filter((asset) => asset.type === filterByType);
		}

		// Filter by tag - use asset details if available
		if (filterByTag !== 'all') {
			filtered = filtered.filter((asset) => {
				const assetDetails = assetStore.assetDetails[asset.id];
				const tags = assetDetails?.tags || [];
				return tags.includes(filterByTag);
			});
		}

		// Filter by status
		if (filterByStatus !== 'all') {
			filtered = filtered.filter((asset) => asset.status === filterByStatus);
		}

		// Filter by search query
		if (searchQuery.trim()) {
			const query = searchQuery.toLowerCase().trim();
			filtered = filtered.filter((asset) => {
				const assetDetails = assetStore.assetDetails[asset.id];
				const tags = assetDetails?.tags || [];
				return (
					asset.value.toLowerCase().includes(query) ||
					asset.type.toLowerCase().includes(query) ||
					tags.some((tag: string) => tag.toLowerCase().includes(query))
				);
			});
		}

		return filtered;
	}

	// Get unique tags from all assets
	function getAllTags(): string[] {
		const tagSet = new Set<string>();
		assets.forEach((asset) => {
			const assetDetails = assetStore.assetDetails[asset.id];
			const tags = assetDetails?.tags || [];
			tags.forEach((tag: string) => tagSet.add(tag));
		});
		return Array.from(tagSet).sort();
	}

	// Get unique asset types
	function getAssetTypes(): string[] {
		const typeSet = new Set<string>();
		assets.forEach((asset) => typeSet.add(asset.type));
		return Array.from(typeSet).sort();
	}

	// Get unique statuses
	function getAssetStatuses(): string[] {
		const statusSet = new Set<string>();
		assets.forEach((asset) => statusSet.add(asset.status));
		return Array.from(statusSet).sort();
	}

	// Get icon and color for asset based on type and tags
	function getAssetIconInfo(asset: V1AssetSummary): {
		icon: string;
		color: string;
		bgColor: string;
	} {
		const assetDetails = assetStore.assetDetails[asset.id];
		const tags = assetDetails?.tags || [];

		// Check for special tag-based icons first
		if (tags.includes('cf-proxied')) {
			return { icon: 'cloud', color: '#FF6B35', bgColor: '#FFF4F0' }; // Cloudflare orange
		}

		if (tags.includes('ssh')) {
			return { icon: 'terminal', color: '#000000', bgColor: '#F5F5F5' }; // SSH terminal
		}

		if (tags.includes('mail-server') || tags.includes('mx')) {
			return { icon: 'mail', color: '#4285F4', bgColor: '#E8F0FE' }; // Mail blue
		}

		if (tags.includes('database') || tags.includes('db')) {
			return { icon: 'database', color: '#34A853', bgColor: '#E8F5E8' }; // Database green
		}

		if (tags.includes('https') || tags.includes('ssl')) {
			return { icon: 'lock', color: '#0F9D58', bgColor: '#E8F5E8' }; // HTTPS green
		}

		if (tags.includes('http')) {
			return { icon: 'unlock', color: '#EA4335', bgColor: '#FCE8E6' }; // HTTP red
		}

		// Default icons based on asset type
		switch (asset.type) {
			case 'domain':
				return { icon: 'globe', color: '#4CAF50', bgColor: '#E8F5E8' }; // Green
			case 'subdomain':
				return { icon: 'network', color: '#2196F3', bgColor: '#E3F2FD' }; // Blue
			case 'ip':
				return { icon: 'server', color: '#FF9800', bgColor: '#FFF3E0' }; // Orange
			case 'service':
				if (tags.includes('web') || tags.includes('http') || tags.includes('https')) {
					return { icon: 'wifi', color: '#9C27B0', bgColor: '#F3E5F5' }; // Purple for web services
				}
				return { icon: 'shield', color: '#9C27B0', bgColor: '#F3E5F5' }; // Purple
			default:
				return { icon: 'file-text', color: '#666666', bgColor: '#F5F5F5' }; // Gray
		}
	}

	// Create SVG icon string for vis-network
	function createIconSvg(
		iconType: string,
		color: string,
		bgColor: string,
		size: number = 24
	): string {
		const iconMap: Record<string, string> = {
			globe: `<circle cx="12" cy="12" r="10" stroke="${color}" stroke-width="2" fill="none"/><path d="m2 12 20 0" stroke="${color}" stroke-width="2"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z" stroke="${color}" stroke-width="2" fill="none"/>`,
			network: `<path d="m3 16 4-4-4-4" stroke="${color}" stroke-width="2" fill="none"/><path d="m21 20-4-4 4-4" stroke="${color}" stroke-width="2" fill="none"/><path d="M6.5 12h11" stroke="${color}" stroke-width="2"/>`,
			server: `<rect width="20" height="8" x="2" y="2" rx="2" ry="2" stroke="${color}" stroke-width="2" fill="none"/><rect width="20" height="8" x="2" y="14" rx="2" ry="2" stroke="${color}" stroke-width="2" fill="none"/><line x1="6" x2="6.01" y1="6" y2="6" stroke="${color}" stroke-width="2"/><line x1="6" x2="6.01" y1="18" y2="18" stroke="${color}" stroke-width="2"/>`,
			wifi: `<path d="M5 12.55a11 11 0 0 1 14.08 0" stroke="${color}" stroke-width="2" fill="none"/><path d="M1.42 9a16 16 0 0 1 21.16 0" stroke="${color}" stroke-width="2" fill="none"/><path d="M8.53 16.11a6 6 0 0 1 6.95 0" stroke="${color}" stroke-width="2" fill="none"/><line x1="12" x2="12.01" y1="20" y2="20" stroke="${color}" stroke-width="2"/>`,
			shield: `<path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z" stroke="${color}" stroke-width="2" fill="none"/>`,
			lock: `<rect width="18" height="11" x="3" y="11" rx="2" ry="2" stroke="${color}" stroke-width="2" fill="none"/><path d="M7 11V7a5 5 0 0 1 10 0v4" stroke="${color}" stroke-width="2" fill="none"/>`,
			unlock: `<rect width="18" height="11" x="3" y="11" rx="2" ry="2" stroke="${color}" stroke-width="2" fill="none"/><path d="M7 11V7a5 5 0 0 1 9.9-1" stroke="${color}" stroke-width="2" fill="none"/>`,
			cloud: `<path d="M17.5 19H9a7 7 0 1 1 6.71-9h1.79a4.5 4.5 0 1 1 0 9Z" stroke="${color}" stroke-width="2" fill="none"/>`,
			terminal: `<polyline points="4,17 10,11 4,5" stroke="${color}" stroke-width="2" fill="none"/><line x1="12" x2="20" y1="19" y2="19" stroke="${color}" stroke-width="2"/>`,
			database: `<ellipse cx="12" cy="5" rx="9" ry="3" stroke="${color}" stroke-width="2" fill="none"/><path d="M3 5v14c0 3 4 6 9 6s9-3 9-6V5" stroke="${color}" stroke-width="2" fill="none"/>`,
			mail: `<path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" stroke="${color}" stroke-width="2" fill="none"/><polyline points="22,6 12,13 2,6" stroke="${color}" stroke-width="2" fill="none"/>`,
			'file-text': `<path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z" stroke="${color}" stroke-width="2" fill="none"/><path d="M14 2v4a2 2 0 0 0 2 2h4" stroke="${color}" stroke-width="2" fill="none"/><path d="M10 9H8" stroke="${color}" stroke-width="2"/><path d="M16 13H8" stroke="${color}" stroke-width="2"/><path d="M16 17H8" stroke="${color}" stroke-width="2"/>`
		};

		const iconPath = iconMap[iconType] || iconMap['file-text'];

		return `
			<svg width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
				<circle cx="12" cy="12" r="11" fill="${bgColor}" stroke="${color}" stroke-width="1.5"/>
				<g transform="translate(12,12) scale(0.6) translate(-12,-12)">
					${iconPath}
				</g>
			</svg>
		`;
	}

	function createNetworkData(): { nodes: any[]; edges: any[] } {
		const nodes: any[] = [];
		const edges: any[] = [];
		const nodeMap = new Map<string, boolean>();
		const filteredAssets = getFilteredAssets();

		// Create nodes for filtered assets
		filteredAssets.forEach((asset) => {
			if (!nodeMap.has(asset.id)) {
				const iconInfo = getAssetIconInfo(asset);
				let { color, bgColor } = iconInfo;

				// Modify colors based on status
				if (asset.status === 'scanning') {
					color = '#FFC107'; // Yellow for scanning
					bgColor = '#FFF8E1';
				} else if (asset.status === 'error') {
					color = '#F44336'; // Red for error
					bgColor = '#FFEBEE';
				}

				const iconSvg = createIconSvg(iconInfo.icon, color, bgColor, 40);

				// Convert SVG to data URL for vis-network
				const svgDataUrl = `data:image/svg+xml;charset=utf-8,${encodeURIComponent(iconSvg)}`;

				// Get tags for tooltip
				const assetDetails = assetStore.assetDetails[asset.id];
				const tags = assetDetails?.tags || [];
				const tagsText = tags.length > 0 ? `\nTags: ${tags.join(', ')}` : '';

				nodes.push({
					id: asset.id,
					label: asset.value,
					title: `${asset.type.toUpperCase()}: ${asset.value}\nStatus: ${asset.status}\nScans: ${asset.scan_count}${tagsText}`,
					shape: 'image',
					image: svgDataUrl,
					size: 40,
					borderWidth: 2,
					color: {
						border: color,
						background: bgColor,
						highlight: {
							border: color,
							background: bgColor
						},
						hover: {
							border: color,
							background: bgColor
						}
					},
					font: {
						size: 11,
						color: '#333333',
						face: 'Inter, system-ui, sans-serif',
						strokeWidth: 3,
						strokeColor: '#ffffff'
					},
					chosen: {
						node: function (values: any, id: string, selected: boolean, hovering: boolean) {
							if (hovering || selected) {
								values.borderWidth = 3;
								values.size = 44;
							}
						}
					}
				});
				nodeMap.set(asset.id, true);
			}
		});

		// Create edges based on relationships - supporting multiple parents
		createMultiParentEdges(filteredAssets, edges);

		return { nodes, edges };
	}

	// Create edges supporting multiple parent relationships
	function createMultiParentEdges(filteredAssets: V1AssetSummary[], edges: any[]) {
		// Create maps for efficient lookups
		const assetsByType = {
			domain: filteredAssets.filter((a) => a.type === 'domain'),
			subdomain: filteredAssets.filter((a) => a.type === 'subdomain'),
			ip: filteredAssets.filter((a) => a.type === 'ip'),
			service: filteredAssets.filter((a) => a.type === 'service')
		};

		const assetsByValue = new Map<string, V1AssetSummary>();
		filteredAssets.forEach((asset) => assetsByValue.set(asset.value, asset));

		// 1. Connect subdomains to their parent domains
		assetsByType.subdomain.forEach((subdomain) => {
			const parentDomain = extractDomain(subdomain.value, 'subdomain');
			if (parentDomain) {
				const domainAsset = assetsByValue.get(parentDomain);
				if (domainAsset) {
					addEdgeIfNotExists(edges, domainAsset.id, subdomain.id, {
						color: { color: '#2196F3', opacity: edgeOpacity },
						width: 2,
						arrows: 'to',
						title: 'Domain → Subdomain'
					});
				}
			}
		});

		// 2. Connect services to their host IPs
		assetsByType.service.forEach((service) => {
			const serviceIP = extractIPFromService(service.value);
			const ipAsset = assetsByValue.get(serviceIP);
			if (ipAsset) {
				addEdgeIfNotExists(edges, ipAsset.id, service.id, {
					color: { color: '#9C27B0', opacity: edgeOpacity },
					width: 2,
					arrows: 'to',
					title: 'IP → Service'
				});
			}
		});

		// 3. Use DNS records to connect domains/subdomains to IPs (multiple relationships)
		[...assetsByType.domain, ...assetsByType.subdomain].forEach((domainAsset) => {
			const assetDetails = assetStore.assetDetails[domainAsset.id];
			if (assetDetails?.dns_records) {
				const dnsRecords = assetDetails.dns_records;

				// Connect to A records (IPv4)
				dnsRecords.a?.forEach((ip: string) => {
					const ipAsset = assetsByValue.get(ip);
					if (ipAsset) {
						addEdgeIfNotExists(edges, domainAsset.id, ipAsset.id, {
							color: { color: '#4CAF50', opacity: edgeOpacity * 0.8 },
							width: 2,
							arrows: 'to',
							title: 'DNS A Record',
							dashes: false
						});
					}
				});

				// Connect to AAAA records (IPv6)
				dnsRecords.aaaa?.forEach((ip: string) => {
					const ipAsset = assetsByValue.get(ip);
					if (ipAsset) {
						addEdgeIfNotExists(edges, domainAsset.id, ipAsset.id, {
							color: { color: '#4CAF50', opacity: 0.5 },
							width: 1,
							arrows: 'to',
							title: 'DNS AAAA Record',
							dashes: [5, 5]
						});
					}
				});

				// Connect CNAME chains
				dnsRecords.cname?.forEach((cname: string) => {
					const cnameAsset = assetsByValue.get(cname);
					if (cnameAsset) {
						addEdgeIfNotExists(edges, domainAsset.id, cnameAsset.id, {
							color: { color: '#FF9800', opacity: 0.6 },
							width: 1,
							arrows: 'to',
							title: 'CNAME Record',
							dashes: [10, 5]
						});
					}
				});
			}
		});

		// 4. Connect based on service relationships and properties
		assetsByType.service.forEach((service) => {
			const assetDetails = assetStore.assetDetails[service.id];
			if (assetDetails?.properties) {
				// Connect services that share the same source IP to domains
				const sourceIP = assetDetails.properties.source_ip;
				if (sourceIP && typeof sourceIP === 'string') {
					// Find domains that resolve to this source IP
					[...assetsByType.domain, ...assetsByType.subdomain].forEach((domainAsset) => {
						const domainDetails = assetStore.assetDetails[domainAsset.id];
						if (domainDetails?.dns_records?.a?.includes(sourceIP)) {
							addEdgeIfNotExists(edges, domainAsset.id, service.id, {
								color: { color: '#673AB7', opacity: 0.5 },
								width: 1,
								arrows: 'to',
								title: 'Domain → Service (via IP)',
								dashes: [3, 3]
							});
						}
					});
				}
			}
		});

		// 5. Create reverse relationships for IPs that host multiple domains
		assetsByType.ip.forEach((ipAsset) => {
			const relatedDomains: V1AssetSummary[] = [];

			// Find all domains that resolve to this IP
			[...assetsByType.domain, ...assetsByType.subdomain].forEach((domainAsset) => {
				const domainDetails = assetStore.assetDetails[domainAsset.id];
				if (domainDetails?.dns_records?.a?.includes(ipAsset.value)) {
					relatedDomains.push(domainAsset);
				}
			});

			// If this IP hosts multiple domains, create connections between them
			if (relatedDomains.length > 1) {
				relatedDomains.forEach((domain1) => {
					relatedDomains.forEach((domain2) => {
						if (domain1.id !== domain2.id) {
							addEdgeIfNotExists(edges, domain1.id, domain2.id, {
								color: { color: '#795548', opacity: 0.3 },
								width: 1,
								arrows: 'none',
								title: 'Shared IP Host',
								dashes: [2, 8]
							});
						}
					});
				});
			}
		});
	}

	// Helper function to avoid duplicate edges
	function addEdgeIfNotExists(edges: any[], from: string, to: string, edgeProps: any) {
		const exists = edges.some((edge) => edge.from === from && edge.to === to);
		if (!exists) {
			edges.push({
				from,
				to,
				...edgeProps
			});
		}
	}

	function initializeNetwork() {
		const filteredAssets = getFilteredAssets();
		if (!container || filteredAssets.length === 0) return;

		// Store current view position before destroying network
		const currentViewState = storeNetworkView();

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
				},
				scaling: {
					min: 10,
					max: 30
				}
			},
			edges: {
				width: 2,
				shadow: true,
				smooth: {
					type: layoutMode === 'hierarchical' ? 'cubicBezier' : 'continuous',
					forceDirection: layoutMode === 'hierarchical' ? 'vertical' : 'none',
					roundness: 0.4
				}
			},
			physics: {
				enabled: physicsEnabled && !manualMode,
				stabilization: {
					iterations: layoutMode === 'hierarchical' ? 300 : 150,
					updateInterval: 50
				},
				barnesHut: {
					gravitationalConstant: getGravitationalConstant(),
					centralGravity: layoutMode === 'clustered' ? 0.05 : 0.1,
					springLength: getSpringLength(),
					springConstant: manualMode ? 0.001 : 0.02,
					damping: manualMode ? 0.9 : 0.15,
					avoidOverlap: getAvoidOverlap()
				},
				maxVelocity: manualMode ? 5 : 20,
				minVelocity: 0.75,
				solver: 'barnesHut',
				timestep: manualMode ? 0.1 : 0.35
			},
			interaction: {
				hover: true,
				tooltipDelay: 200,
				hideEdgesOnDrag: manualMode,
				hideNodesOnDrag: false,
				zoomView: true,
				dragView: true,
				dragNodes: true,
				selectConnectedEdges: false,
				multiselect: manualMode,
				keyboard: {
					enabled: true,
					speed: { x: 10, y: 10, zoom: 0.02 },
					bindToWindow: false
				}
			},
			layout: {
				improvedLayout: true,
				hierarchical: {
					enabled: layoutMode === 'hierarchical',
					direction: 'UD',
					sortMethod: 'directed',
					levelSeparation: 150,
					nodeSpacing: 100,
					treeSpacing: 200,
					blockShifting: true,
					edgeMinimization: true,
					parentCentralization: true
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
					// Batch state updates to prevent multiple reactivity triggers
					selectedAsset = asset;
					selectedAssetId = asset.id;
					selectedAssetDetails = assetStore.assetDetails[asset.id] || null;
					modalOpen = true;
					// Load asset details asynchronously
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

		// Apply clustering if enabled
		if (clusteringEnabled && layoutMode === 'clustered') {
			applyNetworkClustering();
		}

		// Restore previous view state if it exists
		if (currentViewState) {
			restoreNetworkView(currentViewState);
		}
	}

	function applyNetworkClustering() {
		if (!network) return;

		const filteredAssets = getFilteredAssets();

		// Cluster by asset type
		const assetTypes = getAssetTypes();
		assetTypes.forEach((type) => {
			const typeAssets = filteredAssets.filter((asset) => asset.type === type);
			if (typeAssets.length > 1) {
				const nodeIds = typeAssets.map((asset) => asset.id);
				network!.cluster({
					joinCondition: (childOptions: any) => nodeIds.includes(childOptions.id),
					clusterNodeProperties: {
						label: `${type.toUpperCase()}\n(${typeAssets.length})`,
						shape: 'box',
						color: getClusterColor(type),
						font: { size: 14, color: 'white' },
						borderWidth: 3
					}
				});
			}
		});
	}

	function getClusterColor(type: string): string {
		switch (type) {
			case 'domain':
				return '#4CAF50';
			case 'subdomain':
				return '#2196F3';
			case 'ip':
				return '#FF9800';
			case 'service':
				return '#9C27B0';
			default:
				return '#666666';
		}
	}

	// Create a hash of current filter settings to detect changes
	function getFilterHash(): string {
		return `${layoutMode}-${physicsEnabled}-${manualMode}-${edgeOpacity}-${nodeSpacing}-${clusteringEnabled}-${filterByType}-${filterByTag}-${filterByStatus}-${searchQuery}`;
	}

	// Create a hash of assets data to detect content changes
	function getAssetsHash(): string {
		return assets.map(asset => `${asset.id}-${asset.status}-${asset.scan_count}-${JSON.stringify(assetStore.assetDetails[asset.id]?.tags || [])}`).join('|');
	}

	// Update existing network data without destroying it
	function updateNetworkData() {
		if (!network) return;
		
		// Store current view position and node positions before updating
		const currentViewState = storeNetworkView();
		const nodePositions = storeNodePositions();
		
		// Temporarily disable physics to prevent movement during update
		const wasPhysicsEnabled = physicsEnabled && !manualMode;
		if (wasPhysicsEnabled) {
			network.setOptions({ physics: { enabled: false } });
		}
		
		const data = createNetworkData();
		
		try {
			// Update nodes and edges without destroying the network
			network.setData(data);
			
			// Restore node positions immediately if available
			if (nodePositions) {
				// Try immediate restoration first
				Object.entries(nodePositions).forEach(([nodeId, position]: [string, any]) => {
					try {
						network!.moveNode(nodeId, position.x, position.y);
					} catch (e) {
						// Silently ignore errors for individual nodes
					}
				});
			}
			
			// Restore view state immediately if available
			if (currentViewState) {
				try {
					network.moveTo({
						position: currentViewState.position,
						scale: currentViewState.scale,
						animation: false
					});
				} catch (e) {
					// Fallback to delayed restoration
					restoreNetworkView(currentViewState);
				}
			}
			
			// Re-enable physics if it was enabled before
			if (wasPhysicsEnabled) {
				setTimeout(() => {
					network!.setOptions({ physics: { enabled: true } });
				}, 5);
			}
		} catch (error) {
			console.error('Failed to update network data, falling back to reinitialize:', error);
			// Re-enable physics before fallback
			if (wasPhysicsEnabled) {
				network.setOptions({ physics: { enabled: true } });
			}
			// Fallback to full reinitialize if update fails
			initializeNetwork();
		}
	}

	// Get spacing parameters based on current settings
	function getSpringLength(): number {
		const baseLength = layoutMode === 'clustered' ? 250 : 180;
		const spacingMultiplier =
			{
				tight: 0.7,
				normal: 1.0,
				loose: 1.5,
				'very-loose': 2.0
			}[nodeSpacing] || 1.0;

		return baseLength * spacingMultiplier;
	}

	function getGravitationalConstant(): number {
		const baseConstant = layoutMode === 'clustered' ? -12000 : -4000;
		const spacingMultiplier =
			{
				tight: 1.5,
				normal: 1.0,
				loose: 0.6,
				'very-loose': 0.3
			}[nodeSpacing] || 1.0;

		return baseConstant * spacingMultiplier;
	}

	function getAvoidOverlap(): number {
		const baseOverlap = layoutMode === 'clustered' ? 0.5 : 0.3;
		const spacingMultiplier =
			{
				tight: 0.5,
				normal: 1.0,
				loose: 1.5,
				'very-loose': 2.0
			}[nodeSpacing] || 1.0;

		return baseOverlap * spacingMultiplier;
	}

	// Store and restore network view position
	function storeNetworkView() {
		if (!network) return null;
		try {
			const position = network.getViewPosition();
			const scale = network.getScale();
			return { position, scale };
		} catch (e) {
			return null;
		}
	}

	function restoreNetworkView(viewState: any) {
		if (!network || !viewState) return;
		try {
			// Reduce delay and use immediate restoration when possible
			setTimeout(() => {
				network!.moveTo({
					position: viewState.position,
					scale: viewState.scale,
					animation: false
				});
			}, 5); // Much shorter delay
		} catch (e) {
			console.error('Failed to restore view state:', e);
		}
	}

	// Store and restore node positions
	function storeNodePositions() {
		if (!network) return null;
		try {
			const positions = network.getPositions();
			return positions;
		} catch (e) {
			return null;
		}
	}

	function restoreNodePositions(nodePositions: any) {
		if (!network || !nodePositions) return;
		try {
			setTimeout(() => {
				// Move nodes individually to their stored positions
				Object.entries(nodePositions).forEach(([nodeId, position]: [string, any]) => {
					try {
						network!.moveNode(nodeId, position.x, position.y);
					} catch (e) {
						// Silently ignore errors for individual nodes (e.g., if node no longer exists)
					}
				});
			}, 5); // Much shorter delay
		} catch (e) {
			console.error('Failed to restore node positions:', e);
		}
	}

	// Use a more persistent way to store previous values that won't reset on re-renders
	let networkState = $state({
		previousAssetsLength: 0,
		previousFilterHash: '',
		previousAssetsHash: '',
		initialized: false
	});

	let discoverListString = $state('');

	// Modal state and selected asset
	let modalOpen = $state(false);
	let selectedAsset: V1AssetSummary | null = $state(null);
	let selectedAssetId: string | null = $state(null);
	let selectedAssetDetails: any = $state(null);
	let discoveryOpen = $state(false);
	let discoveryHosts = $state('');
	let assetChecklistItems: ModelDerivedChecklistItem[] = $state([]);

	// Computed sorted scan results
	let sortedScanResults = $derived(() => {
		if (!selectedAsset?.id || !assetStore.assetDetails[selectedAsset.id]?.scan_results) {
			return [];
		}
		const results = assetStore.assetDetails[selectedAsset.id].scan_results || [];
		return [...results].sort(
			(a, b) => new Date(b.executed_at).getTime() - new Date(a.executed_at).getTime()
		);
	});

	// Effect to initialize network when container and assets are available
	$effect(() => {
		if (container && assets.length > 0) {
			const currentAssetsHash = getAssetsHash();
			const currentFilterHash = getFilterHash();
			
			// Full reinitialize only if: no network exists, filter settings changed, or first time
			const shouldReinitialize = !network || !networkState.initialized || currentFilterHash !== networkState.previousFilterHash;
			
			if (shouldReinitialize) {
				initializeNetwork();
				networkState.previousAssetsLength = assets.length;
				networkState.previousFilterHash = currentFilterHash;
				networkState.previousAssetsHash = currentAssetsHash;
				networkState.initialized = true;
			}
			// Update data for any other changes (length changes, content changes, etc.)
			else if (currentAssetsHash !== networkState.previousAssetsHash || assets.length !== networkState.previousAssetsLength) {
				updateNetworkData();
				networkState.previousAssetsLength = assets.length;
				networkState.previousAssetsHash = currentAssetsHash;
			}
		}
	});

	// Effect to maintain selected asset when assets are refreshed
	$effect(() => {
		if (selectedAssetId && assets.length > 0) {
			const updatedAsset = assets.find((a) => a.id === selectedAssetId);
			if (updatedAsset) {
				// Only update the selected asset data, don't modify modal state
				selectedAsset = updatedAsset;
				selectedAssetDetails = assetStore.assetDetails[selectedAssetId] || null;
			} else if (selectedAssetId) {
				// Asset not found - it might have been removed
				selectedAsset = null;
				selectedAssetId = null;
				selectedAssetDetails = null;
				modalOpen = false;
			}
		}
	});

	// Effect to reactively update selectedAssetDetails when store data changes
	$effect(() => {
		if (selectedAssetId) {
			selectedAssetDetails = assetStore.assetDetails[selectedAssetId] || null;
		}
	});

	// Effect to load checklist items when selected asset changes
	$effect(() => {
		if (selectedAsset) {
			checklistStore.getAssetItems(selectedAsset.id).then((items) => {
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

	<!-- Empty state message -->
	{#if assets.length !== 0}
		<div class="overlay overlay-top-left">
			<div class="overlay-card">
				<div class="mb-2 flex items-center justify-between">
					<h2 class="overlay-title">Asset Network Graph</h2>
					<Button variant="outline" size="sm" onclick={() => (showControls = !showControls)}>
						{showControls ? 'Hide' : 'Show'} Controls
					</Button>
				</div>

				{#if showControls}
					<Card.Root class="mb-4 bg-white/95 p-3">
						<div class="mb-3 grid grid-cols-1 gap-3 md:grid-cols-2">
							<!-- Layout Mode -->
							<div>
								<label for="layout-select" class="mb-1 block text-xs font-medium text-gray-700"
									>Layout</label
								>
								<select
									id="layout-select"
									bind:value={layoutMode}
									class="h-8 rounded-md border border-gray-300 bg-white px-2 text-xs"
								>
									<option value="force">Force-directed</option>
									<option value="hierarchical">Hierarchical</option>
									<option value="clustered">Clustered</option>
								</select>
							</div>

							<!-- Filter by Type -->
							<div>
								<label for="type-select" class="mb-1 block text-xs font-medium text-gray-700"
									>Asset Type</label
								>
								<select
									id="type-select"
									bind:value={filterByType}
									class="h-8 rounded-md border border-gray-300 bg-white px-2 text-xs"
								>
									<option value="all">All Types</option>
									{#each getAssetTypes() as type}
										<option value={type}>{type.charAt(0).toUpperCase() + type.slice(1)}</option>
									{/each}
								</select>
							</div>

							<!-- Filter by Tag -->
							<div>
								<label for="tag-select" class="mb-1 block text-xs font-medium text-gray-700"
									>Tag</label
								>
								<select
									id="tag-select"
									bind:value={filterByTag}
									class="h-8 rounded-md border border-gray-300 bg-white px-2 text-xs"
								>
									<option value="all">All Tags</option>
									{#each getAllTags() as tag}
										<option value={tag}>{tag}</option>
									{/each}
								</select>
							</div>

							<!-- Filter by Status -->
							<div>
								<label for="status-select" class="mb-1 block text-xs font-medium text-gray-700"
									>Status</label
								>
								<select
									id="status-select"
									bind:value={filterByStatus}
									class="h-8 rounded-md border border-gray-300 bg-white px-2 text-xs"
								>
									<option value="all">All Statuses</option>
									{#each getAssetStatuses() as status}
										<option value={status}
											>{status.charAt(0).toUpperCase() + status.slice(1)}</option
										>
									{/each}
								</select>
							</div>
						</div>

						<!-- Search -->
						<div class="mb-3">
							<label for="search-input" class="mb-1 block text-xs font-medium text-gray-700"
								>Search</label
							>
							<Input
								id="search-input"
								bind:value={searchQuery}
								placeholder="Search assets..."
								class="h-8 text-xs"
							/>
						</div>

						<!-- Spacing and Visual Controls -->
						<div class="mb-3 grid grid-cols-1 gap-3 md:grid-cols-2">
							<!-- Node Spacing -->
							<div>
								<label for="spacing-select" class="mb-1 block text-xs font-medium text-gray-700"
									>Node Spacing</label
								>
								<select
									id="spacing-select"
									bind:value={nodeSpacing}
									class="h-8 rounded-md border border-gray-300 bg-white px-2 text-xs"
								>
									<option value="tight">Tight</option>
									<option value="normal">Normal</option>
									<option value="loose">Loose</option>
									<option value="very-loose">Very Loose</option>
								</select>
							</div>

							<!-- Edge Opacity -->
							<div>
								<label for="opacity-range" class="mb-1 block text-xs font-medium text-gray-700"
									>Edge Opacity</label
								>
								<div class="flex items-center gap-2">
									<input
										id="opacity-range"
										type="range"
										min="0.1"
										max="1"
										step="0.1"
										bind:value={edgeOpacity}
										class="h-2 flex-1 cursor-pointer appearance-none rounded-lg bg-gray-200"
									/>
									<span class="w-8 text-xs text-gray-600">{Math.round(edgeOpacity * 100)}%</span>
								</div>
							</div>
						</div>

						<!-- Toggle Controls -->
						<div class="flex items-center gap-4 text-xs">
							<label class="flex items-center gap-1">
								<input
									type="checkbox"
									bind:checked={physicsEnabled}
									class="rounded border-gray-300"
								/>
								<span>Physics</span>
							</label>
							<label class="flex items-center gap-1">
								<input type="checkbox" bind:checked={manualMode} class="rounded border-gray-300" />
								<span>Manual Mode</span>
							</label>
							<label class="flex items-center gap-1">
								<input
									type="checkbox"
									bind:checked={clusteringEnabled}
									disabled={layoutMode !== 'clustered'}
									class="rounded border-gray-300"
								/>
								<span>Clustering</span>
							</label>
						</div>
					</Card.Root>
				{/if}

				<div class="legend">
					<div class="legend-item">
						<Globe class="legend-icon" size={16} color="#4CAF50" />
						<span>Domains</span>
					</div>
					<div class="legend-item">
						<NetworkIcon class="legend-icon" size={16} color="#2196F3" />
						<span>Subdomains</span>
					</div>
					<div class="legend-item">
						<Server class="legend-icon" size={16} color="#FF9800" />
						<span>IP Addresses</span>
					</div>
					<div class="legend-item">
						<Shield class="legend-icon" size={16} color="#9C27B0" />
						<span>Services</span>
					</div>
				</div>

				<!-- Extended legend for tag-based icons -->
				<div class="legend mt-2 text-xs">
					<div class="legend-item">
						<Cloud class="legend-icon" size={14} color="#FF6B35" />
						<span>Cloudflare</span>
					</div>
					<div class="legend-item">
						<Lock class="legend-icon" size={14} color="#0F9D58" />
						<span>HTTPS</span>
					</div>
					<div class="legend-item">
						<Unlock class="legend-icon" size={14} color="#EA4335" />
						<span>HTTP</span>
					</div>
					<div class="legend-item">
						<Terminal class="legend-icon" size={14} color="#000000" />
						<span>SSH</span>
					</div>
					<div class="legend-item">
						<Mail class="legend-icon" size={14} color="#4285F4" />
						<span>Mail</span>
					</div>
				</div>

				<!-- Relationship legend -->
				<div class="legend mt-2 border-t border-gray-200 pt-2 text-xs">
					<div class="mb-1 text-xs font-medium text-gray-600">Relationships:</div>
					<div class="legend-item">
						<div class="h-0 w-4 border-t-2 border-blue-500"></div>
						<span>Hierarchy</span>
					</div>
					<div class="legend-item">
						<div class="h-0 w-4 border-t-2 border-green-500"></div>
						<span>DNS Records</span>
					</div>
					<div class="legend-item">
						<div class="h-0 w-4 border-t-2 border-purple-500"></div>
						<span>Services</span>
					</div>
					<div class="legend-item">
						<div class="h-0 w-4 border-t-2 border-dashed border-orange-500"></div>
						<span>CNAME</span>
					</div>
					<div class="legend-item">
						<div class="border-brown-500 h-0 w-4 border-t border-dotted"></div>
						<span>Shared Host</span>
					</div>
				</div>

				<!-- Asset Details Modal -->
				<AssetDetailsModal
					bind:open={modalOpen}
					bind:asset={selectedAsset}
					bind:assetDetails={selectedAssetDetails}
					bind:checklistItems={assetChecklistItems}
				/>
			</div>
		</div>

		<div class="overlay overlay-bottom">
			<div class="overlay-card">
				<div class="overlay-info">
					<span>Showing {getFilteredAssets().length} of {assets.length} assets</span>
				</div>
			</div>
		</div>
	{:else}
		<div class="empty-state">
			<div class="empty-state-card">
				<h3 class="empty-state-title">No assets found</h3>
				<p class="empty-state-description">Start discovery to visualize your network assets.</p>
			</div>
		</div>
	{/if}
</div>

<style>
	.asset-graph-root {
		position: fixed;
		top: 0;
		left: 4rem; /* 64px sidebar width */
		right: 0;
		bottom: 0;
		width: calc(100vw - 4rem);
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
	    max-width: 25rem;
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
		flex-shrink: 0;
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
		gap: 0.75rem;
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
		border-top: 1px solid rgba(0, 0, 0, 0.06);
	}

	.results {
		margin-top: 0.75rem;
		display: grid;
		gap: 0.5rem;
	}
	.results h3 {
		margin: 0;
		font-size: 0.95rem;
		font-weight: 600;
	}
	.result-item {
		border: 1px solid rgba(0, 0, 0, 0.08);
		border-radius: 8px;
		padding: 0.5rem;
		background: #fff;
	}
	.result-head {
		display: flex;
		justify-content: space-between;
		align-items: center;
		font-size: 0.9rem;
	}
	.result-head .script {
		font-weight: 600;
	}
	.result-head .status[data-ok='true'] {
		color: #059669;
	}
	.result-head .status[data-ok='false'] {
		color: #dc2626;
	}
	.result-head .decision {
		margin-left: 0.5rem;
		font-size: 0.75rem;
		padding: 2px 6px;
		border-radius: 999px;
		border: 1px solid rgba(0, 0, 0, 0.08);
	}
	.result-head .decision[data-decision='pass'] {
		background: #ecfdf5;
		color: #065f46;
		border-color: #a7f3d0;
	}
	.result-head .decision[data-decision='reject'] {
		background: #fef2f2;
		color: #7f1d1d;
		border-color: #fecaca;
	}
	.result-head .decision[data-decision='na'] {
		background: #f3f4f6;
		color: #374151;
		border-color: #e5e7eb;
	}
	.meta {
		display: flex;
		gap: 0.75rem;
		font-size: 0.75rem;
		color: #6b7280;
	}
	pre.output,
	pre.error,
	pre.metadata {
		margin: 0.25rem 0 0 0;
		max-height: 140px;
		overflow: auto;
		background: #f9fafb;
		padding: 0.5rem;
		border-radius: 6px;
	}
	pre.error {
		background: #fef2f2;
	}

	.live-indicator {
		margin-top: 0.25rem;
		font-size: 0.8rem;
		color: #2563eb;
	}

	/* Empty state styles */
	.empty-state {
		position: absolute;
		inset: 0;
		display: flex;
		align-items: center;
		justify-content: center;
		background: rgba(250, 250, 250, 0.9);
		z-index: 10;
	}

	.empty-state-card {
		background: white;
		border: 1px solid rgba(0, 0, 0, 0.06);
		border-radius: 12px;
		padding: 2rem;
		box-shadow: 0 10px 30px rgba(0, 0, 0, 0.08);
		text-align: center;
		max-width: 400px;
	}

	.empty-state-title {
		font-size: 1.5rem;
		font-weight: 600;
		color: #111827;
		margin: 0 0 0.5rem 0;
	}

	.empty-state-description {
		font-size: 1rem;
		color: #6b7280;
		margin: 0;
		line-height: 1.5;
	}

	/* Asset Tags Styles */
	.asset-tags {
		border: 1px solid #e5e7eb;
		border-radius: 8px;
		padding: 0.75rem;
		background: #f9fafb;
	}

	.asset-tags h4 {
		font-size: 0.875rem;
		font-weight: 600;
		color: #374151;
		margin: 0 0 0.5rem 0;
	}

	.tags-container {
		display: flex;
		flex-wrap: wrap;
		gap: 0.375rem;
	}

	.tag {
		display: inline-flex;
		align-items: center;
		padding: 0.25rem 0.5rem;
		font-size: 0.75rem;
		font-weight: 500;
		color: #1f2937;
		background: #e5e7eb;
		border-radius: 12px;
		border: 1px solid #d1d5db;
	}

	.tag:hover {
		background: #d1d5db;
	}

	/* DNS Records Styles */
	.dns-records {
		border: 1px solid #e5e7eb;
		border-radius: 8px;
		padding: 0.75rem;
		background: #f9fafb;
	}

	.dns-records h4 {
		font-size: 0.875rem;
		font-weight: 600;
		color: #374151;
		margin: 0 0 0.75rem 0;
	}

	.dns-container {
		display: grid;
		gap: 0.5rem;
	}

	.dns-record-type {
		display: grid;
		gap: 0.25rem;
	}

	.dns-record-type strong {
		font-size: 0.8125rem;
		font-weight: 600;
		color: #4b5563;
	}

	.dns-values {
		display: flex;
		flex-wrap: wrap;
		gap: 0.25rem;
	}

	.dns-value {
		display: inline-block;
		padding: 0.125rem 0.375rem;
		font-size: 0.75rem;
		font-family:
			'SF Mono', Monaco, 'Cascadia Code', 'Roboto Mono', Consolas, 'Courier New', monospace;
		color: #1f2937;
		background: #ffffff;
		border: 1px solid #d1d5db;
		border-radius: 4px;
		white-space: nowrap;
	}

	.dns-value.txt-record {
		max-width: 200px;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
	}

	.dns-value:hover {
		border-color: #9ca3af;
		background: #f3f4f6;
	}
</style>
