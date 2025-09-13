<script lang="ts">
	import { browser } from '$app/environment';
	import '../app.css';
	import favicon from '$lib/assets/favicon.svg';
	import Sidebar from '$lib/components/ui/Sidebar.svelte';
	import * as Tooltip from '$lib/components/ui/tooltip';
	import { assetStore } from '$lib/stores/assets.svelte';

	let { children } = $props();

	if (browser) assetStore.load();
</script>

<svelte:head>
	<link rel="icon" href={favicon} />
</svelte:head>

<Tooltip.Provider>
	<div class="min-h-screen bg-gray-50">
		<!-- Sidebar -->
		<Sidebar />

		<!-- Global Job Progress Overlay -->
		{#if assetStore.jobRunning}
			<div class="job-overlay">
				<div class="job-card">
					<div class="spinner small"></div>
					<div>
						<div class="job-title">{assetStore.jobType === 'discover' ? 'Discovery' : assetStore.jobType === 'scan' ? 'Scanning' : 'Job'} running</div>
						{#if assetStore.jobStatus && assetStore.jobType === 'scan'}
							<div class="job-sub">
								{assetStore.jobStatus.progress.completed}/{assetStore.jobStatus.progress.total}
								({Math.round((assetStore.jobStatus.progress.completed / Math.max(assetStore.jobStatus.progress.total, 1)) * 100)}%)
							</div>
						{/if}
					</div>
				</div>
			</div>
		{/if}

		<!-- Main Content -->
		<main class="ml-16">
			{@render children?.()}
		</main>
	</div>
</Tooltip.Provider>

<style>
	.job-overlay {
		position: fixed;
		top: 1rem;
		left: 50%;
		transform: translateX(-50%);
		z-index: 50;
		pointer-events: none;
	}

	.job-card {
		pointer-events: auto;
		display: flex;
		align-items: center;
		gap: 0.75rem;
		background: rgba(255, 255, 255, 0.95);
		backdrop-filter: blur(8px);
		-webkit-backdrop-filter: blur(8px);
		border: 1px solid rgba(0, 0, 0, 0.1);
		border-radius: 12px;
		padding: 0.875rem 1.125rem;
		box-shadow: 0 8px 32px rgba(0, 0, 0, 0.12);
		min-width: 200px;
	}

	.job-title {
		font-size: 0.875rem;
		font-weight: 600;
		color: #111827;
		margin: 0;
	}

	.job-sub {
		font-size: 0.75rem;
		color: #6b7280;
		margin-top: 0.25rem;
	}

	.spinner {
		width: 20px;
		height: 20px;
		border: 2px solid #e5e7eb;
		border-top: 2px solid #3b82f6;
		border-radius: 50%;
		animation: spin 1s linear infinite;
		flex-shrink: 0;
	}

	.spinner.small {
		width: 16px;
		height: 16px;
		border-width: 2px;
	}

	@keyframes spin {
		0% { transform: rotate(0deg); }
		100% { transform: rotate(360deg); }
	}
</style>
