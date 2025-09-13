<script lang="ts">
	import { assetStore } from '$lib/stores/assets.svelte';
	import AssetGraph from '$lib/components/AssetGraph.svelte';
</script>

<AssetGraph assets={assetStore.data?.assets || []} />

{#if assetStore.loading}
	<div class="fullscreen-overlay">
		<div class="spinner"></div>
		<p class="mt-3 text-sm text-gray-700">Loading assets...</p>
	</div>
{/if}

<style>
	.fullscreen-overlay {
		position: fixed;
		top: 0;
		left: 4rem; /* Account for sidebar */
		right: 0;
		bottom: 0;
		display: flex;
		align-items: center;
		justify-content: center;
		background: rgba(250, 250, 250, 0.9);
		z-index: 20;
		text-align: center;
	}

	.spinner {
		width: 40px;
		height: 40px;
		border: 3px solid #e5e7eb;
		border-top-color: #3b82f6;
		border-radius: 50%;
		animation: spin 1s linear infinite;
	}

	@keyframes spin {
		from { transform: rotate(0deg); }
		to { transform: rotate(360deg); }
	}
</style>
