import type { V1AssetCatalogueResponse, V1JobStatusResponse, V1AssetDetails } from '$lib/api/Api';
import { apiClient } from '$lib/api/client';

export class AssetsStore {
	loading = $state(false);
	data: V1AssetCatalogueResponse | null = $state(null);
	jobId: string | null = $state(null);
	jobStatus: V1JobStatusResponse | null = $state(null);
	jobType: 'discover' | 'scan' | null = $state(null);
	jobRunning = $state(false);
	currentScanAssetId: string | null = $state(null);
	assetDetails: Record<string, V1AssetDetails> = $state({} as Record<string, V1AssetDetails>);

	#pollHandle: ReturnType<typeof setInterval> | null = null;
	#previousProgressCompleted: number = 0;

	async load() {
		if (this.loading) return;
		console.log('AssetStore.load() called - this will refresh asset catalogue');
		this.loading = true;
		try {
			const response = await apiClient.assets.catalogueList({});
			this.data = response.data;
			console.log('Asset catalogue refreshed, found', this.data?.assets?.length || 0, 'assets');
		} catch (error) {
			console.error('Failed to load assets:', error);
		} finally {
			this.loading = false;
		}
	}

	async discover(hosts: string[]) {
		try {
			const res = await apiClient.assets.discoverCreate({ hosts: hosts });
			this.jobId = res.data.job_id;
			this.jobType = 'discover';
			this.jobRunning = true;
			this.#previousProgressCompleted = 0; // Reset progress tracking
			this.#startJobPolling();
		} catch (error) {
			console.error('Failed to start discovery:', error);
		}
	}

	async scanAsset(assetId: string, scripts?: string[]) {
		try {
			this.currentScanAssetId = assetId;
			const res = await apiClient.assets.scanCreate2(assetId, { scripts });
			this.startTrackingJob(res.data.job_id, 'scan');
		} catch (error) {
			console.error('Failed to start asset scan:', error);
		}
	}

	async scanAll(scripts?: string[]) {
		try {
			const res = await apiClient.assets.scanCreate({ scripts });
			this.startTrackingJob(res.data.job_id, 'scan');
		} catch (error) {
			console.error('Failed to start scan all:', error);
		}
	}

	async loadAssetDetails(assetId: string) {
		try {
			const res = await apiClient.assets.assetsDetail(assetId);
			this.assetDetails[assetId] = res.data.asset;
		} catch (error) {
			console.error('Failed to load asset details:', error);
		}
	}

	startTrackingJob(jobId: string, type: 'discover' | 'scan') {
		this.jobId = jobId;
		this.jobType = type;
		this.jobRunning = true;
		this.#previousProgressCompleted = 0; // Reset progress tracking
		this.#startJobPolling();
	}

	#startJobPolling() {
		if (!this.jobId) return;
		this.#stopJobPolling();
		this.#pollHandle = setInterval(async () => {
			try {
				const res = await apiClient.jobs.jobsDetail(this.jobId!);
				this.jobStatus = res.data;
				this.jobRunning = res.data.status === 'pending' || res.data.status === 'running';
				
				// Check if progress has increased and refresh assets if so
				const currentCompleted = res.data.progress?.completed || 0;
				if (currentCompleted > this.#previousProgressCompleted) {
					this.#previousProgressCompleted = currentCompleted;
					// Refresh assets whenever progress increases
					void this.load();
				}
				
				// Refresh catalogue while job is active (for individual asset scans)
				if (this.jobRunning) {
					// Only refresh asset details during individual asset scanning
					if (this.currentScanAssetId && this.jobType === 'scan') {
						void this.loadAssetDetails(this.currentScanAssetId);
					}
				} else {
					this.#stopJobPolling();
					// Final refresh on completion
					if (this.jobType === 'discover') {
						void this.load();
						// Automatically start scan all after discovery completes
						setTimeout(() => {
							void this.scanAll();
						}, 1000); // Small delay to ensure discovery data is loaded
					} else if (this.jobType === 'scan') {
						// Refresh asset catalogue after scanning completes
						void this.load();
					}
					if (this.currentScanAssetId) {
						void this.loadAssetDetails(this.currentScanAssetId);
						this.currentScanAssetId = null; // Clear after completion
					}
				}
			} catch (error) {
				console.error('Failed to poll job status:', error);
				// stop polling on persistent errors
				this.#stopJobPolling();
			}
		}, 1500);
	}

	#stopJobPolling() {
		if (this.#pollHandle) {
			clearInterval(this.#pollHandle);
			this.#pollHandle = null;
		}
	}
}

export const assetStore = new AssetsStore();
