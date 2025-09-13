<script lang="ts">
	import { cn } from '$lib/utils';

	interface Props {
		className?: string;
		value?: number;
		size?: 'sm' | 'md' | 'lg';
	}

	let { className = '', value = 0, size = 'md', ...restProps }: Props = $props();

	const sizes = {
		sm: 'h-2',
		md: 'h-3',
		lg: 'h-4'
	};

	let percentage = $derived(Math.min(100, Math.max(0, value)));
</script>

<div
	class={cn(
		'relative w-full overflow-hidden rounded-full bg-secondary',
		sizes[size],
		className
	)}
	{...restProps}
>
	<div
		class="h-full w-full flex-1 bg-primary transition-all duration-300 ease-in-out"
		style="transform: translateX(-{100 - percentage}%)"
	></div>
</div>
