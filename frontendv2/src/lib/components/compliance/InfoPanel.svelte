<script lang="ts">
	import type { InfoPanelData } from '$lib/guide/mapper';
	import { Button } from '$lib/components/ui/button';
	import * as Dialog from '$lib/components/ui/dialog';
	import * as Tabs from '$lib/components/ui/tabs';
	import { Badge } from '$lib/components/ui/badge';

	interface Props {
		open: boolean;
		title: string;
		info: InfoPanelData | null;
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
					<Tabs.List class="grid w-full grid-cols-5 mb-6">
						<Tabs.Trigger value="overview">Overview</Tabs.Trigger>
						<Tabs.Trigger value="risks">Risks</Tabs.Trigger>
						<Tabs.Trigger value="guide">Guide</Tabs.Trigger>
						<Tabs.Trigger value="legal">Legal</Tabs.Trigger>
						<Tabs.Trigger value="resources">Resources</Tabs.Trigger>
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
								{info.overview.what_it_means || '—'}
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
								{info.overview.why_it_matters || '—'}
							</p>
						</div>
					</Tabs.Content>

					<!-- Risks Tab -->
					<Tabs.Content value="risks" class="space-y-4">
						<div>
							<h3 class="text-lg font-semibold text-foreground mb-2 flex items-center gap-2">
								<svg class="h-4 w-4 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
								</svg>
								How attackers could use this
							</h3>
							{#if info.risks.attack_vectors.length > 0}
								<ul class="space-y-2">
									{#each info.risks.attack_vectors as vector}
										<li class="flex items-start gap-2">
											<svg class="h-4 w-4 text-red-500 mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
												<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
											</svg>
											<span class="text-muted-foreground text-sm">{vector}</span>
										</li>
									{/each}
								</ul>
							{:else}
								<p class="text-muted-foreground text-sm">—</p>
							{/if}
						</div>

						<div>
							<h3 class="text-lg font-semibold text-foreground mb-2 flex items-center gap-2">
								<svg class="h-4 w-4 text-orange-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
								</svg>
								Potential impact
							</h3>
							{#if info.risks.potential_impact.length > 0}
								<ul class="space-y-2">
									{#each info.risks.potential_impact as impact}
										<li class="flex items-start gap-2">
											<svg class="h-4 w-4 text-orange-500 mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
												<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
											</svg>
											<span class="text-muted-foreground text-sm">{impact}</span>
										</li>
									{/each}
								</ul>
							{:else}
								<p class="text-muted-foreground text-sm">—</p>
							{/if}
						</div>
					</Tabs.Content>

					<!-- Guide Tab -->
					<Tabs.Content value="guide" class="space-y-4">
						<div>
							<h3 class="text-lg font-semibold text-foreground mb-2 flex items-center gap-2">
								<svg class="h-4 w-4 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01" />
								</svg>
								How to address this (non-technical steps)
							</h3>
							<div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
								<p class="text-sm text-blue-800 mb-3 font-medium">
									💡 The platform explains what needs to be done, but doesn't automatically fix issues. Follow these steps to address this requirement:
								</p>
								{#if info.guide.non_technical_steps.length > 0}
									<ol class="space-y-2">
										{#each info.guide.non_technical_steps as step, index}
											<li class="flex items-start gap-3">
												<span class="bg-blue-600 text-white text-xs rounded-full w-5 h-5 flex items-center justify-center font-medium flex-shrink-0 mt-0.5">
													{index + 1}
												</span>
												<span class="text-blue-700 text-sm">{step}</span>
											</li>
										{/each}
									</ol>
								{:else}
									<p class="text-blue-700 text-sm">No specific steps available for this item.</p>
								{/if}
							</div>
						</div>
					</Tabs.Content>

					<!-- Legal Tab -->
					<Tabs.Content value="legal" class="space-y-4">
						<div>
							<h3 class="text-lg font-semibold text-foreground mb-2 flex items-center gap-2">
								<svg class="h-4 w-4 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 8l2 2 4-4" />
								</svg>
								Legal Requirement
							</h3>
							<div class="bg-red-50 border border-red-200 rounded-lg p-4">
								<p class="text-red-800 text-sm leading-relaxed">
									{info.legal.requirement_summary || '—'}
								</p>
							</div>
						</div>

						<div>
							<h3 class="text-lg font-semibold text-foreground mb-2 flex items-center gap-2">
								<svg class="h-4 w-4 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
								</svg>
								Article References
							</h3>
							{#if info.legal.article_refs && info.legal.article_refs.length > 0}
								<div class="flex flex-wrap gap-2">
									{#each info.legal.article_refs as ref}
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
							<Badge variant="outline" class={getPriorityColor(info.legal.priority)}>
								{getPriorityLabel(info.legal.priority)}
							</Badge>
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
											class="flex items-center gap-3 p-4 border rounded-lg hover:bg-muted/50 transition-colors group"
										>
											<div class="flex-shrink-0">
												{#if resource.type === 'video'}
													<div class="bg-red-100 p-2 rounded">
														<svg class="h-4 w-4 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
															<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14.828 14.828a4 4 0 01-5.656 0M9 10h1.01M15 10h1.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
														</svg>
													</div>
												{:else if resource.type === 'document'}
													<div class="bg-green-100 p-2 rounded">
														<svg class="h-4 w-4 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
															<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
														</svg>
													</div>
												{:else if resource.type === 'image'}
													<div class="bg-blue-100 p-2 rounded">
														<svg class="h-4 w-4 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
															<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
														</svg>
													</div>
												{:else if resource.type === 'schema'}
													<div class="bg-purple-100 p-2 rounded">
														<svg class="h-4 w-4 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
															<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01" />
														</svg>
													</div>
												{:else}
													<div class="bg-gray-100 p-2 rounded">
														<svg class="h-4 w-4 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
															<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
														</svg>
													</div>
												{/if}
											</div>
											<div class="flex-1">
												<div class="flex items-center gap-2 mb-1">
													<span class="text-sm font-medium text-blue-600 group-hover:text-blue-800 group-hover:underline">
														{resource.title}
													</span>
													{#if resource.type}
														<span class="bg-gray-100 text-gray-600 text-xs px-2 py-0.5 rounded-full capitalize">
															{resource.type}
														</span>
													{/if}
												</div>
												{#if resource.description}
													<p class="text-xs text-gray-600 mb-1">{resource.description}</p>
												{/if}
												<span class="text-xs text-muted-foreground">
													{resource.url}
												</span>
											</div>
											<svg class="h-4 w-4 text-muted-foreground group-hover:text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
												<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
											</svg>
										</a>
									{/each}
								</div>
							{:else}
								<p class="text-muted-foreground text-sm">No resources available for this item.</p>
							{/if}
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