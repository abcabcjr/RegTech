<script lang="ts">
	import '../app.css';
	import favicon from '$lib/assets/favicon.svg';
	import { page } from '$app/stores';

	let { children } = $props();
</script>

<svelte:head>
	<link rel="icon" href={favicon} />
</svelte:head>

<div class="min-h-screen bg-gray-50">
	<!-- Navigation Header -->
	<nav class="bg-white shadow-sm border-b border-gray-200">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<div class="flex justify-between h-16">
				<div class="flex items-center">
					<div class="flex-shrink-0">
						<h1 class="text-xl font-bold text-gray-900">RegTech Scanner</h1>
					</div>
					<div class="ml-10 flex items-baseline space-x-4">
						<a 
							href="/" 
							class="px-3 py-2 rounded-md text-sm font-medium {$page.url.pathname === '/' ? 'bg-gray-100 text-gray-900' : 'text-gray-600 hover:text-gray-900 hover:bg-gray-50'}"
						>
							Asset Graph
						</a>
						<a 
							href="/compliance" 
							class="px-3 py-2 rounded-md text-sm font-medium {$page.url.pathname === '/compliance' ? 'bg-gray-100 text-gray-900' : 'text-gray-600 hover:text-gray-900 hover:bg-gray-50'}"
						>
							Compliance
						</a>
					</div>
				</div>
			</div>
		</div>
	</nav>

	<!-- Main Content -->
	<main>
		{@render children?.()}
	</main>
</div>
