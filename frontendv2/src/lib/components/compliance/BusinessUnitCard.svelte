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
			await businessUnitsStore.create(newBusinessUnitName.trim());
			newBusinessUnitName = '';
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
			await businessUnitsStore.update(businessUnitToEdit.id, editBusinessUnitName.trim());
			editDialogOpen = false;
			businessUnitToEdit = null;
			editBusinessUnitName = '';
		} catch (error) {
			editError = error instanceof Error ? error.message : 'Failed to update business unit';
		} finally {
			updating = false;
		}
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
		editBusinessUnitName = businessUnit.name;
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
	<Dialog.Content>
		<Dialog.Header>
			<Dialog.Title>Create New Business Unit</Dialog.Title>
			<Dialog.Description>
				Add a new business unit to organize your compliance management.
			</Dialog.Description>
		</Dialog.Header>
		
		<div class="space-y-4 py-4">
			<div class="space-y-2">
				<Label for="new-name">Business Unit Name</Label>
				<Input
					id="new-name"
					bind:value={newBusinessUnitName}
					placeholder="e.g., Finance Department, IT Operations"
					disabled={creating}
				/>
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
			<div class="space-y-2">
				<Label for="edit-name">Business Unit Name</Label>
				<Input
					id="edit-name"
					bind:value={editBusinessUnitName}
					placeholder="Business unit name"
					disabled={updating}
				/>
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
