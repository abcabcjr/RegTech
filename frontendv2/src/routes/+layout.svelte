<script lang="ts">
	import '../app.css';
	import favicon from '$lib/assets/favicon.svg';
	import Sidebar from '$lib/components/ui/Sidebar.svelte';
	import * as Tooltip from '$lib/components/ui/tooltip';

	let { children } = $props();
</script>

<svelte:head>
	<link rel="icon" href={favicon} />
</svelte:head>

<Tooltip.Provider>
	<div class="min-h-screen bg-gray-50">
		<!-- Sidebar -->
		<Sidebar />

		<!-- Main Content -->
		<main class="ml-16">
			{@render children?.()}
		</main>
	</div>
</Tooltip.Provider>
