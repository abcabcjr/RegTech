<script lang="ts">
	import type { InfoBlock } from '$lib/types';
	
	interface Props {
		info: InfoBlock;
		compact?: boolean;
	}
	
	let { info, compact = false }: Props = $props();

	// Helper function to format priority
	function getPriorityColor(priority?: 'must' | 'should') {
		switch (priority) {
			case 'must':
				return 'text-red-600 bg-red-50 border-red-200';
			case 'should':
				return 'text-amber-600 bg-amber-50 border-amber-200';
			default:
				return 'text-gray-600 bg-gray-50 border-gray-200';
		}
	}

	function getPriorityText(priority?: 'must' | 'should') {
		switch (priority) {
			case 'must':
				return 'Required';
			case 'should':
				return 'Recommended';
			default:
				return 'Optional';
		}
	}
</script>

<div class="bg-muted/30 border border-muted rounded-lg p-4 space-y-4">
	<!-- Header with Priority Badge -->
	<div class="flex items-center justify-between">
		<h4 class="font-medium text-sm text-muted-foreground uppercase tracking-wide">
			Compliance Information
		</h4>
		{#if info.priority}
			<span class="px-2 py-1 text-xs font-medium rounded border {getPriorityColor(info.priority)}">
				{getPriorityText(info.priority)}
			</span>
		{/if}
	</div>

	<!-- What It Means -->
	{#if info.whatItMeans && !compact}
		<div class="space-y-2">
			<h5 class="font-medium text-sm text-foreground">What It Means</h5>
			<p class="text-sm text-muted-foreground leading-relaxed">{info.whatItMeans}</p>
		</div>
	{/if}

	<!-- Why It Matters -->
	{#if info.whyItMatters}
		<div class="space-y-2">
			<h5 class="font-medium text-sm text-foreground">Why It Matters</h5>
			<p class="text-sm text-muted-foreground leading-relaxed">{info.whyItMatters}</p>
		</div>
	{/if}

	<!-- Legal References -->
	{#if info.lawRefs && info.lawRefs.length > 0}
		<div class="space-y-2">
			<h5 class="font-medium text-sm text-foreground">Legal References</h5>
			<div class="flex flex-wrap gap-2">
				{#each info.lawRefs as ref}
					<span class="px-2 py-1 bg-blue-50 text-blue-700 border border-blue-200 rounded text-xs font-mono">
						{ref}
					</span>
				{/each}
			</div>
		</div>
	{/if}

	<!-- Non-Technical Steps -->
	{#if info.guide?.non_technical_steps && info.guide.non_technical_steps.length > 0 && !compact}
		<div class="space-y-2">
			<h5 class="font-medium text-sm text-foreground">Implementation Steps</h5>
			<ul class="space-y-1">
				{#each info.guide.non_technical_steps as step}
					<li class="text-sm text-muted-foreground flex items-start">
						<span class="w-1.5 h-1.5 bg-primary rounded-full mt-2 mr-3 flex-shrink-0"></span>
						{step}
					</li>
				{/each}
			</ul>
		</div>
	{/if}

	<!-- Resources -->
	{#if info.resources && info.resources.length > 0 && !compact}
		<div class="space-y-2">
			<h5 class="font-medium text-sm text-foreground">Resources</h5>
			<div class="space-y-1">
				{#each info.resources as resource}
					<a 
						href={resource.url} 
						target="_blank" 
						rel="noopener noreferrer"
						class="block text-sm text-blue-600 hover:text-blue-800 hover:underline"
					>
						{resource.title}
						<svg class="inline w-3 h-3 ml-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
							<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
						</svg>
					</a>
				{/each}
			</div>
		</div>
	{/if}

	<!-- Scope Caveats -->
	{#if info.guide?.scope_caveats && !compact}
		<div class="space-y-2">
			<h5 class="font-medium text-sm text-foreground">Scope & Limitations</h5>
			<div class="bg-yellow-50 border border-yellow-200 rounded p-3">
				<p class="text-sm text-yellow-800">{info.guide.scope_caveats}</p>
			</div>
		</div>
	{/if}

	<!-- Acceptance Summary -->
	{#if info.guide?.acceptance_summary && !compact}
		<div class="space-y-2">
			<h5 class="font-medium text-sm text-foreground">Acceptance Criteria</h5>
			<div class="bg-green-50 border border-green-200 rounded p-3">
				<p class="text-sm text-green-800">{info.guide.acceptance_summary}</p>
			</div>
		</div>
	{/if}

	<!-- FAQ -->
	{#if info.guide?.faq && info.guide.faq.length > 0 && !compact}
		<div class="space-y-2">
			<h5 class="font-medium text-sm text-foreground">Frequently Asked Questions</h5>
			<div class="space-y-3">
				{#each info.guide.faq as faqItem}
					<div class="border-l-2 border-blue-200 pl-3">
						<p class="font-medium text-sm text-foreground">{faqItem.q}</p>
						<p class="text-sm text-muted-foreground mt-1">{faqItem.a}</p>
					</div>
				{/each}
			</div>
		</div>
	{/if}
</div>

<style>
	/* Ensure external link icon is properly sized */
	svg {
		display: inline-block;
		vertical-align: text-top;
	}
</style>