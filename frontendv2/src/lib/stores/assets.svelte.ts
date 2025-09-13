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

	async load() {
		if (this.loading) return;
		this.loading = true;
		try {
			const response = await apiClient.assets.catalogueList({});
			this.data = response.data;
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
				// Refresh catalogue while job is active
				if (this.jobRunning) {
					void this.load();
					if (this.currentScanAssetId) {
						void this.loadAssetDetails(this.currentScanAssetId);
					}
				} else {
					this.#stopJobPolling();
					// One final refresh on completion
					void this.load();
					if (this.currentScanAssetId) {
						void this.loadAssetDetails(this.currentScanAssetId);
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
