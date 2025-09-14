import type {
	ModelDerivedChecklistItem,
	ModelChecklistItemTemplate,
	HandlerSetStatusRequest,
	HandlerUploadTemplatesRequest
} from '$lib/api/Api';
import { apiClient } from '$lib/api/client';

export class ChecklistStore {
	// Global checklist items
	globalItems: ModelDerivedChecklistItem[] = $state([]);
	globalLoading = $state(false);

	// Asset-specific checklist items (keyed by asset ID)
	assetItems: Record<string, ModelDerivedChecklistItem[]> = $state({});
	assetLoading: Record<string, boolean> = $state({});

	// Templates (now enhanced with covered assets)
	templates: ModelDerivedChecklistItem[] = $state([]);
	templatesLoading = $state(false);

	// Load global checklist items
	async loadGlobal() {
		if (this.globalLoading) return;
		this.globalLoading = true;
		try {
			const response = await apiClient.checklist.globalList();
			// Create a deep copy to avoid reference issues
			this.globalItems = JSON.parse(JSON.stringify(response.data || []));
		} catch (error) {
			console.error('Failed to load global checklist:', error);
			this.globalItems = [];
		} finally {
			this.globalLoading = false;
		}
	}

	// Load asset-specific checklist items
	async loadAsset(assetId: string) {
		if (this.assetLoading[assetId]) return;
		this.assetLoading[assetId] = true;
		try {
			const response = await apiClient.checklist.assetDetail(assetId);
			// Create a deep copy to avoid reference issues
			this.assetItems[assetId] = JSON.parse(JSON.stringify(response.data || []));
		} catch (error) {
			console.error(`Failed to load checklist for asset ${assetId}:`, error);
			this.assetItems[assetId] = [];
		} finally {
			this.assetLoading[assetId] = false;
		}
	}

	// Load templates
	async loadTemplates() {
		if (this.templatesLoading) return;
		this.templatesLoading = true;
		try {
			const response = await apiClient.checklist.templatesList();
			this.templates = response.data || [];
		} catch (error) {
			console.error('Failed to load checklist templates:', error);
			this.templates = [];
		} finally {
			this.templatesLoading = false;
		}
	}

	// Set status (much simpler!)
	async setStatus(itemId: string, assetId: string, status: 'yes' | 'no' | 'na', notes: string = '') {
		try {
			const response = await apiClient.checklist.statusCreate({
				item_id: itemId,
				asset_id: assetId || undefined,
				status: status,
				notes: notes
			});

			// Refresh the relevant checklist items
			if (!assetId) {
				await this.loadGlobal();
			} else {
				await this.loadAsset(assetId);
			}

			return response.data;
		} catch (error) {
			console.error('Failed to set checklist status:', error);
			throw error;
		}
	}


	// Upload templates from JSON file (overwrites all existing)
	async uploadTemplates(templates: ModelChecklistItemTemplate[]) {
		try {
			const response = await apiClient.checklist.templatesUploadCreate({
				templates: templates
			});

			// Refresh templates and global items (asset items will refresh when accessed)
			await this.loadTemplates();
			await this.loadGlobal();

			return response.data;
		} catch (error) {
			console.error('Failed to upload checklist templates:', error);
			throw error;
		}
	}

	// Get asset items for a specific asset (loads if not cached)
	async getAssetItems(assetId: string): Promise<ModelDerivedChecklistItem[]> {
		if (!this.assetItems[assetId] && !this.assetLoading[assetId]) {
			await this.loadAsset(assetId);
		}
		return this.assetItems[assetId] || [];
	}

	// Helper to get status color class
	getStatusColor(status?: string): string {
		switch (status) {
			case 'yes':
				return 'text-green-600 bg-green-50 border-green-200';
			case 'no':
				return 'text-red-600 bg-red-50 border-red-200';
			case 'na':
				return 'text-gray-600 bg-gray-50 border-gray-200';
			default:
				return 'text-gray-600 bg-gray-50 border-gray-200';
		}
	}

	// Helper to get status label
	getStatusLabel(status?: string): string {
		switch (status) {
			case 'yes':
				return 'Compliant';
			case 'no':
				return 'Non-Compliant';
			case 'na':
				return 'N/A';
			default:
				return 'Unknown';
		}
	}

	// Helper to get source label
	getSourceLabel(source?: string): string {
		switch (source) {
			case 'auto':
				return 'Automated';
			case 'manual':
				return 'Manual';
			default:
				return 'Unknown';
		}
	}
}

// Create and export the store instance
export const checklistStore = new ChecklistStore();
