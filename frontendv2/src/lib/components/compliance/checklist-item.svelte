<script lang="ts">
	import type { ChecklistItem, FileAttachment } from '$lib/types';
	import { StatusBadge } from '$lib/components/ui/status-badge';
	import { Button } from '$lib/components/ui/button';
	import * as Card from '$lib/components/ui/card';
	import Select from '$lib/components/ui/select/select.svelte';
	import { Textarea } from '$lib/components/ui/textarea';
	import { Input } from '$lib/components/ui/input';
	import { Badge } from '$lib/components/ui/badge';
	import { Tooltip } from '$lib/components/ui/tooltip';
	import InlineInfoPanel from './InlineInfoPanel.svelte';
	import FileUpload from './FileUpload.svelte';
	import { apiClient } from '$lib/api/client';
	import { getPdfGuide } from '$lib/data/pdf-guides';

	interface Props {
		item: ChecklistItem;
		onUpdate: (updates: Partial<ChecklistItem>) => void;
		readOnly?: boolean;
		updating?: boolean;
	}

	let { item, onUpdate, readOnly = false, updating = false }: Props = $props();

	let isExpanded = $state(true);
	let infoPanelOpen = $state(false);
	let attachments = $state<FileAttachment[]>([]);
	let loadingAttachments = $state(false);
	
	// Debug logging
	$effect(() => {
		console.log('Checklist item data:', {
			title: item.title,
			info: item.info,
			helpText: item.helpText,
			whyMatters: item.whyMatters
		});
	});
	let pdfGuide = $state<any | null>(null);

	// Load PDF guide when component mounts
	$effect(() => {
		pdfGuide = getPdfGuide(item.id);
	});

	function handleStatusChange(event: CustomEvent<{ value: string }>) {
		const status = event.detail.value as 'yes' | 'no' | 'na';
		onUpdate({ 
			status, 
			lastUpdated: new Date().toISOString(),
			// Clear justification if switching to "yes"
			...(status === "yes" && { justification: "" })
		});
	}

	function handleJustificationChange(event: Event) {
		const target = event.target as HTMLTextAreaElement;
		onUpdate({ justification: target.value, lastUpdated: new Date().toISOString() });
	}

	function handleEvidenceChange(event: Event) {
		const target = event.target as HTMLInputElement;
		onUpdate({ evidence: target.value, lastUpdated: new Date().toISOString() });
	}

	// Generate checklist key for this item
	let checklistKey = $derived(() => {
		// For global items, use format: global:{itemId}
		// For asset items, would be: asset:{assetId}:{itemId}
		return `global:${item.id}`;
	});

	// Load file attachments for this checklist item
	async function loadAttachments() {
		if (readOnly || isDisplayOnly) return; // Don't load attachments for read-only items
		
		loadingAttachments = true;
		try {
			const response = await fetch(`${apiClient.baseUrl}/files?checklistKey=${encodeURIComponent(checklistKey())}`);
			if (response.ok) {
				const attachmentSummaries = await response.json();
				attachments = attachmentSummaries;
			} else {
				console.warn('Failed to load attachments:', response.statusText);
				attachments = [];
			}
		} catch (error) {
			console.error('Failed to load attachments:', error);
			attachments = [];
		} finally {
			loadingAttachments = false;
		}
	}

	function handleFileUploaded(attachment: FileAttachment) {
		attachments = [...attachments, attachment];
		
		// Update the item's attachments list
		const currentAttachments = item.attachments || [];
		onUpdate({ 
			attachments: [...currentAttachments, attachment.id],
			lastUpdated: new Date().toISOString()
		});
	}

	function handleFileDeleted(fileId: string) {
		attachments = attachments.filter(a => a.id !== fileId);
		
		// Update the item's attachments list
		const currentAttachments = item.attachments || [];
		onUpdate({ 
			attachments: currentAttachments.filter(id => id !== fileId),
			lastUpdated: new Date().toISOString()
		});
	}

	// Load attachments when component mounts or item changes
	$effect(() => {
		loadAttachments();
	});

	let isDisplayOnly = $derived(item.category === "web" || item.category === "vulnerability" || readOnly);
	
	// Generate unique IDs for form controls
	const statusId = `status-${item.id}`;
	const justificationId = `justification-${item.id}`;
	const evidenceId = `evidence-${item.id}`;
</script>

<Card.Root class="transition-all duration-200 hover:shadow-md">
	<Card.Header class="pb-3">
		<div class="flex items-start justify-between">
			<div class="flex-1">
				<div class="flex items-center space-x-2">
					<Card.Title class="text-base font-medium">{item.title}</Card.Title>
					{#if item.required}
						<Badge variant="outline" class="text-xs">Required</Badge>
					{/if}
					{#if item.info?.priority === 'must'}
						<Badge variant="destructive" class="text-xs">Must</Badge>
					{:else if item.info?.priority === 'should'}
						<Badge variant="secondary" class="text-xs">Should</Badge>
					{/if}
				</div>
			</div>
			<div class="flex items-center space-x-2">
				<StatusBadge status={item.status} />
				{#if item.coveredAssets && item.coveredAssets.length > 0}
					<Badge variant="outline">
						{item.coveredAssets.length} asset{item.coveredAssets.length !== 1 ? 's' : ''}
					</Badge>
				{/if}
				<Button 
					variant="ghost" 
					size="sm"
					onclick={() => isExpanded = !isExpanded}
					class="flex items-center"
					title={isExpanded ? 'Collapse' : 'Expand'}
				>
					<svg 
						class="h-4 w-4 transition-transform duration-200 {isExpanded ? 'rotate-180' : ''}" 
						fill="none" 
						stroke="currentColor" 
						viewBox="0 0 24 24"
					>
						<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
					</svg>
				</Button>
			</div>
		</div>
	</Card.Header>

	{#if isExpanded}
		<Card.Content class="pt-0 space-y-4">

			{#if !isDisplayOnly}
				<div class="space-y-3">
					<div>
						<label for={statusId} class="text-sm font-medium mb-2 block">
							Compliance Status
							{#if updating}
								<span class="ml-2 text-xs text-muted-foreground">
									<div class="inline-block animate-spin rounded-full h-3 w-3 border-b border-current"></div>
									Saving...
								</span>
							{/if}
						</label>
						<Select
							id={statusId}
							value={item.status}
							placeholder="Select status"
							onchange={handleStatusChange}
							disabled={updating}
						>
							<option value="yes">Yes - Compliant</option>
							<option value="no">No - Non-Compliant</option>
							<option value="na">Not Applicable</option>
						</Select>
					</div>

					{#if item.status === "na"}
						<div>
							<label for={justificationId} class="text-sm font-medium mb-2 block">
								Justification <span class="text-destructive">*</span>
							</label>
							<Textarea
								id={justificationId}
								placeholder="Please explain why this requirement is not applicable to your organization..."
								value={item.justification || ""}
								onchange={handleJustificationChange}
								rows={3}
							/>
						</div>
					{/if}

					<div>
						<FileUpload
							checklistKey={checklistKey()}
							{attachments}
							onFileUploaded={handleFileUploaded}
							onFileDeleted={handleFileDeleted}
							readOnly={isDisplayOnly}
						/>
					</div>

					{#if item.evidence}
						<div>
							<label for={evidenceId} class="text-sm font-medium mb-2 block">Additional Notes</label>
							<Input
								id={evidenceId}
								placeholder="Additional evidence notes or references..."
								value={item.evidence || ""}
								onchange={handleEvidenceChange}
							/>
						</div>
					{/if}
				</div>
			{/if}

			<!-- Inline Information Panel -->
			<InlineInfoPanel 
				info={{
					overview: {
						what_it_means: (item.info?.whatItMeans) || item.helpText || "This compliance requirement helps ensure your organization meets cybersecurity standards and legal obligations.",
						why_it_matters: (item.info?.whyItMatters) || item.whyMatters || "Implementing this requirement protects your business from cyber threats and ensures regulatory compliance."
					},
					risks: {
						attack_vectors: [
							"Attackers could exploit missing security controls",
							"Weak implementation creates vulnerabilities",
							"Non-compliance exposes organization to penalties"
						],
						potential_impact: [
							"Data breaches and unauthorized access",
							"Business disruption and operational damage", 
							"Legal penalties and compliance violations",
							"Loss of customer trust and reputation damage"
						]
					},
					guide: {
						non_technical_steps: [
							"Review your current security policies and procedures",
							"Identify gaps between current state and requirements",
							"Develop an implementation plan with clear timelines",
							"Assign responsibility to specific team members",
							"Implement the required controls and processes",
							"Document all changes and maintain evidence",
							"Test and validate the implementation",
							"Schedule regular reviews and updates"
						]
					},
					media: {
						images: [],
						videos: [],
						schemas: []
					},
					legal: {
						requirement_summary: "This requirement is mandated by Moldova's Cybersecurity Law to protect critical infrastructure and sensitive data. Organizations must implement appropriate security measures and maintain proper documentation.",
						article_refs: (item.info?.lawRefs) || ["Art. 11 - Security Requirements", "NU-49-MDED-2025"],
						priority: (item.info?.priority) || "should"
					},
					resources: (item.info?.resources) || [
						{
							title: "Implementation Guide",
							url: "https://example.com/implementation-guide",
							type: "document",
							description: "Step-by-step guide for implementing this requirement"
						},
						{
							title: "Best Practices",
							url: "https://example.com/best-practices",
							type: "document", 
							description: "Industry best practices and recommendations"
						}
					],
					pdf_guide: pdfGuide
				}}
			/>

			{#if item.coveredAssets && item.coveredAssets.length > 0}
				<div class="mt-4">
					<h4 class="text-sm font-medium mb-3">Coverage</h4>
					<div class="space-y-2">
						{#each item.coveredAssets as asset}
							<div class="flex items-center justify-between p-3 bg-muted/30 rounded-md">
								<div class="flex items-center gap-3">
									<Badge variant="outline" class="text-xs">
										{asset.asset_type}
									</Badge>
									<span class="font-mono text-sm">{asset.asset_value}</span>
									{#if asset.notes}
										<span class="text-xs text-muted-foreground">{asset.notes}</span>
									{/if}
								</div>
							</div>
						{/each}
					</div>
				</div>
			{:else if item.kind === 'auto' && item.scope === 'asset'}
				<div class="text-sm text-muted-foreground p-3 bg-muted/20 rounded-md">
					No assets currently covered by this compliance check
				</div>
			{/if}

			{#if item.lastUpdated}
				<p class="text-xs text-muted-foreground">
					Last updated: {new Date(item.lastUpdated).toLocaleDateString()}
				</p>
			{/if}
		</Card.Content>
	{/if}
</Card.Root>

