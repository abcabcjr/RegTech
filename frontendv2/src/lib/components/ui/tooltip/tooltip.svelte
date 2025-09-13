<script lang="ts">
	import { cn } from '$lib/utils';
	import { createEventDispatcher } from 'svelte';

	const dispatch = createEventDispatcher();

	interface Props {
		className?: string;
		content?: string;
		show?: boolean;
		children?: {
			trigger?: () => any;
			default?: () => any;
		};
	}

	let { 
		className = '', 
		content = '', 
		show = false,
		children
	}: Props = $props();

	let trigger: HTMLElement;
	let tooltip: HTMLElement = $state();

	function handleMouseEnter() {
		show = true;
	}

	function handleMouseLeave() {
		show = false;
	}

	function handleClickOutside(event: MouseEvent) {
		if (tooltip && !tooltip.contains(event.target as Node) && !trigger.contains(event.target as Node)) {
			show = false;
		}
	}
</script>

<svelte:window onclick={handleClickOutside} />

<div class="relative inline-block" bind:this={trigger}>
	<div
		onmouseenter={handleMouseEnter}
		onmouseleave={handleMouseLeave}
		onclick={() => (show = !show)}
		role="button"
		tabindex="0"
		onkeydown={(e) => {
			if (e.key === 'Enter' || e.key === ' ') {
				e.preventDefault();
				show = !show;
			}
		}}
	>
		{@render children?.trigger?.()}
	</div>

	{#if show}
		<div
			bind:this={tooltip}
			class={cn(
				'absolute z-50 w-auto max-w-xs rounded-md border bg-popover px-3 py-1.5 text-sm text-popover-foreground shadow-md animate-in fade-in-0 zoom-in-95',
				className
			)}
			role="tooltip"
		>
			{content}
			{@render children?.default?.()}
		</div>
	{/if}
</div>
