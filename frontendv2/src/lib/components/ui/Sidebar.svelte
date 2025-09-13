<script lang="ts">
	import { page } from '$app/stores';
	import { CheckSquare, Network } from '@lucide/svelte';
	import * as Tooltip from '$lib/components/ui/tooltip';

	interface NavItem {
		href: string;
		icon: any;
		label: string;
	}

	const navItems: NavItem[] = [
		{
			href: '/compliance',
			icon: CheckSquare,
			label: 'Compliance'
		},
		{
			href: '/',
			icon: Network,
			label: 'Assets'
		}
	];

	function isActive(href: string): boolean {
		if (href === '/') {
			return $page.url.pathname === '/';
		}
		return $page.url.pathname.startsWith(href);
	}
</script>

<aside class="fixed left-0 top-0 z-40 h-screen w-16 bg-white border-r border-gray-200 shadow-sm">
	<!-- Logo/Brand -->
	<div class="flex h-16 items-center justify-center border-b border-gray-200">
		<div class="text-xl font-bold text-blue-600">RT</div>
	</div>

	<!-- Navigation -->
	<nav class="flex flex-col items-center space-y-2 p-2 pt-4">
		{#each navItems as item}
			<Tooltip.Root>
				<Tooltip.Trigger>
					<a
						href={item.href}
						class="flex h-12 w-12 items-center justify-center rounded-lg transition-colors {isActive(item.href)
							? 'bg-blue-100 text-blue-600'
							: 'text-gray-600 hover:bg-gray-100 hover:text-gray-900'}"
					>
						<svelte:component this={item.icon} class="h-6 w-6" />
					</a>
				</Tooltip.Trigger>
				<Tooltip.Content side="right" class="ml-2">
					<p>{item.label}</p>
				</Tooltip.Content>
			</Tooltip.Root>
		{/each}
	</nav>
</aside>
