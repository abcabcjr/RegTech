<script lang="ts">
  import { Button } from '$lib/components/ui/button';
  import * as Dialog from '$lib/components/ui/dialog';
  import * as Card from '$lib/components/ui/card';
  import { Badge } from '$lib/components/ui/badge';
  import { incidentsStore } from '$lib/stores/incidents.svelte';
  import type { IncidentRecord } from '$lib/types/incidents';
  
  // Icons
  import Download from '@lucide/svelte/icons/download';
  import Printer from '@lucide/svelte/icons/printer';
  import Edit from '@lucide/svelte/icons/edit';
  import Trash2 from '@lucide/svelte/icons/trash-2';

  // Props
  let { 
    open = $bindable(false),
    incident
  }: { 
    open: boolean;
    incident: IncidentRecord;
  } = $props();

  function handleExportJSON() {
    incidentsStore.exportIncidentJSON(incident.id);
  }

  function handlePrintReport() {
    const printWindow = window.open('', '_blank');
    if (printWindow) {
      printWindow.document.write(`
        <html>
          <head>
            <title>Incident Report - ${incident.id}</title>
            <style>
              body { font-family: Arial, sans-serif; margin: 20px; }
              .header { border-bottom: 2px solid #ccc; padding-bottom: 10px; margin-bottom: 20px; }
              .section { margin-bottom: 20px; }
              .label { font-weight: bold; color: #666; }
              .value { margin-bottom: 10px; }
            </style>
          </head>
          <body>
            <div class="header">
              <h1>Incident Report</h1>
              <p>ID: ${incident.id}</p>
              <p>Created: ${new Date(incident.createdAt).toLocaleDateString()}</p>
              <p>Status: ${incident.stage}</p>
            </div>
            
            <div class="section">
              <h2>Initial Report</h2>
              <div class="label">Summary:</div>
              <div class="value">${incident.details.initial?.summary || 'N/A'}</div>
              <div class="label">Detected At:</div>
              <div class="value">${incident.details.initial?.detectedAt || 'N/A'}</div>
              <div class="label">Cause:</div>
              <div class="value">${incidentsStore.getCauseTagLabel(incident.causeTag)}</div>
            </div>
            
            ${incident.stage !== 'initial' ? `
              <div class="section">
                <h2>Update Report</h2>
                <div class="label">Users Affected:</div>
                <div class="value">${incident.usersAffected || 0}</div>
                <div class="label">Downtime:</div>
                <div class="value">${incident.downtimeMinutes || 0} minutes</div>
                <div class="label">Financial Impact:</div>
                <div class="value">${incident.financialImpactPct || 0}%</div>
                <div class="label">Gravity:</div>
                <div class="value">${incident.details.update?.gravity || 'N/A'}</div>
                <div class="label">Impact:</div>
                <div class="value">${incident.details.update?.impact || 'N/A'}</div>
              </div>
            ` : ''}
            
            ${incident.stage === 'final' ? `
              <div class="section">
                <h2>Final Report</h2>
                <div class="label">Root Cause:</div>
                <div class="value">${incident.details.final?.rootCause || 'N/A'}</div>
                <div class="label">Mitigations:</div>
                <div class="value">${incident.details.final?.mitigations || 'N/A'}</div>
                <div class="label">Lessons Learned:</div>
                <div class="value">${incident.details.final?.lessons || 'N/A'}</div>
              </div>
            ` : ''}
          </body>
        </html>
      `);
      printWindow.document.close();
      printWindow.print();
    }
  }

  function handleDelete() {
    if (confirm('Are you sure you want to delete this incident? This action cannot be undone.')) {
      incidentsStore.deleteIncident(incident.id);
      open = false;
    }
  }

  function formatDate(dateString: string) {
    return new Date(dateString).toLocaleDateString();
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
</script>

<Dialog.Root bind:open>
  <Dialog.Content class="max-w-4xl max-h-[90vh] overflow-y-auto">
    <Dialog.Header>
      <div class="flex items-center justify-between">
        <Dialog.Title>
          {incidentsStore.getIncidentSummary(incident)}
        </Dialog.Title>
        <Badge variant={getStatusBadgeVariant(incident.stage)}>
          {incident.stage}
        </Badge>
      </div>
      <Dialog.Description>
        Created {formatDate(incident.createdAt)} • 
        Last updated {formatDate(incident.updatedAt)}
      </Dialog.Description>
    </Dialog.Header>

    <div class="space-y-6">
      <!-- Initial Report -->
      <Card.Root>
        <Card.Header>
          <Card.Title>Initial Report</Card.Title>
        </Card.Header>
        <Card.Content>
          <div class="grid gap-4">
            <div>
              <div class="text-sm font-medium text-muted-foreground">Summary</div>
              <p class="text-sm">{incident.details.initial?.summary || 'No summary'}</p>
            </div>
            <div class="grid grid-cols-2 gap-4">
              <div>
                <div class="text-sm font-medium text-muted-foreground">Detected At</div>
                <p class="text-sm">{incident.details.initial?.detectedAt || 'Not specified'}</p>
              </div>
              <div>
                <div class="text-sm font-medium text-muted-foreground">Cause</div>
                <p class="text-sm">{incidentsStore.getCauseTagLabel(incident.causeTag)}</p>
              </div>
            </div>
            <div class="grid grid-cols-2 gap-4">
              <div class="flex items-center space-x-2">
                <span class="text-sm font-medium text-muted-foreground">Suspected Illegal:</span>
                <Badge variant={incident.details.initial?.suspectedIllegal ? 'destructive' : 'outline'}>
                  {incident.details.initial?.suspectedIllegal ? 'Yes' : 'No'}
                </Badge>
              </div>
              <div class="flex items-center space-x-2">
                <span class="text-sm font-medium text-muted-foreground">Cross-Border:</span>
                <Badge variant={incident.details.initial?.possibleCrossBorder ? 'destructive' : 'outline'}>
                  {incident.details.initial?.possibleCrossBorder ? 'Possible' : 'No'}
                </Badge>
              </div>
            </div>
          </div>
        </Card.Content>
      </Card.Root>

      <!-- Update Report -->
      {#if incident.stage !== 'initial'}
        <Card.Root>
          <Card.Header>
            <Card.Title>Update Report</Card.Title>
          </Card.Header>
          <Card.Content>
            <div class="grid gap-4">
              <div class="grid grid-cols-3 gap-4">
                <div>
                <div class="text-sm font-medium text-muted-foreground">Users Affected</div>
                <p class="text-sm">{incident.usersAffected || 0}</p>
              </div>
              <div>
                <div class="text-sm font-medium text-muted-foreground">Downtime (min)</div>
                <p class="text-sm">{incident.downtimeMinutes || 0}</p>
              </div>
              <div>
                <div class="text-sm font-medium text-muted-foreground">Financial Impact %</div>
                <p class="text-sm">{incident.financialImpactPct || 0}%</p>
              </div>
            </div>
            <div>
              <div class="text-sm font-medium text-muted-foreground">Gravity</div>
              <p class="text-sm">{incident.details.update?.gravity || 'Not assessed'}</p>
            </div>
            <div>
              <div class="text-sm font-medium text-muted-foreground">Impact</div>
              <p class="text-sm">{incident.details.update?.impact || 'Not described'}</p>
            </div>
            <div>
              <div class="text-sm font-medium text-muted-foreground">Interim Actions</div>
                <p class="text-sm">{incident.details.update?.corrections || 'No actions documented'}</p>
              </div>
              <div class="flex items-center space-x-4">
                {#if incident.significant}
                  <Badge variant="destructive">Significant Incident</Badge>
                {/if}
                {#if incident.recurring}
                  <Badge variant="secondary">Recurring Incident</Badge>
                {/if}
              </div>
            </div>
          </Card.Content>
        </Card.Root>
      {/if}

      <!-- Final Report -->
      {#if incident.stage === 'final'}
        <Card.Root>
          <Card.Header>
            <Card.Title>Final Report</Card.Title>
          </Card.Header>
          <Card.Content>
            <div class="grid gap-4">
              <div>
              <div class="text-sm font-medium text-muted-foreground">Root Cause</div>
              <p class="text-sm">{incident.details.final?.rootCause || 'Not determined'}</p>
            </div>
            <div>
              <div class="text-sm font-medium text-muted-foreground">Final Gravity Assessment</div>
              <Badge variant={incident.details.final?.gravity === 'critical' ? 'destructive' : 'outline'}>
                {incident.details.final?.gravity || 'Not assessed'}
              </Badge>
            </div>
            <div>
              <div class="text-sm font-medium text-muted-foreground">Mitigations</div>
              <p class="text-sm">{incident.details.final?.mitigations || 'Not documented'}</p>
            </div>
            <div>
              <div class="text-sm font-medium text-muted-foreground">Cross-Border Effects</div>
              <p class="text-sm">{incident.details.final?.crossBorderDesc || 'None identified'}</p>
            </div>
            <div>
              <div class="text-sm font-medium text-muted-foreground">Lessons Learned</div>
                <p class="text-sm">{incident.details.final?.lessons || 'Not documented'}</p>
              </div>
            </div>
          </Card.Content>
        </Card.Root>
      {/if}
    </div>

    <!-- Actions -->
    <div class="flex justify-between pt-4 border-t">
      <div class="flex space-x-2">
        <Button variant="outline" size="sm" onclick={handleExportJSON}>
          <Download class="h-4 w-4 mr-2" />
          Export JSON
        </Button>
        <Button variant="outline" size="sm" onclick={handlePrintReport}>
          <Printer class="h-4 w-4 mr-2" />
          Print Report
        </Button>
      </div>
      
      <div class="flex space-x-2">
        <Button variant="destructive" size="sm" onclick={handleDelete}>
          <Trash2 class="h-4 w-4 mr-2" />
          Delete
        </Button>
        <Button variant="outline" onclick={() => open = false}>
          Close
        </Button>
      </div>
    </div>
  </Dialog.Content>
</Dialog.Root>
