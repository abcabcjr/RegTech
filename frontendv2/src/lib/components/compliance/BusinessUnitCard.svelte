<script lang="ts">
	import type { V1BusinessUnitResponse } from '$lib/api/Api';
	import { businessUnitsStore } from '$lib/stores/businessUnits.svelte';
	import { Button } from '$lib/components/ui/button';
	import * as Card from '$lib/components/ui/card';
	import * as Dialog from '$lib/components/ui/dialog';
	import * as Select from '$lib/components/ui/select';
	import { Input } from '$lib/components/ui/input';
	import { Label } from '$lib/components/ui/label';
	import { Badge } from '$lib/components/ui/badge';
	import { Building, Plus, Edit, Trash2, Users } from '@lucide/svelte';
	import { browser } from '$app/environment';

	// Props
	let { 
		onBusinessUnitChange 
	}: { 
		onBusinessUnitChange?: () => Promise<void> | void;
	} = $props();

	// Dialog states
	let createDialogOpen = $state(false);
	let editDialogOpen = $state(false);
	let deleteDialogOpen = $state(false);

	// Form states
	let newBusinessUnitName = $state('');
	let editBusinessUnitName = $state('');
	let businessUnitToEdit: V1BusinessUnitResponse | null = $state(null);
	let businessUnitToDelete: V1BusinessUnitResponse | null = $state(null);
	
	// New business unit form fields
	let newLegalEntityName = $state('');
	let newRegistrationCode = $state('');
	let newInternalCode = $state('');
	let newSector = $state('');
	let newSubsector = $state('');
	let newCompanySizeBand = $state('');
	let newHeadcountRange = $state('');
	let newCountry = $state('');
	let newAddress = $state('');
	let newTimezone = $state('');
	let newPrimaryDomain = $state('');
	let newOtherDomainsCount = $state(0);
	let newFurnizorServicii = $state<boolean | undefined>(undefined);
	let newFurnizorDate = $state('');
	
	// Edit business unit form fields
	let editLegalEntityName = $state('');
	let editRegistrationCode = $state('');
	let editInternalCode = $state('');
	let editSector = $state('');
	let editSubsector = $state('');
	let editCompanySizeBand = $state('');
	let editHeadcountRange = $state('');
	let editCountry = $state('');
	let editAddress = $state('');
	let editTimezone = $state('');
	let editPrimaryDomain = $state('');
	let editOtherDomainsCount = $state(0);
	let editFurnizorServicii = $state<boolean | undefined>(undefined);
	let editFurnizorDate = $state('');

	// Loading states
	let creating = $state(false);
	let updating = $state(false);
	let deleting = $state(false);

	// Error states
	let createError = $state('');
	let editError = $state('');
	let deleteError = $state('');

	// Load business units on mount
    if (browser)
	    businessUnitsStore.load();

	// Handle create business unit
	async function handleCreate() {
		if (!newBusinessUnitName.trim()) return;
		
		creating = true;
		createError = '';
		
		try {
			const request = {
				name: newBusinessUnitName.trim(),
				legalEntityName: newLegalEntityName.trim() || undefined,
				registrationCode: newRegistrationCode.trim() || undefined,
				internalCode: newInternalCode.trim() || undefined,
				sector: newSector.trim() || undefined,
				subsector: newSubsector.trim() || undefined,
				companySizeBand: newCompanySizeBand.trim() || undefined,
				headcountRange: newHeadcountRange.trim() || undefined,
				country: newCountry.trim() || undefined,
				address: newAddress.trim() || undefined,
				timezone: newTimezone.trim() || undefined,
				primaryDomain: newPrimaryDomain.trim() || undefined,
				otherDomainsCount: newOtherDomainsCount || undefined,
				furnizorServicii: newFurnizorServicii,
				furnizorDate: newFurnizorDate.trim() || undefined
			};
			
			await businessUnitsStore.createWithDetails(request);
			
			// Reset form
			newBusinessUnitName = '';
			newLegalEntityName = '';
			newRegistrationCode = '';
			newInternalCode = '';
			newSector = '';
			newSubsector = '';
			newCompanySizeBand = '';
			newHeadcountRange = '';
			newCountry = '';
			newAddress = '';
			newTimezone = '';
			newPrimaryDomain = '';
			newOtherDomainsCount = 0;
			newFurnizorServicii = undefined;
			newFurnizorDate = '';
			
			createDialogOpen = false;
		} catch (error) {
			createError = error instanceof Error ? error.message : 'Failed to create business unit';
		} finally {
			creating = false;
		}
	}

	// Handle edit business unit
	async function handleEdit() {
		if (!businessUnitToEdit || !editBusinessUnitName.trim()) return;
		
		updating = true;
		editError = '';
		
		try {
			const request = {
				name: editBusinessUnitName.trim(),
				legalEntityName: editLegalEntityName.trim() || undefined,
				registrationCode: editRegistrationCode.trim() || undefined,
				internalCode: editInternalCode.trim() || undefined,
				sector: editSector.trim() || undefined,
				subsector: editSubsector.trim() || undefined,
				companySizeBand: editCompanySizeBand.trim() || undefined,
				headcountRange: editHeadcountRange.trim() || undefined,
				country: editCountry.trim() || undefined,
				address: editAddress.trim() || undefined,
				timezone: editTimezone.trim() || undefined,
				primaryDomain: editPrimaryDomain.trim() || undefined,
				otherDomainsCount: editOtherDomainsCount || undefined,
				furnizorServicii: editFurnizorServicii,
				furnizorDate: editFurnizorDate.trim() || undefined
			};
			
			await businessUnitsStore.updateWithDetails(businessUnitToEdit.id, request);
			
			// Reset form
			editBusinessUnitName = '';
			editLegalEntityName = '';
			editRegistrationCode = '';
			editInternalCode = '';
			editSector = '';
			editSubsector = '';
			editCompanySizeBand = '';
			editHeadcountRange = '';
			editCountry = '';
			editAddress = '';
			editTimezone = '';
			editPrimaryDomain = '';
			editOtherDomainsCount = 0;
			editFurnizorServicii = undefined;
			editFurnizorDate = '';
			
			businessUnitToEdit = null;
			editDialogOpen = false;
		} catch (error) {
			editError = error instanceof Error ? error.message : 'Failed to update business unit';
		} finally {
			updating = false;
		}
	}
	
	// Populate edit form with business unit data
	function populateEditForm(businessUnit: V1BusinessUnitResponse) {
		editBusinessUnitName = businessUnit.name;
		editLegalEntityName = businessUnit.legalEntityName || '';
		editRegistrationCode = businessUnit.registrationCode || '';
		editInternalCode = businessUnit.internalCode || '';
		editSector = businessUnit.sector || '';
		editSubsector = businessUnit.subsector || '';
		editCompanySizeBand = businessUnit.companySizeBand || '';
		editHeadcountRange = businessUnit.headcountRange || '';
		editCountry = businessUnit.country || '';
		editAddress = businessUnit.address || '';
		editTimezone = businessUnit.timezone || '';
		editPrimaryDomain = businessUnit.primaryDomain || '';
		editOtherDomainsCount = businessUnit.otherDomainsCount || 0;
		editFurnizorServicii = businessUnit.furnizorServicii;
		editFurnizorDate = businessUnit.furnizorDate || '';
	}

	// Handle delete business unit
	async function handleDelete() {
		if (!businessUnitToDelete) return;
		
		deleting = true;
		deleteError = '';
		
		try {
			await businessUnitsStore.delete(businessUnitToDelete.id);
			deleteDialogOpen = false;
			businessUnitToDelete = null;
		} catch (error) {
			deleteError = error instanceof Error ? error.message : 'Failed to delete business unit';
		} finally {
			deleting = false;
		}
	}

	// Open edit dialog
	function openEditDialog(businessUnit: V1BusinessUnitResponse) {
		businessUnitToEdit = businessUnit;
		populateEditForm(businessUnit);
		editError = '';
		editDialogOpen = true;
	}

	// Open delete dialog
	function openDeleteDialog(businessUnit: V1BusinessUnitResponse) {
		businessUnitToDelete = businessUnit;
		deleteError = '';
		deleteDialogOpen = true;
	}

	// Handle business unit selection
	async function handleBusinessUnitSelect(selectedValue: string) {
		if (selectedValue === 'global') {
			businessUnitsStore.selectBusinessUnit(null);
		} else {
			const businessUnit = businessUnitsStore.getById(selectedValue);
			if (businessUnit) {
				businessUnitsStore.selectBusinessUnit(businessUnit);
			}
		}
		
		// Call the callback to reload data
		if (onBusinessUnitChange) {
			await onBusinessUnitChange();
		}
	}

	// Handle select change
	function handleSelectChange(selected: any) {
		if (selected && selected.value) {
			handleBusinessUnitSelect(selected.value);
		}
	}
</script>

<Card.Root>
	<Card.Header>
		<div class="flex items-center justify-between">
			<div class="flex items-center space-x-2">
				<Building class="h-5 w-5 text-blue-600" />
				<Card.Title>Business Units</Card.Title>
			</div>
			<Button 
				size="sm" 
				onclick={() => createDialogOpen = true}
				disabled={businessUnitsStore.loading}
			>
				<Plus class="h-4 w-4 mr-1" />
				New Unit
			</Button>
		</div>
		<Card.Description>
			Manage business units and switch between compliance contexts
		</Card.Description>
	</Card.Header>
	
	<Card.Content class="space-y-4">
		{#if businessUnitsStore.loading}
			<div class="flex items-center justify-center py-8">
				<div class="text-sm text-gray-500">Loading business units...</div>
			</div>
		{:else if businessUnitsStore.error}
			<div class="bg-red-50 border border-red-200 rounded-md p-3">
				<div class="text-sm text-red-600">{businessUnitsStore.error}</div>
			</div>
		{:else}
			<!-- Business Unit Selector -->
			<div class="space-y-2">
				<Label for="business-unit-select">Current Business Unit</Label>
				<Select.Root type="single">
					<Select.Trigger>
						{businessUnitsStore.selectedBusinessUnit?.name || 'Global (Organization-wide)'}
					</Select.Trigger>
					<Select.Content>
						{#each businessUnitsStore.sortedBusinessUnits as businessUnit (businessUnit.id)}
							<Select.Item value={businessUnit.id} onclick={() => handleBusinessUnitSelect(businessUnit.id)}>
								<div class="flex items-center space-x-2">
									<Building class="h-4 w-4" />
									<span>{businessUnit.name}</span>
								</div>
							</Select.Item>
						{/each}
					</Select.Content>
				</Select.Root>
			</div>

			<!-- Current Selection Display -->
			<div class="bg-blue-50 border border-blue-200 rounded-md p-3">
				<div class="flex items-center justify-between">
					<div class="flex items-center space-x-2">
						{#if businessUnitsStore.selectedBusinessUnit}
							<Building class="h-4 w-4 text-blue-600" />
							<span class="font-medium text-blue-900">
								{businessUnitsStore.selectedBusinessUnit.name}
							</span>
							<Badge variant="secondary" class="text-xs">
								Business Unit
							</Badge>
						{:else}
							<Users class="h-4 w-4 text-blue-600" />
							<span class="font-medium text-blue-900">Global Context</span>
							<Badge variant="secondary" class="text-xs">
								Organization-wide
							</Badge>
						{/if}
					</div>
					{#if businessUnitsStore.selectedBusinessUnit}
						<div class="flex items-center space-x-1">
							<Button 
								size="sm" 
								variant="ghost"
								onclick={() => businessUnitsStore.selectedBusinessUnit && openEditDialog(businessUnitsStore.selectedBusinessUnit)}
							>
								<Edit class="h-3 w-3" />
							</Button>
							<Button 
								size="sm" 
								variant="ghost"
								onclick={() => businessUnitsStore.selectedBusinessUnit && openDeleteDialog(businessUnitsStore.selectedBusinessUnit)}
							>
								<Trash2 class="h-3 w-3" />
							</Button>
						</div>
					{/if}
				</div>
			</div>
		{/if}
	</Card.Content>
</Card.Root>

<!-- Create Business Unit Dialog -->
<Dialog.Root bind:open={createDialogOpen}>
	<Dialog.Content class="!max-w-screen">
		<Dialog.Header>
			<Dialog.Title>Create New Business Unit</Dialog.Title>
			<Dialog.Description>
				Add a new business unit to organize your compliance management.
			</Dialog.Description>
		</Dialog.Header>
		
		<div class="space-y-4 py-4">
			<!-- Basic Information -->
			<div class="space-y-2">
				<Label for="new-name">Business Unit Name *</Label>
				<Input
					id="new-name"
					bind:value={newBusinessUnitName}
					placeholder="e.g., Finance Department, IT Operations"
					disabled={creating}
				/>
			</div>
			
			<!-- Legal Entity Information -->
			<div class="space-y-4">
				<h4 class="text-sm font-medium text-gray-900">Legal Entity Information</h4>
				<div class="grid grid-cols-1 md:grid-cols-3 gap-4">
					<div class="space-y-2">
						<Label for="new-legal-entity">Legal Entity / Business Unit Name</Label>
						<Input
							id="new-legal-entity"
							bind:value={newLegalEntityName}
							placeholder="e.g., Acme Corp SRL"
							disabled={creating}
						/>
					</div>
					<div class="space-y-2">
						<Label for="new-registration-code">Registration Code (IDNO/VAT)</Label>
						<Input
							id="new-registration-code"
							bind:value={newRegistrationCode}
							placeholder="e.g., RO12345678"
							disabled={creating}
						/>
					</div>
					<div class="space-y-2">
						<Label for="new-internal-code">Internal ID/Code</Label>
						<Input
							id="new-internal-code"
							bind:value={newInternalCode}
							placeholder="e.g., ACME-001"
							disabled={creating}
						/>
					</div>
				</div>
			</div>
			
			<!-- Business Information -->
			<div class="space-y-4">
				<h4 class="text-sm font-medium text-gray-900">Business Information</h4>
				<div class="grid grid-cols-1 md:grid-cols-4 gap-4">
					<div class="space-y-2">
						<Label for="new-sector">Sector</Label>
						<Input
							id="new-sector"
							bind:value={newSector}
							placeholder="e.g., Technology"
							disabled={creating}
						/>
					</div>
					<div class="space-y-2">
						<Label for="new-subsector">Subsector</Label>
						<Input
							id="new-subsector"
							bind:value={newSubsector}
							placeholder="e.g., Software Development"
							disabled={creating}
						/>
					</div>
					<div class="space-y-2">
						<Label for="new-company-size">Company Size Band</Label>
						<Select.Root>
							<Select.Trigger>
								{newCompanySizeBand || 'Select size band'}
							</Select.Trigger>
							<Select.Content>
								<Select.Item value="micro" onclick={() => newCompanySizeBand = 'micro'}>Micro</Select.Item>
								<Select.Item value="small" onclick={() => newCompanySizeBand = 'small'}>Small</Select.Item>
								<Select.Item value="medium" onclick={() => newCompanySizeBand = 'medium'}>Medium</Select.Item>
								<Select.Item value="large" onclick={() => newCompanySizeBand = 'large'}>Large</Select.Item>
							</Select.Content>
						</Select.Root>
					</div>
					<div class="space-y-2">
						<Label for="new-headcount">Headcount Range</Label>
						<Input
							id="new-headcount"
							bind:value={newHeadcountRange}
							placeholder="e.g., 50-200"
							disabled={creating}
						/>
					</div>
				</div>
			</div>
			
			<!-- Location Information -->
			<div class="space-y-4">
				<h4 class="text-sm font-medium text-gray-900">Location Information</h4>
				<div class="grid grid-cols-1 md:grid-cols-3 gap-4">
					<div class="space-y-2">
						<Label for="new-country">Country</Label>
						<Input
							id="new-country"
							bind:value={newCountry}
							placeholder="e.g., Romania"
							disabled={creating}
						/>
					</div>
					<div class="space-y-2">
						<Label for="new-timezone">Timezone</Label>
						<Input
							id="new-timezone"
							bind:value={newTimezone}
							placeholder="e.g., Europe/Bucharest"
							disabled={creating}
						/>
					</div>
					<div class="space-y-2">
						<Label for="new-address">Address</Label>
						<Input
							id="new-address"
							bind:value={newAddress}
							placeholder="e.g., Str. Example 123, Bucharest"
							disabled={creating}
						/>
					</div>
				</div>
			</div>
			
			<!-- Domain Information -->
			<div class="space-y-4">
				<h4 class="text-sm font-medium text-gray-900">Domain Information</h4>
				<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
					<div class="space-y-2">
						<Label for="new-primary-domain">Primary Domain / Website</Label>
						<Input
							id="new-primary-domain"
							bind:value={newPrimaryDomain}
							placeholder="e.g., acme.com"
							disabled={creating}
						/>
					</div>
					<div class="space-y-2">
						<Label for="new-other-domains">Count of Other Domains</Label>
						<Input
							id="new-other-domains"
							type="number"
							bind:value={newOtherDomainsCount}
							placeholder="0"
							disabled={creating}
						/>
					</div>
				</div>
			</div>
			
			<!-- Legal Compliance -->
			<div class="space-y-4">
				<h4 class="text-sm font-medium text-gray-900">Legal Compliance</h4>
				<div class="space-y-4">
					<div class="space-y-2">
						<Label>Identified as "furnizor de servicii" under Law 48/2023</Label>
						<div class="flex space-x-4">
							<label class="flex items-center space-x-2">
								<input
									type="radio"
									bind:group={newFurnizorServicii}
									value={true}
									disabled={creating}
								/>
								<span>Yes</span>
							</label>
							<label class="flex items-center space-x-2">
								<input
									type="radio"
									bind:group={newFurnizorServicii}
									value={false}
									disabled={creating}
								/>
								<span>No</span>
							</label>
						</div>
					</div>
					{#if newFurnizorServicii === true}
						<div class="space-y-2">
							<Label for="new-furnizor-date">Date/Reference</Label>
							<Input
								id="new-furnizor-date"
								bind:value={newFurnizorDate}
								placeholder="e.g., 2024-01-15"
								disabled={creating}
							/>
						</div>
					{/if}
				</div>
			</div>
			
			{#if createError}
				<div class="bg-red-50 border border-red-200 rounded-md p-3">
					<div class="text-sm text-red-600">{createError}</div>
				</div>
			{/if}
		</div>
		
		<Dialog.Footer>
			<Button variant="outline" onclick={() => createDialogOpen = false} disabled={creating}>
				Cancel
			</Button>
			<Button onclick={handleCreate} disabled={creating || !newBusinessUnitName.trim()}>
				{creating ? 'Creating...' : 'Create Business Unit'}
			</Button>
		</Dialog.Footer>
	</Dialog.Content>
</Dialog.Root>

<!-- Edit Business Unit Dialog -->
<Dialog.Root bind:open={editDialogOpen}>
	<Dialog.Content>
		<Dialog.Header>
			<Dialog.Title>Edit Business Unit</Dialog.Title>
			<Dialog.Description>
				Update the name of this business unit.
			</Dialog.Description>
		</Dialog.Header>
		
		<div class="space-y-4 py-4">
			<!-- Basic Information -->
			<div class="space-y-2">
				<Label for="edit-name">Business Unit Name *</Label>
				<Input
					id="edit-name"
					bind:value={editBusinessUnitName}
					placeholder="Business unit name"
					disabled={updating}
				/>
			</div>
			
			<!-- Legal Entity Information -->
			<div class="space-y-4">
				<h4 class="text-sm font-medium text-gray-900">Legal Entity Information</h4>
				<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
					<div class="space-y-2">
						<Label for="edit-legal-entity">Legal Entity / Business Unit Name</Label>
						<Input
							id="edit-legal-entity"
							bind:value={editLegalEntityName}
							placeholder="e.g., Acme Corp SRL"
							disabled={updating}
						/>
					</div>
					<div class="space-y-2">
						<Label for="edit-registration-code">Registration Code (IDNO/VAT)</Label>
						<Input
							id="edit-registration-code"
							bind:value={editRegistrationCode}
							placeholder="e.g., RO12345678"
							disabled={updating}
						/>
					</div>
					<div class="space-y-2">
						<Label for="edit-internal-code">Internal ID/Code</Label>
						<Input
							id="edit-internal-code"
							bind:value={editInternalCode}
							placeholder="e.g., ACME-001"
							disabled={updating}
						/>
					</div>
				</div>
			</div>
			
			<!-- Business Information -->
			<div class="space-y-4">
				<h4 class="text-sm font-medium text-gray-900">Business Information</h4>
				<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
					<div class="space-y-2">
						<Label for="edit-sector">Sector</Label>
						<Input
							id="edit-sector"
							bind:value={editSector}
							placeholder="e.g., Technology"
							disabled={updating}
						/>
					</div>
					<div class="space-y-2">
						<Label for="edit-subsector">Subsector</Label>
						<Input
							id="edit-subsector"
							bind:value={editSubsector}
							placeholder="e.g., Software Development"
							disabled={updating}
						/>
					</div>
					<div class="space-y-2">
						<Label for="edit-company-size">Company Size Band</Label>
						<Select.Root>
							<Select.Trigger>
								{editCompanySizeBand || 'Select size band'}
							</Select.Trigger>
							<Select.Content>
								<Select.Item value="micro" onclick={() => editCompanySizeBand = 'micro'}>Micro</Select.Item>
								<Select.Item value="small" onclick={() => editCompanySizeBand = 'small'}>Small</Select.Item>
								<Select.Item value="medium" onclick={() => editCompanySizeBand = 'medium'}>Medium</Select.Item>
								<Select.Item value="large" onclick={() => editCompanySizeBand = 'large'}>Large</Select.Item>
							</Select.Content>
						</Select.Root>
					</div>
					<div class="space-y-2">
						<Label for="edit-headcount">Headcount Range</Label>
						<Input
							id="edit-headcount"
							bind:value={editHeadcountRange}
							placeholder="e.g., 50-200"
							disabled={updating}
						/>
					</div>
				</div>
			</div>
			
			<!-- Location Information -->
			<div class="space-y-4">
				<h4 class="text-sm font-medium text-gray-900">Location Information</h4>
				<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
					<div class="space-y-2">
						<Label for="edit-country">Country</Label>
						<Input
							id="edit-country"
							bind:value={editCountry}
							placeholder="e.g., Romania"
							disabled={updating}
						/>
					</div>
					<div class="space-y-2">
						<Label for="edit-timezone">Timezone</Label>
						<Input
							id="edit-timezone"
							bind:value={editTimezone}
							placeholder="e.g., Europe/Bucharest"
							disabled={updating}
						/>
					</div>
					<div class="space-y-2 md:col-span-2">
						<Label for="edit-address">Address</Label>
						<Input
							id="edit-address"
							bind:value={editAddress}
							placeholder="e.g., Str. Example 123, Bucharest"
							disabled={updating}
						/>
					</div>
				</div>
			</div>
			
			<!-- Domain Information -->
			<div class="space-y-4">
				<h4 class="text-sm font-medium text-gray-900">Domain Information</h4>
				<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
					<div class="space-y-2">
						<Label for="edit-primary-domain">Primary Domain / Website</Label>
						<Input
							id="edit-primary-domain"
							bind:value={editPrimaryDomain}
							placeholder="e.g., acme.com"
							disabled={updating}
						/>
					</div>
					<div class="space-y-2">
						<Label for="edit-other-domains">Count of Other Domains</Label>
						<Input
							id="edit-other-domains"
							type="number"
							bind:value={editOtherDomainsCount}
							placeholder="0"
							disabled={updating}
						/>
					</div>
				</div>
			</div>
			
			<!-- Legal Compliance -->
			<div class="space-y-4">
				<h4 class="text-sm font-medium text-gray-900">Legal Compliance</h4>
				<div class="space-y-4">
					<div class="space-y-2">
						<Label>Identified as "furnizor de servicii" under Law 48/2023</Label>
						<div class="flex space-x-4">
							<label class="flex items-center space-x-2">
								<input
									type="radio"
									bind:group={editFurnizorServicii}
									value={true}
									disabled={updating}
								/>
								<span>Yes</span>
							</label>
							<label class="flex items-center space-x-2">
								<input
									type="radio"
									bind:group={editFurnizorServicii}
									value={false}
									disabled={updating}
								/>
								<span>No</span>
							</label>
						</div>
					</div>
					{#if editFurnizorServicii === true}
						<div class="space-y-2">
							<Label for="edit-furnizor-date">Date/Reference</Label>
							<Input
								id="edit-furnizor-date"
								bind:value={editFurnizorDate}
								placeholder="e.g., 2024-01-15"
								disabled={updating}
							/>
						</div>
					{/if}
				</div>
			</div>
			
			{#if editError}
				<div class="bg-red-50 border border-red-200 rounded-md p-3">
					<div class="text-sm text-red-600">{editError}</div>
				</div>
			{/if}
		</div>
		
		<Dialog.Footer>
			<Button variant="outline" onclick={() => editDialogOpen = false} disabled={updating}>
				Cancel
			</Button>
			<Button onclick={handleEdit} disabled={updating || !editBusinessUnitName.trim()}>
				{updating ? 'Updating...' : 'Update Business Unit'}
			</Button>
		</Dialog.Footer>
	</Dialog.Content>
</Dialog.Root>

<!-- Delete Business Unit Dialog -->
<Dialog.Root bind:open={deleteDialogOpen}>
	<Dialog.Content>
		<Dialog.Header>
			<Dialog.Title>Delete Business Unit</Dialog.Title>
			<Dialog.Description>
				Are you sure you want to delete "{businessUnitToDelete?.name}"? This action cannot be undone and will remove all associated compliance data.
			</Dialog.Description>
		</Dialog.Header>
		
		{#if deleteError}
			<div class="bg-red-50 border border-red-200 rounded-md p-3">
				<div class="text-sm text-red-600">{deleteError}</div>
			</div>
		{/if}
		
		<Dialog.Footer>
			<Button variant="outline" onclick={() => deleteDialogOpen = false} disabled={deleting}>
				Cancel
			</Button>
			<Button variant="destructive" onclick={handleDelete} disabled={deleting}>
				{deleting ? 'Deleting...' : 'Delete Business Unit'}
			</Button>
		</Dialog.Footer>
	</Dialog.Content>
</Dialog.Root>
