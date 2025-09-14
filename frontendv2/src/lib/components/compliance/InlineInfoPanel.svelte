<script lang="ts">
	import type { InfoPanelData } from '$lib/guide/mapper';
	import { Button } from '$lib/components/ui/button';
	import * as Tabs from '$lib/components/ui/tabs';
	import { Badge } from '$lib/components/ui/badge';

	interface Props {
		info: InfoPanelData | null;
		expanded?: boolean;
		showHeader?: boolean;
	}

	let { info, expanded = false, showHeader = true }: Props = $props();
	let isExpanded = $state(expanded);
	let activeTab = $state('overview');

	$effect(() => {
		console.log('InlineInfoPanel received info:', info);
		if (info) {
			console.log('Guide data:', info.guide);
			console.log('Risks data:', info.risks);
			console.log('Legal data:', info.legal);
		}
	});
	
	function toggleExpanded() {
		isExpanded = !isExpanded;
	}

	function getPriorityColor(priority?: string) {
		switch (priority) {
			case 'critical':
				return 'bg-red-100 text-red-800 border-red-200';
			case 'high':
				return 'bg-orange-100 text-orange-800 border-orange-200';
			case 'medium':
				return 'bg-yellow-100 text-yellow-800 border-yellow-200';
			case 'low':
				return 'bg-green-100 text-green-800 border-green-200';
			default:
				return 'bg-gray-100 text-gray-800 border-gray-200';
		}
	}

	function getPriorityLabel(priority?: string, priority_number?: number) {
		if (priority_number) {
			const priorityText = priority === 'critical' ? 'Critical' : 
								priority === 'high' ? 'High' : 
								priority === 'medium' ? 'Medium' : 
								priority === 'low' ? 'Low' : '—';
			return `${priorityText} (P${priority_number})`;
		}
		switch (priority) {
			case 'critical':
				return 'Critical';
			case 'high':
				return 'High';
			case 'medium':
				return 'Medium';
			case 'low':
				return 'Low';
			default:
				return '—';
		}
	}
</script>

<div class="{showHeader ? 'border-t border-gray-200 mt-4' : ''}">
	{#if showHeader}
		<Button
			variant="ghost"
			onclick={toggleExpanded}
			class="w-full justify-between p-4 h-auto hover:bg-gray-50"
		>
			<div class="flex items-center gap-2">
				<svg class="h-5 w-5 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
					<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
				</svg>
				<span class="font-medium text-left">Detailed Compliance Guide</span>
			</div>
			<svg 
				class="h-5 w-5 transition-transform duration-200 {isExpanded ? 'rotate-180' : ''}" 
				fill="none" 
				stroke="currentColor" 
				viewBox="0 0 24 24"
			>
				<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
			</svg>
		</Button>
	{/if}

	{#if isExpanded || !showHeader}
		<div class="{showHeader ? 'border-t border-gray-100 bg-gray-50/50' : ''}">
			{#if info}
				<div class="p-4">
					<Tabs.Root value={activeTab} class="w-full">
					<Tabs.List class="grid w-full grid-cols-6 mb-4">
						<Tabs.Trigger value="overview">Overview</Tabs.Trigger>
						<Tabs.Trigger value="risks">Risks</Tabs.Trigger>
						<Tabs.Trigger value="guide">Guide</Tabs.Trigger>
						<Tabs.Trigger value="pdf">PDF Guide</Tabs.Trigger>
						<Tabs.Trigger value="legal">Legal</Tabs.Trigger>
						<Tabs.Trigger value="resources">Resources</Tabs.Trigger>
					</Tabs.List>

						<!-- Overview Tab -->
						<Tabs.Content value="overview" class="space-y-4 max-h-96 overflow-y-auto">
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
						<Tabs.Content value="risks" class="space-y-4 max-h-96 overflow-y-auto">
							<div>
								<h3 class="text-lg font-semibold text-foreground mb-2 flex items-center gap-2">
									<svg class="h-4 w-4 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
										<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
									</svg>
									How attackers could use this
								</h3>
								{#if info.risks?.attack_vectors && info.risks.attack_vectors.length > 0}
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
								{#if info.risks?.potential_impact && info.risks.potential_impact.length > 0}
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
						<Tabs.Content value="guide" class="space-y-4 max-h-96 overflow-y-auto">
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
									{#if info.guide?.non_technical_steps && info.guide.non_technical_steps.length > 0}
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

							{#if info.guide?.scope_caveats}
								<div>
									<h3 class="text-lg font-semibold text-foreground mb-2 flex items-center gap-2">
										<svg class="h-4 w-4 text-amber-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
											<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
										</svg>
										Scope Considerations
									</h3>
									<div class="bg-amber-50 border border-amber-200 rounded-lg p-4">
										<p class="text-amber-800 text-sm">{info.guide.scope_caveats}</p>
									</div>
								</div>
							{/if}

							{#if info.guide?.acceptance_summary}
								<div>
									<h3 class="text-lg font-semibold text-foreground mb-2 flex items-center gap-2">
										<svg class="h-4 w-4 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
											<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
										</svg>
										Evidence Requirements
									</h3>
									<div class="bg-green-50 border border-green-200 rounded-lg p-4">
										<p class="text-green-800 text-sm">{info.guide.acceptance_summary}</p>
									</div>
								</div>
							{/if}

							{#if info.guide?.faq && info.guide.faq.length > 0}
								<div>
									<h3 class="text-lg font-semibold text-foreground mb-2 flex items-center gap-2">
										<svg class="h-4 w-4 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
											<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
										</svg>
										Frequently Asked Questions
									</h3>
									<div class="space-y-3">
										{#each info.guide.faq as faq}
											<div class="bg-gray-50 border border-gray-200 rounded-lg p-4">
												<h4 class="font-medium text-gray-900 mb-2">{faq.q}</h4>
												<p class="text-gray-700 text-sm">{faq.a}</p>
											</div>
										{/each}
									</div>
								</div>
							{/if}
						</Tabs.Content>

						<!-- PDF Guide Tab -->
						<Tabs.Content value="pdf" class="space-y-4 max-h-96 overflow-y-auto">
							<div>
								<h3 class="text-lg font-semibold text-foreground mb-2 flex items-center gap-2">
									<svg class="h-4 w-4 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
										<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
									</svg>
									PDF Implementation Guide
								</h3>
								{#if info.pdf_guide}
									<div class="space-y-4">
										<div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
											<p class="text-sm text-blue-800 mb-3 font-medium">
												📄 Download the complete implementation guide for this compliance requirement:
											</p>
											<p class="text-blue-700 text-sm mb-4">{info.pdf_guide?.description || '—'}</p>
											
											<div class="flex flex-col sm:flex-row gap-3">
												<a 
													href={info.pdf_guide?.url || '#'} 
													target="_blank" 
													rel="noopener noreferrer"
													class="inline-flex items-center gap-2 bg-red-600 text-white px-4 py-2 rounded-lg font-medium hover:bg-red-700 transition-colors"
												>
													<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
														<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
													</svg>
													Download PDF Guide
												</a>
												
												<button
													onclick={() => info.pdf_guide?.url && window.open(info.pdf_guide.url, '_blank')}
													class="inline-flex items-center gap-2 bg-gray-100 text-gray-700 px-4 py-2 rounded-lg font-medium hover:bg-gray-200 transition-colors"
												>
													<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
														<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
														<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
													</svg>
													View in New Tab
												</button>
											</div>
										</div>

										{#if info.pdf_guide?.sections && info.pdf_guide.sections.length > 0}
											<div>
												<h4 class="text-md font-medium text-foreground mb-2">What's Included in This Guide</h4>
												<ul class="space-y-2">
													{#each info.pdf_guide.sections as section}
														<li class="flex items-start gap-2">
															<svg class="h-4 w-4 text-green-500 mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
																<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
															</svg>
															<span class="text-muted-foreground text-sm">{section}</span>
														</li>
													{/each}
												</ul>
											</div>
										{/if}

										{#if info.pdf_guide?.tips && info.pdf_guide.tips.length > 0}
											<div>
												<h4 class="text-md font-medium text-foreground mb-2">Quick Tips</h4>
												<div class="bg-amber-50 border border-amber-200 rounded-lg p-3">
													<ul class="space-y-1">
														{#each info.pdf_guide.tips as tip}
															<li class="flex items-start gap-2">
																<svg class="h-3 w-3 text-amber-500 mt-1 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
																	<path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd" />
																</svg>
																<span class="text-amber-700 text-sm">{tip}</span>
															</li>
														{/each}
													</ul>
												</div>
											</div>
										{/if}
									</div>
								{:else}
									<div class="text-center py-8">
										<svg class="h-12 w-12 text-muted-foreground mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
											<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
										</svg>
										<p class="text-muted-foreground">No PDF guide available for this requirement.</p>
										<p class="text-xs text-muted-foreground mt-2">PDF guides provide detailed implementation instructions and templates.</p>
									</div>
								{/if}
							</div>
						</Tabs.Content>

						<!-- Legal Tab -->
						<Tabs.Content value="legal" class="space-y-4 max-h-96 overflow-y-auto">
							<div>
								<h3 class="text-lg font-semibold text-foreground mb-2 flex items-center gap-2">
									<svg class="h-4 w-4 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
										<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 8l2 2 4-4" />
									</svg>
									Legal Requirement
								</h3>
								<div class="bg-red-50 border border-red-200 rounded-lg p-4">
									<p class="text-red-800 text-sm leading-relaxed">
										{info.legal?.requirement_summary || '—'}
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
								{#if info.legal?.article_refs && info.legal.article_refs.length > 0}
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
								<Badge variant="outline" class={getPriorityColor(info.legal?.priority || undefined)}>
									{getPriorityLabel(info.legal?.priority || undefined, info.legal?.priority_number)}
								</Badge>
							</div>
						</Tabs.Content>

						<!-- Resources Tab -->
						<Tabs.Content value="resources" class="space-y-4 max-h-96 overflow-y-auto">
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
				</div>
			{:else}
				<div class="text-center py-8">
					<svg class="h-12 w-12 text-muted-foreground mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
						<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
					</svg>
					<p class="text-muted-foreground">Loading detailed information...</p>
					<p class="text-xs text-muted-foreground mt-2">If this message persists, the backend may not be running or data may not be available.</p>
				</div>
			{/if}
		</div>
	{/if}
</div>
