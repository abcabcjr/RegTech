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
      const printWindow = window.open('', '_blank');
      if (printWindow) {
        const formatDate = (dateStr: string) => {
          return new Date(dateStr).toLocaleString();
        };

        const formatBadge = (stage: string) => {
          const variants = {
            'initial': 'background: #f3f4f6; color: #374151; padding: 4px 8px; border-radius: 4px; font-size: 12px;',
            'update': 'background: #dbeafe; color: #1e40af; padding: 4px 8px; border-radius: 4px; font-size: 12px;',
            'final': 'background: #dcfce7; color: #166534; padding: 4px 8px; border-radius: 4px; font-size: 12px;'
          };
          return variants[stage as keyof typeof variants] || variants.initial;
        };

        printWindow.document.write(`
          <!DOCTYPE html>
          <html>
            <head>
              <title>Incident Report - ${selectedIncident.id}</title>
              <style>
                body {
                  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                  line-height: 1.6;
                  color: #374151;
                  max-width: 800px;
                  margin: 0 auto;
                  padding: 20px;
                  background: white;
                }
                
                .header {
                  border-bottom: 2px solid #e5e7eb;
                  padding-bottom: 20px;
                  margin-bottom: 30px;
                }
                
                .header h1 {
                  color: #111827;
                  margin: 0 0 10px 0;
                  font-size: 28px;
                  font-weight: 700;
                }
                
                .header-info {
                  display: flex;
                  justify-content: space-between;
                  align-items: center;
                  flex-wrap: wrap;
                  gap: 10px;
                }
                
                .meta-info {
                  color: #6b7280;
                  font-size: 14px;
                }
                
                .status-badge {
                  ${formatBadge(selectedIncident.stage)}
                  font-weight: 500;
                  text-transform: capitalize;
                }
                
                .section {
                  margin-bottom: 30px;
                  background: #f9fafb;
                  padding: 20px;
                  border-radius: 8px;
                  border: 1px solid #e5e7eb;
                }
                
                .section h2 {
                  color: #111827;
                  margin: 0 0 15px 0;
                  font-size: 20px;
                  font-weight: 600;
                  border-bottom: 1px solid #d1d5db;
                  padding-bottom: 8px;
                }
                
                .field-grid {
                  display: grid;
                  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
                  gap: 15px;
                  margin-bottom: 15px;
                }
                
                .field {
                  margin-bottom: 12px;
                }
                
                .field-label {
                  font-weight: 600;
                  color: #374151;
                  font-size: 14px;
                  margin-bottom: 4px;
                  display: block;
                }
                
                .field-value {
                  color: #111827;
                  font-size: 14px;
                  word-wrap: break-word;
                }
                
                .field-value.empty {
                  color: #9ca3af;
                  font-style: italic;
                }
                
                .yes-badge {
                  background: #fef2f2;
                  color: #dc2626;
                  padding: 2px 6px;
                  border-radius: 4px;
                  font-size: 12px;
                  font-weight: 500;
                }
                
                .no-badge {
                  background: #f0fdf4;
                  color: #16a34a;
                  padding: 2px 6px;
                  border-radius: 4px;
                  font-size: 12px;
                  font-weight: 500;
                }
                
                @media print {
                  body { margin: 0; padding: 15px; }
                  .section { break-inside: avoid; }
                  .header { break-after: avoid; }
                }
              </style>
            </head>
            <body>
              <div class="header">
                <h1>Incident Report</h1>
                <div class="header-info">
                  <div class="meta-info">
                    ID: <strong>${selectedIncident.id}</strong><br>
                    Created: ${formatDate(selectedIncident.createdAt)}<br>
                    Last Updated: ${formatDate(selectedIncident.updatedAt)}
                  </div>
                  <span class="status-badge">${selectedIncident.stage}</span>
                </div>
              </div>

              <!-- Initial Report Section -->
              <div class="section">
                <h2>Initial Report</h2>
                <div class="field">
                  <span class="field-label">Summary</span>
                  <div class="field-value">${selectedIncident.details.initial?.summary || '<span class="empty">Not provided</span>'}</div>
                </div>
                
                <div class="field-grid">
                  <div class="field">
                    <span class="field-label">Detected At</span>
                    <div class="field-value">${selectedIncident.details.initial?.detectedAt ? formatDate(selectedIncident.details.initial.detectedAt) : '<span class="empty">Not provided</span>'}</div>
                  </div>
                  <div class="field">
                    <span class="field-label">Cause</span>
                    <div class="field-value">${selectedIncident.causeTag || '<span class="empty">Not specified</span>'}</div>
                  </div>
                </div>
                
                <div class="field-grid">
                  <div class="field">
                    <span class="field-label">Suspected Illegal Activity</span>
                    <div class="field-value">
                      <span class="${selectedIncident.details.initial?.suspectedIllegal ? 'yes-badge' : 'no-badge'}">
                        ${selectedIncident.details.initial?.suspectedIllegal ? 'Yes' : 'No'}
                      </span>
                    </div>
                  </div>
                  <div class="field">
                    <span class="field-label">Cross-Border Effects</span>
                    <div class="field-value">
                      <span class="${selectedIncident.details.initial?.possibleCrossBorder ? 'yes-badge' : 'no-badge'}">
                        ${selectedIncident.details.initial?.possibleCrossBorder ? 'Yes' : 'No'}
                      </span>
                    </div>
                  </div>
                </div>
              </div>

              ${selectedIncident.stage !== 'initial' ? `
              <!-- Update Report Section -->
              <div class="section">
                <h2>Impact Assessment</h2>
                
                <div class="field-grid">
                  <div class="field">
                    <span class="field-label">Users Affected</span>
                    <div class="field-value">${selectedIncident.usersAffected || 0}</div>
                  </div>
                  <div class="field">
                    <span class="field-label">Downtime (minutes)</span>
                    <div class="field-value">${selectedIncident.downtimeMinutes || 0}</div>
                  </div>
                  <div class="field">
                    <span class="field-label">Financial Impact (%)</span>
                    <div class="field-value">${selectedIncident.financialImpactPct || 0}%</div>
                  </div>
                </div>
                
                <div class="field-grid">
                  <div class="field">
                    <span class="field-label">Gravity</span>
                    <div class="field-value">${selectedIncident.details.update?.gravity || '<span class="empty">Not assessed</span>'}</div>
                  </div>
                  <div class="field">
                    <span class="field-label">Significant Incident</span>
                    <div class="field-value">
                      <span class="${selectedIncident.significant ? 'yes-badge' : 'no-badge'}">
                        ${selectedIncident.significant ? 'Yes' : 'No'}
                      </span>
                    </div>
                  </div>
                  <div class="field">
                    <span class="field-label">Recurring Incident</span>
                    <div class="field-value">
                      <span class="${selectedIncident.recurring ? 'yes-badge' : 'no-badge'}">
                        ${selectedIncident.recurring ? 'Yes' : 'No'}
                      </span>
                    </div>
                  </div>
                </div>
                
                <div class="field">
                  <span class="field-label">Impact Description</span>
                  <div class="field-value">${selectedIncident.details.update?.impact || '<span class="empty">Not documented</span>'}</div>
                </div>
                
                <div class="field">
                  <span class="field-label">Interim Actions</span>
                  <div class="field-value">${selectedIncident.details.update?.corrections || '<span class="empty">No actions documented</span>'}</div>
                </div>
              </div>
              ` : ''}

              ${selectedIncident.stage === 'final' ? `
              <!-- Final Report Section -->
              <div class="section">
                <h2>Final Report</h2>
                
                <div class="field">
                  <span class="field-label">Root Cause Analysis</span>
                  <div class="field-value">${selectedIncident.details.final?.rootCause || '<span class="empty">Not determined</span>'}</div>
                </div>
                
                <div class="field">
                  <span class="field-label">Mitigations Implemented</span>
                  <div class="field-value">${selectedIncident.details.final?.mitigations || '<span class="empty">Not documented</span>'}</div>
                </div>
                
                <div class="field">
                  <span class="field-label">Lessons Learned</span>
                  <div class="field-value">${selectedIncident.details.final?.lessons || '<span class="empty">Not documented</span>'}</div>
                </div>
                
                <div class="field">
                  <span class="field-label">Cross-Border Effects Description</span>
                  <div class="field-value">${selectedIncident.details.final?.crossBorderDesc || '<span class="empty">None identified</span>'}</div>
                </div>
              </div>
              ` : ''}
              
              <div style="text-align: center; margin-top: 40px; padding-top: 20px; border-top: 1px solid #e5e7eb; color: #6b7280; font-size: 12px;">
                Generated on ${new Date().toLocaleString()}<br>
                RegTech Incident Management System
              </div>
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

  function getGravityBadgeVariant(gravity: string | undefined) {
    switch (gravity?.toLowerCase()) {
      case 'critical':
        return 'destructive';
      case 'high':
        return 'destructive';
      case 'medium':
        return 'default';
      case 'low':
        return 'secondary';
      default:
        return 'outline';
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

  <div class="grid lg:grid-cols-3 gap-8 max-w-7xl mx-auto">
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
                    <div class="flex items-start justify-between gap-2 mb-2">
                      <h3 class="font-medium text-sm truncate">
                        {incidentsStore.getIncidentSummary(incident)}
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
    <div class="lg:col-span-2 min-w-0">
      {#if selectedIncident}
        <Card.Root class="overflow-hidden">
          <Card.Header>
            <div class="flex items-center gap-4 overflow-hidden">
              <div class="flex-1 min-w-0 overflow-hidden">
                <h2 class="text-lg font-semibold leading-none tracking-tight truncate">
                  {incidentsStore.getIncidentSummary(selectedIncident)}
                </h2>
              </div>
              <Badge variant={getStatusBadgeVariant(selectedIncident.stage)} class="flex-shrink-0">
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
                    <div class="text-sm font-semibold text-foreground">Summary</div>
                    <p class="text-sm">{selectedIncident.details.initial?.summary || 'No summary'}</p>
                  </div>
                  <div class="grid grid-cols-2 gap-4">
                    <div>
                      <div class="text-sm font-semibold text-foreground">Detected At</div>
                      <p class="text-sm">{selectedIncident.details.initial?.detectedAt || 'Not specified'}</p>
                    </div>
                    <div>
                      <div class="text-sm font-semibold text-foreground">Cause</div>
                      <p class="text-sm">{incidentsStore.getCauseTagLabel(selectedIncident.causeTag)}</p>
                    </div>
                  </div>
                  <div class="grid grid-cols-2 gap-4">
                    <div class="flex items-center space-x-2">
                      <span class="text-sm font-semibold text-foreground">Suspected Illegal:</span>
                      <Badge variant={selectedIncident.details.initial?.suspectedIllegal ? 'destructive' : 'outline'}>
                        {selectedIncident.details.initial?.suspectedIllegal ? 'Yes' : 'No'}
                      </Badge>
                    </div>
                    <div class="flex items-center space-x-2">
                      <span class="text-sm font-semibold text-foreground">Cross-Border:</span>
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
                        <div class="text-sm font-semibold text-foreground">Users Affected</div>
                        <p class="text-sm">{selectedIncident.usersAffected || 0}</p>
                      </div>
                      <div>
                        <div class="text-sm font-semibold text-foreground">Downtime (min)</div>
                        <p class="text-sm">{selectedIncident.downtimeMinutes || 0}</p>
                      </div>
                      <div>
                        <div class="text-sm font-semibold text-foreground">Financial Impact %</div>
                        <p class="text-sm">{selectedIncident.financialImpactPct || 0}%</p>
                      </div>
                    </div>
                    <div>
                      <div class="text-sm font-semibold text-foreground">Gravity</div>
                      <Badge variant={getGravityBadgeVariant(selectedIncident.details.update?.gravity)}>
                        {selectedIncident.details.update?.gravity || 'Not assessed'}
                      </Badge>
                    </div>
                    <div>
                      <div class="text-sm font-semibold text-foreground">Impact</div>
                      <p class="text-sm">{selectedIncident.details.update?.impact || 'Not described'}</p>
                    </div>
                    <div>
                      <div class="text-sm font-semibold text-foreground">Interim Actions</div>
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
                      <div class="text-sm font-semibold text-foreground">Root Cause</div>
                      <p class="text-sm">{selectedIncident.details.final?.rootCause || 'Not determined'}</p>
                    </div>
                    <div>
                      <div class="text-sm font-semibold text-foreground">Mitigations</div>
                      <p class="text-sm">{selectedIncident.details.final?.mitigations || 'Not documented'}</p>
                    </div>
                    <div>
                      <div class="text-sm font-semibold text-foreground">Cross-Border Effects</div>
                      <p class="text-sm">{selectedIncident.details.final?.crossBorderDesc || 'None identified'}</p>
                    </div>
                    <div>
                      <div class="text-sm font-semibold text-foreground">Lessons Learned</div>
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

