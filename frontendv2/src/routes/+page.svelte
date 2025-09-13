<script lang="ts">
	import { browser } from '$app/environment';
	import { assetStore } from '$lib/stores/assets.svelte';
	import AssetGraph from '$lib/components/AssetGraph.svelte';

	if (browser) assetStore.load();
</script>

{#if assetStore.jobRunning}
	<div class="job-overlay">
		<div class="job-card">
			<div class="spinner small"></div>
			<div>
				<div class="job-title">{assetStore.jobType === 'discover' ? 'Discovery' : 'Job'} running</div>
				{#if assetStore.jobStatus}
					<div class="job-sub">
						{assetStore.jobStatus.progress.completed}/{assetStore.jobStatus.progress.total}
						({Math.round((assetStore.jobStatus.progress.completed / Math.max(assetStore.jobStatus.progress.total, 1)) * 100)}%)
					</div>
				{/if}
			</div>
		</div>
	</div>
{/if}

{#if !assetStore.loading}
	<AssetGraph assets={assetStore.data?.assets || []} />
{/if}

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

	.overlay-card {
		background: white;
		border: 1px solid rgba(0,0,0,0.06);
		border-radius: 10px;
		padding: 1rem 1.25rem;
		box-shadow: 0 10px 30px rgba(0,0,0,0.08);
	}

	.spinner {
		width: 40px;
		height: 40px;
		border: 3px solid #e5e7eb;
		border-top-color: #3b82f6;
		border-radius: 50%;
		animation: spin 1s linear infinite;
	}

	.spinner.small {
		width: 16px;
		height: 16px;
		border-width: 2px;
	}

	@keyframes spin {
		from { transform: rotate(0deg); }
		to { transform: rotate(360deg); }
	}

	.job-overlay {
		position: fixed;
		top: 1rem;
		left: calc(50% + 2rem); /* Center in available space after sidebar */
		transform: translateX(-50%);
		z-index: 50;
	}

	.job-card {
		display: flex;
		align-items: center;
		gap: 0.6rem;
		background: rgba(255, 255, 255, 0.9);
		border: 1px solid rgba(0,0,0,0.06);
		border-radius: 999px;
		padding: 0.4rem 0.75rem;
		box-shadow: 0 6px 20px rgba(0,0,0,0.08);
	}

	.job-title {
		font-size: 0.9rem;
		font-weight: 600;
		color: #111827;
		line-height: 1;
	}

	.job-sub {
		font-size: 0.75rem;
		color: #4b5563;
		line-height: 1;
	}
</style>
