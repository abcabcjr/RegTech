import type {
	V1BusinessUnitResponse,
	V1CreateBusinessUnitRequest,
	V1UpdateBusinessUnitRequest,
	V1ListBusinessUnitsResponse
} from '$lib/api/Api';
import { apiClient } from '$lib/api/client';

export class BusinessUnitsStore {
	// State
	businessUnits: V1BusinessUnitResponse[] = $state([]);
	loading = $state(false);
	error: string | null = $state(null);
	
	// Currently selected business unit for compliance view
	selectedBusinessUnit: V1BusinessUnitResponse | null = $state(null);
	
	// Computed
	get hasBusinessUnits() {
		return this.businessUnits.length > 0;
	}
	
	get sortedBusinessUnits() {
		return [...this.businessUnits].sort((a, b) => a.name.localeCompare(b.name));
	}
	
	// Actions
	async load() {
		if (this.loading) return;
		this.loading = true;
		this.error = null;
		
		try {
			const response = await apiClient.businessUnits.businessUnitsList();
			// Deep copy to avoid reference issues
			this.businessUnits = JSON.parse(JSON.stringify(response.data?.businessUnits || []));
			
			// If no business unit is selected and we have business units, select the first one
			if (!this.selectedBusinessUnit && this.businessUnits.length > 0) {
				this.selectedBusinessUnit = this.businessUnits[0];
				console.log('🏢 Auto-selected business unit:', this.selectedBusinessUnit.name);
			}
		} catch (error) {
			console.error('Failed to load business units:', error);
			this.error = error instanceof Error ? error.message : 'Unknown error';
			this.businessUnits = [];
		} finally {
			this.loading = false;
		}
	}
	
	async create(name: string) {
		try {
			const request: V1CreateBusinessUnitRequest = { name };
			const response = await apiClient.businessUnits.businessUnitsCreate(request);
			await this.load(); // Refresh data
			return response.data;
		} catch (error) {
			console.error('Failed to create business unit:', error);
			throw error;
		}
	}
	
	async createWithDetails(request: V1CreateBusinessUnitRequest) {
		try {
			const response = await apiClient.businessUnits.businessUnitsCreate(request);
			await this.load(); // Refresh data
			return response.data;
		} catch (error) {
			console.error('Failed to create business unit:', error);
			throw error;
		}
	}
	
	async update(id: string, name: string) {
		try {
			const request: V1UpdateBusinessUnitRequest = { name };
			const response = await apiClient.businessUnits.businessUnitsUpdate(id, request);
			await this.load(); // Refresh data
			
			// Update selected business unit if it was the one being updated
			if (this.selectedBusinessUnit?.id === id) {
				this.selectedBusinessUnit = this.businessUnits.find(bu => bu.id === id) || null;
			}
			
			return response.data;
		} catch (error) {
			console.error('Failed to update business unit:', error);
			throw error;
		}
	}
	
	async updateWithDetails(id: string, request: V1UpdateBusinessUnitRequest) {
		try {
			const response = await apiClient.businessUnits.businessUnitsUpdate(id, request);
			await this.load(); // Refresh data
			
			// Update selected business unit if it was the one being updated
			if (this.selectedBusinessUnit?.id === id) {
				this.selectedBusinessUnit = this.businessUnits.find(bu => bu.id === id) || null;
			}
			
			return response.data;
		} catch (error) {
			console.error('Failed to update business unit:', error);
			throw error;
		}
	}
	
	async delete(id: string) {
		try {
			await apiClient.businessUnits.businessUnitsDelete(id);
			
			// If we're deleting the selected business unit, select another one
			if (this.selectedBusinessUnit?.id === id) {
				const remainingUnits = this.businessUnits.filter(bu => bu.id !== id);
				this.selectedBusinessUnit = remainingUnits.length > 0 ? remainingUnits[0] : null;
			}
			
			await this.load(); // Refresh data
		} catch (error) {
			console.error('Failed to delete business unit:', error);
			throw error;
		}
	}
	
	// Select a business unit for compliance view
	selectBusinessUnit(businessUnit: V1BusinessUnitResponse | null) {
		this.selectedBusinessUnit = businessUnit;
	}
	
	// Get business unit by ID
	getById(id: string): V1BusinessUnitResponse | undefined {
		return this.businessUnits.find(bu => bu.id === id);
	}
}

// Export singleton instance
export const businessUnitsStore = new BusinessUnitsStore();
