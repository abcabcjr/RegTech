<script lang="ts">
	import { cn } from '$lib/utils';

	interface Props {
		className?: string;
		value?: number;
		size?: 'sm' | 'md' | 'lg';
	}

	let props: Props = $props();
	let { className = '', size = 'md', ...restProps } = props;

	const sizes = {
		sm: 'h-2',
		md: 'h-3',
		lg: 'h-4'
	};

	let percentage = $derived(Math.min(100, Math.max(0, props.value || 0)));

	// Generate gradient based on percentage
	let gradientColor = $derived(() => {
		if (percentage <= 0) return '#ef4444'; // Red
		if (percentage <= 25) return '#f97316'; // Orange-red
		if (percentage <= 50) return '#eab308'; // Yellow
		if (percentage <= 75) return '#84cc16'; // Yellow-green
		if (percentage <= 90) return '#22c55e'; // Green
		return '#16a34a'; // Dark green
	});
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
		class="h-full w-full flex-1 transition-all duration-300 ease-in-out"
		style="transform: translateX(-{100 - percentage}%); background-color: {gradientColor()};"
	></div>
</div>
