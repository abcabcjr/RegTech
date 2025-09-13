<script lang="ts">
	import type { ChecklistItem } from '$lib/types';
	import { StatusBadge } from '$lib/components/ui/status-badge';
	import { Button } from '$lib/components/ui/button';
	import * as Card from '$lib/components/ui/card';
	import Select from '$lib/components/ui/select/select.svelte';
	import { Textarea } from '$lib/components/ui/textarea';
	import { Input } from '$lib/components/ui/input';
	import { Badge } from '$lib/components/ui/badge';
	import { Tooltip } from '$lib/components/ui/tooltip';
	import InfoPanel from './InfoPanel.svelte';

	interface Props {
		item: ChecklistItem;
		onUpdate: (updates: Partial<ChecklistItem>) => void;
		readOnly?: boolean;
	}

	let { item, onUpdate, readOnly = false }: Props = $props();

	let isExpanded = $state(true);
	let infoPanelOpen = $state(false);

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
				<div class="flex items-center space-x-2 mb-2">
					<Card.Title class="text-base font-medium">{item.title}</Card.Title>
					{#if item.required}
						<Badge variant="outline" class="text-xs">Required</Badge>
					{/if}
					{#if isDisplayOnly}
						<Badge variant="secondary" class="text-xs">Auto-checked</Badge>
					{/if}
				</div>
				<p class="text-sm text-muted-foreground">{item.description}</p>
			</div>
			<div class="flex items-center space-x-2">
				<StatusBadge status={item.status} />
				{#if item.kind === 'auto'}
					<Badge variant="outline">
						Auto-scan
					</Badge>
				{/if}
				{#if item.coveredAssets && item.coveredAssets.length > 0}
					<Badge variant="outline">
						{item.coveredAssets.length} asset{item.coveredAssets.length !== 1 ? 's' : ''}
					</Badge>
				{/if}
				<Button 
					variant="ghost" 
					size="sm"
					onclick={() => infoPanelOpen = true}
					title="Detailed Information"
				>
					<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
						<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
					</svg>
				</Button>
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
			<div class="text-sm text-muted-foreground p-3 bg-muted/50 rounded-md">
				<strong>Help:</strong> {item.helpText}
			</div>

			{#if !isDisplayOnly}
				<div class="space-y-3">
					<div>
						<label for={statusId} class="text-sm font-medium mb-2 block">Compliance Status</label>
						<Select
							id={statusId}
							value={item.status}
							placeholder="Select status"
							onchange={handleStatusChange}
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
						<label for={evidenceId} class="text-sm font-medium mb-2 block">Evidence</label>
						<div class="flex items-center space-x-2">
							<svg class="h-4 w-4 text-muted-foreground" fill="none" stroke="currentColor" viewBox="0 0 24 24">
								<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
							</svg>
							<Input
								id={evidenceId}
								placeholder="Upload evidence file or enter reference..."
								value={item.evidence || ""}
								onchange={handleEvidenceChange}
							/>
						</div>
						<p class="text-xs text-muted-foreground mt-1">
							In a real implementation, this would allow file uploads
						</p>
					</div>
				</div>
			{/if}

			{#if item.status === "no" && item.recommendation}
				<div class="flex items-start space-x-2 p-3 bg-warning/10 border border-warning/20 rounded-md">
					<svg class="h-4 w-4 text-warning mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
						<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
					</svg>
					<div>
						<p class="text-sm font-medium text-warning">Recommendation</p>
						<p class="text-sm text-warning/80">{item.recommendation}</p>
					</div>
				</div>
			{/if}

			{#if item.coveredAssets && item.coveredAssets.length > 0}
				<div class="mt-4">
					<h4 class="text-sm font-medium mb-3">Asset Coverage</h4>
					<div class="space-y-2">
						{#each item.coveredAssets as asset}
							<div class="flex items-center justify-between p-3 bg-muted/30 rounded-md">
								<div class="flex items-center gap-3">
									<Badge variant="outline" class="text-xs">
										{asset.asset_type}
									</Badge>
									<span class="font-mono text-sm">{asset.asset_value}</span>
									{#if asset.notes}
										<span class="text-xs text-muted-foreground">- {asset.notes}</span>
									{/if}
								</div>
								<Badge variant={asset.status === 'yes' ? 'default' : 'destructive'} class="text-xs">
									{asset.status.toUpperCase()}
								</Badge>
							</div>
						{/each}
					</div>
				</div>
			{:else if item.kind === 'auto'}
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

<!-- Info Panel -->
<InfoPanel 
	open={infoPanelOpen}
	title={item.title}
	info={item.info}
	onClose={() => infoPanelOpen = false}
/>
