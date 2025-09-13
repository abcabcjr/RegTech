<script lang="ts">
  import { onMount } from 'svelte';
  import { Button } from '$lib/components/ui/button';
  import * as Card from '$lib/components/ui/card';
  import { Badge } from '$lib/components/ui/badge';
  import { incidentsStore } from '$lib/stores/incidents.svelte';
  import type { IncidentRecord } from '$lib/types/incidents';
  import IncidentWizard from '$lib/components/incidents/IncidentWizard.svelte';
  
  // Icons
  import Plus from '@lucide/svelte/icons/plus';
  import FileText from '@lucide/svelte/icons/file-text';
  import Clock from '@lucide/svelte/icons/clock';
  import Download from '@lucide/svelte/icons/download';
  import Printer from '@lucide/svelte/icons/printer';
  import Edit from '@lucide/svelte/icons/edit';
  import Trash2 from '@lucide/svelte/icons/trash-2';

  let wizardOpen = $state(false);
  let editingIncident = $state<IncidentRecord | null>(null);

  // Reactive references to store state
  let incidents = $derived(incidentsStore.incidents);
  let selectedIncident = $derived(incidentsStore.selectedIncident);
  let loading = $derived(incidentsStore.loading);

  function handleNewIncident() {
    editingIncident = null; // Clear edit mode
    wizardOpen = true;
  }

  function handleSelectIncident(incident: IncidentRecord) {
    incidentsStore.selectIncident(incident);
  }

  function handleExportJSON() {
    if (selectedIncident) {
      incidentsStore.exportIncidentJSON(selectedIncident.id);
    }
  }

  function handlePrintReport() {
    if (selectedIncident) {
      // For now, just open a new window with the incident data
      const printWindow = window.open('', '_blank');
      if (printWindow) {
        printWindow.document.write(`
          <html>
            <head><title>Incident Report - ${selectedIncident.id}</title></head>
            <body>
              <h1>Incident Report</h1>
              <pre>${JSON.stringify(selectedIncident, null, 2)}</pre>
            </body>
          </html>
        `);
        printWindow.document.close();
        printWindow.print();
      }
    }
  }

  function handleEditIncident() {
    if (selectedIncident) {
      editingIncident = selectedIncident;
      wizardOpen = true;
    }
  }

  function handleDeleteIncident() {
    if (selectedIncident) {
      const confirmed = confirm(`Are you sure you want to delete incident ${selectedIncident.id}? This action cannot be undone.`);
      if (confirmed) {
        incidentsStore.deleteIncident(selectedIncident.id);
        // Clear selection since the incident was deleted
        incidentsStore.selectIncident(null);
      }
    }
  }

  function getStatusBadgeVariant(stage: string) {
    switch (stage) {
      case 'initial':
        return 'secondary';
      case 'update':
        return 'default';
      case 'final':
        return 'outline';
      default:
        return 'secondary';
    }
  }

  function formatDate(dateString: string) {
    return new Date(dateString).toLocaleDateString();
  }

  onMount(() => {
    // Load incidents on component mount (only once)
    incidentsStore.loadIncidents();
  });

</script>

<div class="max-w-7xl mx-auto px-4 py-8">
  <div class="mb-8">
    <h1 class="text-3xl font-bold text-foreground mb-4">Incident Management</h1>
    <p class="text-muted-foreground mb-6">
      Report and manage cybersecurity incidents through our 3-stage workflow: 
      Initial Report → Update Report → Final Report.
    </p>
  </div>

  <div class="grid lg:grid-cols-3 gap-8">
    <!-- Incident List -->
    <div class="lg:col-span-1">
      <Card.Root>
        <Card.Header>
          <div class="flex items-center justify-between">
            <Card.Title>Incidents</Card.Title>
            <Button onclick={handleNewIncident} size="sm">
              <Plus class="h-4 w-4 mr-2" />
              New Incident
            </Button>
          </div>
          <Card.Description>
            {incidents.length} total incidents
          </Card.Description>
        </Card.Header>
        <Card.Content>
          {#if loading}
            <div class="text-center py-8">
              <div class="text-muted-foreground">Loading incidents...</div>
            </div>
          {:else if incidents.length === 0}
            <div class="text-center py-8">
              <FileText class="h-12 w-12 text-muted-foreground mx-auto mb-4" />
              <p class="text-muted-foreground mb-4">No incidents reported yet</p>
              <Button onclick={handleNewIncident} variant="outline">
                Report First Incident
              </Button>
            </div>
          {:else}
            <div class="space-y-3">
              {#each incidents as incident (incident.id)}
                <Card.Root 
                  class="cursor-pointer transition-colors hover:bg-muted/50 {selectedIncident?.id === incident.id ? 'ring-2 ring-primary' : ''}"
                  onclick={() => handleSelectIncident(incident)}
                >
                  <Card.Content class="p-4">
                    <div class="flex items-start justify-between mb-2">
                      <h3 class="font-medium text-sm">
                        {incidentsStore.getIncidentSummary(incident)}...
                      </h3>
                      <Badge variant={getStatusBadgeVariant(incident.stage)}>
                        {incident.stage}
                      </Badge>
                    </div>
                    <div class="flex items-center text-xs text-muted-foreground mb-2">
                      <Clock class="h-3 w-3 mr-1" />
                      {formatDate(incident.createdAt)}
                    </div>
                    <p class="text-xs text-muted-foreground line-clamp-2 mb-2">
                      {incident.details.initial?.summary || 'No summary available'}
                    </p>
                    <div class="flex items-center justify-between">
                      <Badge variant="outline" class="text-xs">
                        {incidentsStore.getCauseTagLabel(incident.causeTag)}
                      </Badge>
                      {#if incident.significant}
                        <Badge variant="destructive" class="text-xs">
                          Significant
                        </Badge>
                      {/if}
                    </div>
                  </Card.Content>
                </Card.Root>
              {/each}
            </div>
          {/if}
        </Card.Content>
      </Card.Root>
    </div>

    <!-- Incident Details / Empty State -->
    <div class="lg:col-span-2">
      {#if selectedIncident}
        <Card.Root>
          <Card.Header>
            <div class="flex items-center justify-between">
              <Card.Title>
                {incidentsStore.getIncidentSummary(selectedIncident)}
              </Card.Title>
              <Badge variant={getStatusBadgeVariant(selectedIncident.stage)}>
                {selectedIncident.stage}
              </Badge>
            </div>
            <Card.Description>
              Created {formatDate(selectedIncident.createdAt)} • 
              Last updated {formatDate(selectedIncident.updatedAt)}
            </Card.Description>
          </Card.Header>
          <Card.Content>
            <div class="space-y-6">
              <!-- Initial Report -->
              <div>
                <h3 class="font-semibold text-lg mb-3">Initial Report</h3>
                <div class="grid gap-4">
                  <div>
                    <div class="text-sm font-medium text-muted-foreground">Summary</div>
                    <p class="text-sm">{selectedIncident.details.initial?.summary || 'No summary'}</p>
                  </div>
                  <div class="grid grid-cols-2 gap-4">
                    <div>
                      <div class="text-sm font-medium text-muted-foreground">Detected At</div>
                      <p class="text-sm">{selectedIncident.details.initial?.detectedAt || 'Not specified'}</p>
                    </div>
                    <div>
                      <div class="text-sm font-medium text-muted-foreground">Cause</div>
                      <p class="text-sm">{incidentsStore.getCauseTagLabel(selectedIncident.causeTag)}</p>
                    </div>
                  </div>
                  <div class="grid grid-cols-2 gap-4">
                    <div class="flex items-center space-x-2">
                      <span class="text-sm font-medium text-muted-foreground">Suspected Illegal:</span>
                      <Badge variant={selectedIncident.details.initial?.suspectedIllegal ? 'destructive' : 'outline'}>
                        {selectedIncident.details.initial?.suspectedIllegal ? 'Yes' : 'No'}
                      </Badge>
                    </div>
                    <div class="flex items-center space-x-2">
                      <span class="text-sm font-medium text-muted-foreground">Cross-Border:</span>
                      <Badge variant={selectedIncident.details.initial?.possibleCrossBorder ? 'destructive' : 'outline'}>
                        {selectedIncident.details.initial?.possibleCrossBorder ? 'Possible' : 'No'}
                      </Badge>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Update Report -->
              {#if selectedIncident.stage !== 'initial'}
                <div>
                  <h3 class="font-semibold text-lg mb-3">Update Report</h3>
                  <div class="grid gap-4">
                    <div class="grid grid-cols-3 gap-4">
                      <div>
                        <div class="text-sm font-medium text-muted-foreground">Users Affected</div>
                        <p class="text-sm">{selectedIncident.usersAffected || 0}</p>
                      </div>
                      <div>
                        <div class="text-sm font-medium text-muted-foreground">Downtime (min)</div>
                        <p class="text-sm">{selectedIncident.downtimeMinutes || 0}</p>
                      </div>
                      <div>
                        <div class="text-sm font-medium text-muted-foreground">Financial Impact %</div>
                        <p class="text-sm">{selectedIncident.financialImpactPct || 0}%</p>
                      </div>
                    </div>
                    <div>
                      <div class="text-sm font-medium text-muted-foreground">Gravity</div>
                      <p class="text-sm">{selectedIncident.details.update?.gravity || 'Not assessed'}</p>
                    </div>
                    <div>
                      <div class="text-sm font-medium text-muted-foreground">Impact</div>
                      <p class="text-sm">{selectedIncident.details.update?.impact || 'Not described'}</p>
                    </div>
                    <div>
                      <div class="text-sm font-medium text-muted-foreground">Interim Actions</div>
                      <p class="text-sm">{selectedIncident.details.update?.corrections || 'No actions documented'}</p>
                    </div>
                  </div>
                </div>
              {/if}

              <!-- Final Report -->
              {#if selectedIncident.stage === 'final'}
                <div>
                  <h3 class="font-semibold text-lg mb-3">Final Report</h3>
                  <div class="grid gap-4">
                    <div>
                      <div class="text-sm font-medium text-muted-foreground">Root Cause</div>
                      <p class="text-sm">{selectedIncident.details.final?.rootCause || 'Not determined'}</p>
                    </div>
                    <div>
                      <div class="text-sm font-medium text-muted-foreground">Gravity</div>
                      <Badge variant={selectedIncident.details.final?.gravity === 'critical' ? 'destructive' : 'outline'}>
                        {selectedIncident.details.final?.gravity || 'Not assessed'}
                      </Badge>
                    </div>
                    <div>
                      <div class="text-sm font-medium text-muted-foreground">Mitigations</div>
                      <p class="text-sm">{selectedIncident.details.final?.mitigations || 'Not documented'}</p>
                    </div>
                    <div>
                      <div class="text-sm font-medium text-muted-foreground">Cross-Border Effects</div>
                      <p class="text-sm">{selectedIncident.details.final?.crossBorderDesc || 'None identified'}</p>
                    </div>
                    <div>
                      <div class="text-sm font-medium text-muted-foreground">Lessons Learned</div>
                      <p class="text-sm">{selectedIncident.details.final?.lessons || 'Not documented'}</p>
                    </div>
                  </div>
                </div>
              {/if}

              <!-- Actions -->
              <div class="flex flex-wrap gap-2 pt-4 border-t">
                <Button variant="outline" size="sm" onclick={handleEditIncident}>
                  <Edit class="h-4 w-4 mr-2" />
                  Edit
                </Button>
                <Button variant="outline" size="sm" onclick={handleDeleteIncident} class="text-destructive hover:bg-destructive hover:text-destructive-foreground">
                  <Trash2 class="h-4 w-4 mr-2" />
                  Delete
                </Button>
                <div class="flex-1"></div>
                <Button variant="outline" size="sm" onclick={handleExportJSON}>
                  <Download class="h-4 w-4 mr-2" />
                  Export JSON
                </Button>
                <Button variant="outline" size="sm" onclick={handlePrintReport}>
                  <Printer class="h-4 w-4 mr-2" />
                  Print Report
                </Button>
              </div>
            </div>
          </Card.Content>
        </Card.Root>
      {:else}
        <Card.Root>
          <Card.Content class="p-12 text-center">
            <FileText class="h-16 w-16 text-muted-foreground mx-auto mb-4" />
            <h3 class="text-lg font-semibold mb-2">Select an Incident</h3>
            <p class="text-muted-foreground mb-6">
              Choose an incident from the list to view details, or create a new incident report.
            </p>
            <Button onclick={handleNewIncident}>
              <Plus class="h-4 w-4 mr-2" />
              Report New Incident
            </Button>
          </Card.Content>
        </Card.Root>
      {/if}
    </div>
  </div>
</div>

<!-- Modals -->
<IncidentWizard bind:open={wizardOpen} editIncident={editingIncident} />

