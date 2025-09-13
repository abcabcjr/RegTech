<script lang="ts">
  import { Button } from '$lib/components/ui/button';
  import * as Card from '$lib/components/ui/card';
  import * as Dialog from '$lib/components/ui/dialog';
  import { Input } from '$lib/components/ui/input';
  import { Label } from '$lib/components/ui/label';
  import { Textarea } from '$lib/components/ui/textarea';
  import * as Select from '$lib/components/ui/select';
  import { Checkbox } from '$lib/components/ui/checkbox';
  import { Badge } from '$lib/components/ui/badge';
  import { incidentsStore } from '$lib/stores/incidents.svelte';
  import type { 
    CauseTag, 
    InitialDetails, 
    UpdateDetails, 
    FinalDetails 
  } from '$lib/types/incidents';
  import { CAUSE_TAGS, INCIDENT_STAGES, GRAVITY_LEVELS } from '$lib/types/incidents';
  
  // Icons
  import Check from '@lucide/svelte/icons/check';
  import ChevronLeft from '@lucide/svelte/icons/chevron-left';
  import ChevronRight from '@lucide/svelte/icons/chevron-right';

  // Props
  let { open = $bindable(false) }: { open: boolean } = $props();

  // State
  let currentStep = $state(1);
  let incidentId: string | null = $state(null);
  
  // Form states
  let initialData = $state<Partial<InitialDetails>>({
    suspectedIllegal: false,
    possibleCrossBorder: false
  });
  let updateData = $state<Partial<UpdateDetails>>({});
  let finalData = $state<Partial<FinalDetails>>({});
  let basicData = $state({
    causeTag: 'other' as CauseTag,
    significant: false,
    recurring: false,
    usersAffected: 0,
    downtimeMinutes: 0,
    financialImpactPct: 0,
  });

  function resetForm() {
    currentStep = 1;
    incidentId = null;
    initialData = {
      suspectedIllegal: false,
      possibleCrossBorder: false
    };
    updateData = {};
    finalData = {};
    basicData = {
      causeTag: 'other' as CauseTag,
      significant: false,
      recurring: false,
      usersAffected: 0,
      downtimeMinutes: 0,
      financialImpactPct: 0,
    };
  }

  function handleNext() {
    if (currentStep === 1) {
      // Validate and save initial data
      if (!initialData.summary || !initialData.detectedAt) {
        alert('Please fill in all required fields.');
        return;
      }

      let id = incidentId;
      if (!id) {
        const incident = incidentsStore.createIncident(basicData);
        id = incident.id;
        incidentId = id;
      }
      
      incidentsStore.setStageData(id, 'initial', initialData as InitialDetails);
      currentStep = 2;
    } else if (currentStep === 2) {
      // Save update data and move to final
      if (incidentId) {
        incidentsStore.updateIncident(incidentId, basicData);
        if (updateData.gravity || updateData.impact) {
          incidentsStore.setStageData(incidentId, 'update', updateData as UpdateDetails);
        }
      }
      currentStep = 3;
    } else if (currentStep === 3) {
      // Save final data and close
      if (incidentId) {
        if (finalData.rootCause || finalData.mitigations) {
          incidentsStore.setStageData(incidentId, 'final', finalData as FinalDetails);
        }
      }
      open = false;
      resetForm();
    }
  }

  function handlePrevious() {
    if (currentStep > 1) {
      currentStep = currentStep - 1;
    }
  }

  function handleClose() {
    open = false;
    resetForm();
  }

</script>

<Dialog.Root bind:open>
  <Dialog.Content class="w-[90vw] max-w-4xl max-h-[90vh] overflow-y-auto overflow-x-hidden">
    <!-- Header -->
    <div class="flex items-center justify-between px-8 py-6 border-b">
      <h2 class="text-2xl font-semibold">Report Incident</h2>
    </div>

    <div class="px-8 py-6">
      <!-- Step indicator -->
      <div class="flex items-center justify-between mb-8 px-4">
        {#each INCIDENT_STAGES as step, index}
          <div class="flex items-center flex-1 {index < INCIDENT_STAGES.length - 1 ? 'mr-4' : ''}">
            <div class="flex items-center justify-center w-8 h-8 rounded-full border-2 flex-shrink-0 {
              currentStep >= (step.value === 'initial' ? 1 : step.value === 'update' ? 2 : 3)
                ? 'bg-primary border-primary text-primary-foreground'
                : 'border-muted-foreground text-muted-foreground'
            }">
              {#if currentStep > (step.value === 'initial' ? 1 : step.value === 'update' ? 2 : 3)}
                <Check class="w-4 h-4" />
              {:else}
                <span class="text-xs font-medium">{step.value === 'initial' ? 1 : step.value === 'update' ? 2 : 3}</span>
              {/if}
            </div>
            <div class="ml-2 flex-1 min-w-0">
              <div class="text-xs font-medium truncate">{step.label}</div>
              <div class="text-xs text-muted-foreground truncate">{step.description}</div>
            </div>
            {#if index < INCIDENT_STAGES.length - 1}
              <ChevronRight class="w-4 h-4 text-muted-foreground ml-2 flex-shrink-0" />
            {/if}
          </div>
        {/each}
      </div>

    <!-- Step 1: Initial Report -->
    {#if currentStep === 1}
      <Card.Root>
        <Card.Header>
          <Card.Title>Initial Incident Report</Card.Title>
        </Card.Header>
        <Card.Content class="space-y-6">
          <div class="space-y-2">
            <Label for="summary" class="text-sm font-medium">Incident Summary *</Label>
            <Textarea
              id="summary"
              placeholder="Brief description of what happened..."
              bind:value={initialData.summary}
              class="min-h-[120px]"
            />
          </div>
          
          <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <div class="space-y-2">
              <Label for="detectedAt" class="text-sm font-medium">Detected At *</Label>
              <Input
                id="detectedAt"
                type="datetime-local"
                bind:value={initialData.detectedAt}
              />
            </div>

            <div class="space-y-2">
              <Label for="causeTag" class="text-sm font-medium">Suspected Cause</Label>
              <select 
                id="causeTag"
                class="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
                bind:value={basicData.causeTag}
              >
                {#each CAUSE_TAGS as cause}
                  <option value={cause.value}>{cause.label}</option>
                {/each}
              </select>
            </div>
          </div>

          <div class="space-y-3">
            <Label class="text-sm font-medium">Additional Information</Label>
            <div class="space-y-3">
              <div class="flex items-center space-x-2">
                <Checkbox
                  id="suspectedIllegal"
                  bind:checked={initialData.suspectedIllegal}
                />
                <Label for="suspectedIllegal" class="text-sm font-normal">Suspected illegal activity</Label>
              </div>
              
              <div class="flex items-center space-x-2">
                <Checkbox
                  id="possibleCrossBorder"
                  bind:checked={initialData.possibleCrossBorder}
                />
                <Label for="possibleCrossBorder" class="text-sm font-normal">Possible cross-border effects</Label>
              </div>
            </div>
          </div>
        </Card.Content>
      </Card.Root>
    {/if}

    <!-- Step 2: Update Report -->
    {#if currentStep === 2}
      <Card.Root>
        <Card.Header>
          <Card.Title>Impact Assessment</Card.Title>
        </Card.Header>
        <Card.Content class="space-y-4">
          <div class="grid grid-cols-3 gap-4">
            <div>
              <Label for="usersAffected">Users Affected</Label>
              <Input
                id="usersAffected"
                type="number"
                min="0"
                bind:value={basicData.usersAffected}
              />
            </div>
            
            <div>
              <Label for="downtimeMinutes">Downtime (minutes)</Label>
              <Input
                id="downtimeMinutes"
                type="number"
                min="0"
                bind:value={basicData.downtimeMinutes}
              />
            </div>
            
            <div>
              <Label for="financialImpactPct">Financial Impact (%)</Label>
              <Input
                id="financialImpactPct"
                type="number"
                min="0"
                max="100"
                step="0.1"
                bind:value={basicData.financialImpactPct}
              />
            </div>
          </div>

          <div>
            <Label for="gravity">Incident Gravity</Label>
            <select 
              class="flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50"
              bind:value={updateData.gravity}
            >
              <option value="">Select gravity level</option>
              {#each GRAVITY_LEVELS as level}
                <option value={level.value}>{level.label}</option>
              {/each}
            </select>
          </div>

          <div>
            <Label for="impact">Impact Description</Label>
            <Textarea
              id="impact"
              placeholder="Describe the impact on systems and operations..."
              bind:value={updateData.impact}
            />
          </div>

          <div>
            <Label for="corrections">Interim Actions Taken</Label>
            <Textarea
              id="corrections"
              placeholder="What immediate actions were taken to contain the incident..."
              bind:value={updateData.corrections}
            />
          </div>

          <div class="flex items-center space-x-4">
            <div class="flex items-center space-x-2">
              <Checkbox
                id="significant"
                bind:checked={basicData.significant}
              />
              <Label for="significant">Mark as significant incident</Label>
            </div>
            
            <div class="flex items-center space-x-2">
              <Checkbox
                id="recurring"
                bind:checked={basicData.recurring}
              />
              <Label for="recurring">Mark as recurring incident</Label>
            </div>
          </div>
        </Card.Content>
      </Card.Root>
    {/if}

    <!-- Step 3: Final Report -->
    {#if currentStep === 3}
      <Card.Root>
        <Card.Header>
          <Card.Title>Final Report</Card.Title>
        </Card.Header>
        <Card.Content class="space-y-4">
          <div>
            <Label for="rootCause">Root Cause Analysis</Label>
            <Textarea
              id="rootCause"
              placeholder="What was the underlying cause of this incident..."
              bind:value={finalData.rootCause}
            />
          </div>

          <div>
            <Label for="mitigations">Mitigations Implemented</Label>
            <Textarea
              id="mitigations"
              placeholder="What measures were put in place to prevent recurrence..."
              bind:value={finalData.mitigations}
            />
          </div>

          <div>
            <Label for="lessons">Lessons Learned</Label>
            <Textarea
              id="lessons"
              placeholder="Key takeaways and improvements for the future..."
              bind:value={finalData.lessons}
            />
          </div>

          <div>
            <Label for="crossBorderDesc">Cross-Border Effects (if any)</Label>
            <Textarea
              id="crossBorderDesc"
              placeholder="Describe any international implications..."
              bind:value={finalData.crossBorderDesc}
            />
          </div>
        </Card.Content>
      </Card.Root>
    {/if}

    <!-- Navigation buttons -->
    <div class="flex justify-between pt-6 mt-6 border-t">
      <Button
        variant="outline"
        onclick={handlePrevious}
        disabled={currentStep === 1}
      >
        <ChevronLeft class="w-4 h-4 mr-2" />
        Previous
      </Button>
      
      <div class="flex space-x-2">
        <Button variant="outline" onclick={handleClose}>
          Cancel
        </Button>
        <Button onclick={handleNext}>
          {currentStep === 3 ? 'Complete Report' : 'Next'}
          {#if currentStep < 3}
            <ChevronRight class="w-4 h-4 ml-2" />
          {/if}
        </Button>
      </div>
    </div>
    </div>
  </Dialog.Content>
</Dialog.Root>
