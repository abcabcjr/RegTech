<script lang="ts">
	import type { InfoBlock } from '$lib/types';
	import { Button } from '$lib/components/ui/button';
	import * as Dialog from '$lib/components/ui/dialog';
	import * as Tabs from '$lib/components/ui/tabs';
	import { Badge } from '$lib/components/ui/badge';

	interface Props {
		open: boolean;
		title: string;
		info: InfoBlock | undefined;
		onClose: () => void;
	}

	let { open, title, info, onClose }: Props = $props();
	let activeTab = $state('overview');

	function getPriorityColor(priority?: string) {
		switch (priority) {
			case 'must':
				return 'bg-red-100 text-red-800 border-red-200';
			case 'should':
				return 'bg-yellow-100 text-yellow-800 border-yellow-200';
			default:
				return 'bg-gray-100 text-gray-800 border-gray-200';
		}
	}

	function getPriorityLabel(priority?: string) {
		switch (priority) {
			case 'must':
				return 'Must Have';
			case 'should':
				return 'Should Have';
			default:
				return '—';
		}
	}
</script>

<Dialog.Root bind:open>
	<Dialog.Content class="max-w-2xl max-h-[80vh] overflow-y-auto">
		<Dialog.Header>
			<Dialog.Title class="flex items-center gap-2">
				<svg class="h-5 w-5 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
					<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
				</svg>
				{title}
			</Dialog.Title>
			<Dialog.Description>
				Detailed information about this compliance requirement
			</Dialog.Description>
		</Dialog.Header>

		<div class="py-4">
			{#if info}
				<Tabs.Root value={activeTab} class="w-full">
					<Tabs.List class="grid w-full grid-cols-4 mb-6">
						<Tabs.Trigger value="overview">Overview</Tabs.Trigger>
						<Tabs.Trigger value="legal">Legal</Tabs.Trigger>
						<Tabs.Trigger value="resources">Resources</Tabs.Trigger>
						<Tabs.Trigger value="details">Details</Tabs.Trigger>
					</Tabs.List>

					<!-- Overview Tab -->
					<Tabs.Content value="overview" class="space-y-4">
						<div>
							<h3 class="text-lg font-semibold text-foreground mb-2 flex items-center gap-2">
								<svg class="h-4 w-4 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
								</svg>
								What it means
							</h3>
							<p class="text-muted-foreground leading-relaxed">
								{info.whatItMeans || '—'}
							</p>
						</div>

						<div>
							<h3 class="text-lg font-semibold text-foreground mb-2 flex items-center gap-2">
								<svg class="h-4 w-4 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
								</svg>
								Why it matters
							</h3>
							<p class="text-muted-foreground leading-relaxed">
								{info.whyItMatters || '—'}
							</p>
						</div>
					</Tabs.Content>

					<!-- Legal Tab -->
					<Tabs.Content value="legal" class="space-y-4">
						<div>
							<h3 class="text-lg font-semibold text-foreground mb-2 flex items-center gap-2">
								<svg class="h-4 w-4 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
								</svg>
								Legal References
							</h3>
							{#if info.lawRefs && info.lawRefs.length > 0}
								<div class="flex flex-wrap gap-2">
									{#each info.lawRefs as ref}
										<Badge variant="outline" class="text-xs">
											{ref}
										</Badge>
									{/each}
								</div>
							{:else}
								<p class="text-muted-foreground text-sm">—</p>
							{/if}
						</div>

						<div>
							<h3 class="text-lg font-semibold text-foreground mb-2 flex items-center gap-2">
								<svg class="h-4 w-4 text-orange-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
								</svg>
								Priority Level
							</h3>
							{#if info.priority}
								<Badge variant="outline" class={getPriorityColor(info.priority)}>
									{getPriorityLabel(info.priority)}
								</Badge>
							{:else}
								<p class="text-muted-foreground text-sm">—</p>
							{/if}
						</div>
					</Tabs.Content>

					<!-- Resources Tab -->
					<Tabs.Content value="resources" class="space-y-4">
						<div>
							<h3 class="text-lg font-semibold text-foreground mb-2 flex items-center gap-2">
								<svg class="h-4 w-4 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
								</svg>
								Helpful Resources
							</h3>
							{#if info.resources && info.resources.length > 0}
								<div class="space-y-3">
									{#each info.resources as resource}
										<a 
											href={resource.url} 
											target="_blank" 
											rel="noopener noreferrer"
											class="flex items-center gap-3 p-3 border rounded-lg hover:bg-muted/50 transition-colors"
										>
											<svg class="h-4 w-4 text-blue-600 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
												<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
											</svg>
											<span class="text-sm font-medium text-blue-600 hover:text-blue-800 hover:underline">
												{resource.title}
											</span>
										</a>
									{/each}
								</div>
							{:else}
								<p class="text-muted-foreground text-sm">No resources available for this item.</p>
							{/if}
						</div>
					</Tabs.Content>

					<!-- Details Tab -->
					<Tabs.Content value="details" class="space-y-4">
						<div class="grid grid-cols-2 gap-4">
							<div>
								<h4 class="text-sm font-medium text-foreground mb-1">Priority</h4>
								<p class="text-sm text-muted-foreground">
									{info.priority ? getPriorityLabel(info.priority) : '—'}
								</p>
							</div>
							<div>
								<h4 class="text-sm font-medium text-foreground mb-1">Legal References</h4>
								<p class="text-sm text-muted-foreground">
									{info.lawRefs?.length || 0} reference(s)
								</p>
							</div>
							<div>
								<h4 class="text-sm font-medium text-foreground mb-1">Resources</h4>
								<p class="text-sm text-muted-foreground">
									{info.resources?.length || 0} resource(s)
								</p>
							</div>
							<div>
								<h4 class="text-sm font-medium text-foreground mb-1">Status</h4>
								<p class="text-sm text-muted-foreground">
									{info.priority === 'must' ? 'Required' : 'Recommended'}
								</p>
							</div>
						</div>
					</Tabs.Content>
				</Tabs.Root>
			{:else}
				<div class="text-center py-8">
					<svg class="h-12 w-12 text-muted-foreground mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
						<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
					</svg>
					<p class="text-muted-foreground">No detailed information available for this item.</p>
				</div>
			{/if}
		</div>

		<Dialog.Footer>
			<Button variant="outline" onclick={onClose}>
				Close
			</Button>
		</Dialog.Footer>
	</Dialog.Content>
</Dialog.Root>