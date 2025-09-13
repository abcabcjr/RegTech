<script lang="ts">
	import { cn } from '$lib/utils';
	import { createEventDispatcher } from 'svelte';

	const dispatch = createEventDispatcher<{
		change: { value: string };
	}>();

	interface Props {
		className?: string;
		disabled?: boolean;
		value?: string;
		placeholder?: string;
		id?: string;
		onchange?: (event: CustomEvent<{ value: string }>) => void;
	}

	let { 
		className = '', 
		disabled = false, 
		value = '', 
		placeholder = 'Select an option...',
		id,
		onchange,
		...restProps 
	}: Props = $props();

	function handleChange(event: Event) {
		const target = event.target as HTMLSelectElement;
		value = target.value;
		const customEvent = new CustomEvent('change', { detail: { value: target.value } });
		dispatch('change', { value: target.value });
		if (onchange) {
			onchange(customEvent);
		}
	}
</script>

<select
	class={cn(
		'flex h-10 w-full items-center justify-between rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50',
		className
	)}
	{disabled}
	{placeholder}
	bind:value
	{id}
	onchange={handleChange}
	{...restProps}
>
	<slot />
</select>
