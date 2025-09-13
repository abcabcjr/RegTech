<script lang="ts">
	import { cn } from '$lib/utils';

	type Variant = 'default' | 'secondary' | 'destructive' | 'outline';
	type Size = 'sm' | 'md' | 'lg';

	interface Props {
		className?: string;
		variant?: Variant;
		size?: Size;
		children?: () => any;
	}

	let { 
		className = '', 
		variant = 'default', 
		size = 'md',
		children,
		...restProps 
	}: Props = $props();

	const variants = {
		default: 'bg-primary text-primary-foreground hover:bg-primary/80',
		secondary: 'bg-secondary text-secondary-foreground hover:bg-secondary/80',
		destructive: 'bg-destructive text-destructive-foreground hover:bg-destructive/80',
		outline: 'text-foreground border border-input'
	};

	const sizes = {
		sm: 'px-2 py-1 text-xs',
		md: 'px-2.5 py-0.5 text-sm',
		lg: 'px-3 py-1 text-base'
	};
</script>

<span
	class={cn(
		'inline-flex items-center rounded-full font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2',
		variants[variant],
		sizes[size],
		className
	)}
	{...restProps}
>
	{@render children?.()}
</span>
