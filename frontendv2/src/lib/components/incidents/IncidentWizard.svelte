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
    FinalDetails,
    IncidentRecord 
  } from '$lib/types/incidents';
  import { CAUSE_TAGS, INCIDENT_STAGES, GRAVITY_LEVELS } from '$lib/types/incidents';
  
  // Icons
  import Check from '@lucide/svelte/icons/check';
  import ChevronLeft from '@lucide/svelte/icons/chevron-left';
  import ChevronRight from '@lucide/svelte/icons/chevron-right';
  import FileText from '@lucide/svelte/icons/file-text';
  import Printer from '@lucide/svelte/icons/printer';
  
  // PDF Export
  import jsPDF from 'jspdf';
  import html2canvas from 'html2canvas';

  // Props
  let { 
    open = $bindable(false),
    editIncident = null 
  }: { 
    open: boolean;
    editIncident?: IncidentRecord | null;
  } = $props();

  // State
  let currentStep = $state(1);
  let incidentId: string | null = $state(null);
  
  // Form states
  let initialData = $state<Partial<InitialDetails>>({
    title: '',
    summary: '',
    detectedAt: '',
    suspectedIllegal: false,
    possibleCrossBorder: false
  });
  let updateData = $state<Partial<UpdateDetails>>({
    gravity: '',
    impact: ''
  });
  let finalData = $state<Partial<FinalDetails>>({
    rootCause: '',
    mitigations: '',
    lessons: '',
    crossBorderDesc: ''
  });
  let basicData = $state({
    causeTag: 'other' as CauseTag,
    significant: false,
    recurring: false,
    usersAffected: 0,
    downtimeMinutes: 0,
    financialImpactPct: 0,
  });

  // Effect to populate form when editing or reset when creating
  $effect(() => {
    if (open) {
      if (editIncident) {
        // Populate form with existing incident data
        incidentId = editIncident.id;
        
        // Set basic data
        basicData.causeTag = editIncident.causeTag || 'other';
        basicData.significant = editIncident.significant || false;
        basicData.recurring = editIncident.recurring || false;
        basicData.usersAffected = editIncident.usersAffected || 0;
        basicData.downtimeMinutes = editIncident.downtimeMinutes || 0;
        basicData.financialImpactPct = editIncident.financialImpactPct || 0;
        
        // Set initial data
        if (editIncident.details.initial) {
          initialData.title = editIncident.details.initial.title || '';
          initialData.summary = editIncident.details.initial.summary || '';
          initialData.detectedAt = editIncident.details.initial.detectedAt || '';
          initialData.suspectedIllegal = editIncident.details.initial.suspectedIllegal || false;
          initialData.possibleCrossBorder = editIncident.details.initial.possibleCrossBorder || false;
        }
        
        // Set update data
        if (editIncident.details.update) {
          updateData.gravity = editIncident.details.update.gravity || '';
          updateData.impact = editIncident.details.update.impact || '';
          updateData.corrections = editIncident.details.update.corrections || '';
        }
        
        // Set final data
        if (editIncident.details.final) {
          finalData.rootCause = editIncident.details.final.rootCause || '';
          finalData.mitigations = editIncident.details.final.mitigations || '';
          finalData.lessons = editIncident.details.final.lessons || '';
          finalData.crossBorderDesc = editIncident.details.final.crossBorderDesc || '';
        }
        
        // Set current step based on the incident stage
        if (editIncident.stage === 'final') {
          currentStep = 3;
        } else if (editIncident.stage === 'update') {
          currentStep = 2;
        } else {
          currentStep = 1;
        }
      } else {
        // Reset form for new incident
        resetForm();
      }
    }
  });

  function resetForm() {
    currentStep = 1;
    incidentId = null;
    initialData = {
      title: '',
      summary: '',
      detectedAt: '',
      suspectedIllegal: false,
      possibleCrossBorder: false
    };
    updateData = {
      gravity: '',
      impact: ''
    };
    finalData = {
      rootCause: '',
      mitigations: '',
      lessons: '',
      crossBorderDesc: ''
    };
    basicData = {
      causeTag: 'other' as CauseTag,
      significant: false,
      recurring: false,
      usersAffected: 0,
      downtimeMinutes: 0,
      financialImpactPct: 0,
    };
  }

  async function handleNext() {
    if (currentStep === 1) {
      // Validate and save initial data
      if (!initialData.title || !initialData.summary || !initialData.detectedAt) {
        alert('Please fill in all required fields.');
        return;
      }

      let id = incidentId;
      if (!id) {
        // Create new incident
        const incident = await incidentsStore.createIncident(initialData as InitialDetails, {
          significant: basicData.significant,
          recurring: basicData.recurring,
          causeTag: basicData.causeTag,
          usersAffected: basicData.usersAffected || undefined,
          downtimeMinutes: basicData.downtimeMinutes || undefined,
          financialImpactPct: basicData.financialImpactPct || undefined
        });
        
        if (!incident) {
          alert('Failed to create incident. Please try again.');
          return;
        }
        
        id = incident.id;
        incidentId = id;
      } else {
        // Update existing incident
        await incidentsStore.updateIncident(id, 'initial', {
          significant: basicData.significant,
          recurring: basicData.recurring,
          causeTag: basicData.causeTag,
          usersAffected: basicData.usersAffected || undefined,
          downtimeMinutes: basicData.downtimeMinutes || undefined,
          financialImpactPct: basicData.financialImpactPct || undefined,
          initialDetails: initialData as InitialDetails
        });
      }
      
      currentStep = 2;
    } else if (currentStep === 2) {
      // Validate and save update data
      if (!updateData.gravity || !updateData.impact) {
        alert('Please fill in all required fields.');
        return;
      }

      if (incidentId) {
        await incidentsStore.updateIncident(incidentId, 'update', {
          significant: basicData.significant,
          recurring: basicData.recurring,
          causeTag: basicData.causeTag,
          usersAffected: basicData.usersAffected || undefined,
          downtimeMinutes: basicData.downtimeMinutes || undefined,
          financialImpactPct: basicData.financialImpactPct || undefined,
          updateDetails: updateData as UpdateDetails
        });
      }
      currentStep = 3;
    } else if (currentStep === 3) {
      // Validate and complete the incident
      if (!finalData.rootCause || !finalData.mitigations) {
        alert('Please fill in all required fields.');
        return;
      }

      if (incidentId) {
        await incidentsStore.updateIncident(incidentId, 'final', {
          significant: basicData.significant,
          recurring: basicData.recurring,
          causeTag: basicData.causeTag,
          usersAffected: basicData.usersAffected || undefined,
          downtimeMinutes: basicData.downtimeMinutes || undefined,
          financialImpactPct: basicData.financialImpactPct || undefined,
          finalDetails: finalData as FinalDetails
        });
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

  function handleStepClick(targetStep: number) {
    // Allow backward navigation freely
    if (targetStep < currentStep) {
      currentStep = targetStep;
      return;
    }
    
    // For forward navigation, validate all previous steps
    if (targetStep > currentStep) {
      // Always check Step 1 requirements when moving forward
      if (!initialData.title || !initialData.summary || !initialData.detectedAt) {
        alert('Please complete Step 1 required fields (Incident Title, Summary, and Detected At) before proceeding.');
        return;
      }
      
      // If jumping to Step 3, also check Step 2 requirements
      if (targetStep === 3) {
        if (!updateData.gravity || !updateData.impact) {
          alert('Please complete Step 2 required fields (Incident Gravity and Impact Description) before proceeding to Step 3.');
          return;
        }
      }
    }
    
    // Allow navigation if validation passes or staying on same step
    if (targetStep >= 1 && targetStep <= 3) {
      currentStep = targetStep;
    }
  }

  async function handleSaveAndExit() {
    // Save current progress as draft (no validation required)
    let id = incidentId;
    
    if (!id && (initialData.title || initialData.summary)) {
      // Create incident if it doesn't exist and there's some initial data
      const incident = await incidentsStore.createIncident(initialData as InitialDetails, {
        significant: basicData.significant,
        recurring: basicData.recurring,
        causeTag: basicData.causeTag,
        usersAffected: basicData.usersAffected || undefined,
        downtimeMinutes: basicData.downtimeMinutes || undefined,
        financialImpactPct: basicData.financialImpactPct || undefined
      });
      
      if (incident) {
        id = incident.id;
        incidentId = id;
      }
    } else if (id) {
      // Determine the highest stage based on available data
      let stage: 'initial' | 'update' | 'final' = 'initial';
      let stageData: any = {};
      
      // Always include initial details if available
      if (initialData.title || initialData.summary) {
        stageData.initialDetails = initialData as InitialDetails;
      }
      
      // Include update details if available and set stage to update
      if (updateData.gravity || updateData.impact || updateData.corrections) {
        stage = 'update';
        stageData.updateDetails = updateData as UpdateDetails;
      }
      
      // Include final details if available and set stage to final
      if (finalData.rootCause || finalData.mitigations || finalData.lessons) {
        stage = 'final';
        stageData.finalDetails = finalData as FinalDetails;
      }
      
      await incidentsStore.updateIncident(id, stage, {
        significant: basicData.significant,
        recurring: basicData.recurring,
        causeTag: basicData.causeTag,
        usersAffected: basicData.usersAffected || undefined,
        downtimeMinutes: basicData.downtimeMinutes || undefined,
        financialImpactPct: basicData.financialImpactPct || undefined,
        ...stageData
      });
    }

    // Close the dialog
    open = false;
    resetForm();
  }

  // PDF Export Functions
  async function exportToPDF(reportType: 'initial' | 'update' | 'final') {
    try {
      const pdf = new jsPDF();
      const pageWidth = pdf.internal.pageSize.getWidth();
      const pageHeight = pdf.internal.pageSize.getHeight();
      const margin = 20;
      let yPosition = margin;

      // Set up document title
      pdf.setFontSize(20);
      pdf.setFont('helvetica', 'bold');
      
      let reportTitle = '';
      switch (reportType) {
        case 'initial':
          reportTitle = 'Initial Incident Report';
          break;
        case 'update':
          reportTitle = 'Update Incident Report';
          break;
        case 'final':
          reportTitle = 'Final Incident Report';
          break;
      }
      
      pdf.text(reportTitle, margin, yPosition);
      yPosition += 20;

      // Add incident ID if available
      if (incidentId) {
        pdf.setFontSize(12);
        pdf.setFont('helvetica', 'normal');
        pdf.text(`Incident ID: ${incidentId}`, margin, yPosition);
        yPosition += 15;
      }

      // Add timestamp
      pdf.text(`Generated: ${new Date().toLocaleString()}`, margin, yPosition);
      yPosition += 20;

      // Set up content styling
      pdf.setFontSize(12);
      pdf.setFont('helvetica', 'normal');

      // Add content based on report type
      if (reportType === 'initial' || reportType === 'update' || reportType === 'final') {
        // Basic Information (always included)
        if (basicData.significant || basicData.recurring || basicData.causeTag !== 'other') {
          pdf.setFont('helvetica', 'bold');
          pdf.text('Basic Information:', margin, yPosition);
          yPosition += 10;
          pdf.setFont('helvetica', 'normal');
          
          if (basicData.significant) {
            pdf.text('• Significant Incident: Yes', margin + 10, yPosition);
            yPosition += 8;
          }
          if (basicData.recurring) {
            pdf.text('• Recurring Incident: Yes', margin + 10, yPosition);
            yPosition += 8;
          }
          if (basicData.causeTag !== 'other') {
            const causeLabel = CAUSE_TAGS.find(c => c.value === basicData.causeTag)?.label || basicData.causeTag;
            pdf.text(`• Suspected Cause: ${causeLabel}`, margin + 10, yPosition);
            yPosition += 8;
          }
          yPosition += 10;
        }
      }

      // Initial Report Content
      if (reportType === 'initial' && (initialData.title || initialData.summary)) {
        pdf.setFont('helvetica', 'bold');
        pdf.text('Initial Report Details:', margin, yPosition);
        yPosition += 10;
        pdf.setFont('helvetica', 'normal');

        if (initialData.title) {
          pdf.text(`Title: ${initialData.title}`, margin + 10, yPosition);
          yPosition += 8;
        }
        
        if (initialData.detectedAt) {
          pdf.text(`Detected At: ${new Date(initialData.detectedAt).toLocaleString()}`, margin + 10, yPosition);
          yPosition += 8;
        }

        if (initialData.summary) {
          pdf.text('Summary:', margin + 10, yPosition);
          yPosition += 8;
          const summaryLines = pdf.splitTextToSize(initialData.summary, pageWidth - margin * 2 - 20);
          pdf.text(summaryLines, margin + 20, yPosition);
          yPosition += summaryLines.length * 6 + 10;
        }

        if (initialData.suspectedIllegal) {
          pdf.text('• Suspected illegal activity', margin + 10, yPosition);
          yPosition += 8;
        }

        if (initialData.possibleCrossBorder) {
          pdf.text('• Possible cross-border effects', margin + 10, yPosition);
          yPosition += 8;
        }
      }

      // Update Report Content
      if (reportType === 'update' && (updateData.gravity || updateData.impact || updateData.corrections)) {
        pdf.setFont('helvetica', 'bold');
        pdf.text('Impact Assessment:', margin, yPosition);
        yPosition += 10;
        pdf.setFont('helvetica', 'normal');

        // Impact metrics
        if (basicData.usersAffected || basicData.downtimeMinutes || basicData.financialImpactPct) {
          pdf.text('Impact Metrics:', margin + 10, yPosition);
          yPosition += 8;
          
          if (basicData.usersAffected) {
            pdf.text(`• Users Affected: ${basicData.usersAffected}`, margin + 20, yPosition);
            yPosition += 6;
          }
          if (basicData.downtimeMinutes) {
            pdf.text(`• Downtime: ${basicData.downtimeMinutes} minutes`, margin + 20, yPosition);
            yPosition += 6;
          }
          if (basicData.financialImpactPct) {
            pdf.text(`• Financial Impact: ${basicData.financialImpactPct}%`, margin + 20, yPosition);
            yPosition += 6;
          }
          yPosition += 8;
        }

        if (updateData.gravity) {
          const gravityLabel = GRAVITY_LEVELS.find(g => g.value === updateData.gravity)?.label || updateData.gravity;
          pdf.text(`Incident Gravity: ${gravityLabel}`, margin + 10, yPosition);
          yPosition += 8;
        }

        if (updateData.impact) {
          pdf.text('Impact Description:', margin + 10, yPosition);
          yPosition += 8;
          const impactLines = pdf.splitTextToSize(updateData.impact, pageWidth - margin * 2 - 20);
          pdf.text(impactLines, margin + 20, yPosition);
          yPosition += impactLines.length * 6 + 10;
        }

        if (updateData.corrections) {
          pdf.text('Interim Actions Taken:', margin + 10, yPosition);
          yPosition += 8;
          const correctionsLines = pdf.splitTextToSize(updateData.corrections, pageWidth - margin * 2 - 20);
          pdf.text(correctionsLines, margin + 20, yPosition);
          yPosition += correctionsLines.length * 6 + 10;
        }
      }

      // Final Report Content
      if (reportType === 'final' && (finalData.rootCause || finalData.mitigations || finalData.lessons)) {
        pdf.setFont('helvetica', 'bold');
        pdf.text('Final Report Details:', margin, yPosition);
        yPosition += 10;
        pdf.setFont('helvetica', 'normal');

        if (finalData.rootCause) {
          pdf.text('Root Cause Analysis:', margin + 10, yPosition);
          yPosition += 8;
          const rootCauseLines = pdf.splitTextToSize(finalData.rootCause, pageWidth - margin * 2 - 20);
          pdf.text(rootCauseLines, margin + 20, yPosition);
          yPosition += rootCauseLines.length * 6 + 10;
        }

        if (finalData.mitigations) {
          pdf.text('Mitigations Implemented:', margin + 10, yPosition);
          yPosition += 8;
          const mitigationsLines = pdf.splitTextToSize(finalData.mitigations, pageWidth - margin * 2 - 20);
          pdf.text(mitigationsLines, margin + 20, yPosition);
          yPosition += mitigationsLines.length * 6 + 10;
        }

        if (finalData.lessons) {
          pdf.text('Lessons Learned:', margin + 10, yPosition);
          yPosition += 8;
          const lessonsLines = pdf.splitTextToSize(finalData.lessons, pageWidth - margin * 2 - 20);
          pdf.text(lessonsLines, margin + 20, yPosition);
          yPosition += lessonsLines.length * 6 + 10;
        }

        if (finalData.crossBorderDesc) {
          pdf.text('Cross-Border Effects:', margin + 10, yPosition);
          yPosition += 8;
          const crossBorderLines = pdf.splitTextToSize(finalData.crossBorderDesc, pageWidth - margin * 2 - 20);
          pdf.text(crossBorderLines, margin + 20, yPosition);
          yPosition += crossBorderLines.length * 6 + 10;
        }
      }

      // Save the PDF
      const fileName = `${reportType}-report-${incidentId || 'new'}-${new Date().toISOString().split('T')[0]}.pdf`;
      pdf.save(fileName);
    } catch (error) {
      console.error('Failed to export PDF:', error);
      alert('Failed to export PDF. Please try again.');
    }
  }

  function printReport(reportType: 'initial' | 'update' | 'final') {
    // Use browser's print functionality with a formatted version
    const printWindow = window.open('', '_blank');
    if (!printWindow) return;

    let reportTitle = '';
    let reportContent = '';

    switch (reportType) {
      case 'initial':
        reportTitle = 'Initial Incident Report';
        reportContent = `
          <h2>Basic Information</h2>
          ${initialData.title ? `<p><strong>Title:</strong> ${initialData.title}</p>` : ''}
          ${initialData.detectedAt ? `<p><strong>Detected At:</strong> ${new Date(initialData.detectedAt).toLocaleString()}</p>` : ''}
          ${initialData.summary ? `<p><strong>Summary:</strong><br>${initialData.summary.replace(/\n/g, '<br>')}</p>` : ''}
          ${basicData.significant ? '<p>• Significant Incident</p>' : ''}
          ${basicData.recurring ? '<p>• Recurring Incident</p>' : ''}
          ${initialData.suspectedIllegal ? '<p>• Suspected illegal activity</p>' : ''}
          ${initialData.possibleCrossBorder ? '<p>• Possible cross-border effects</p>' : ''}
        `;
        break;
      case 'update':
        reportTitle = 'Update Incident Report';
        reportContent = `
          <h2>Impact Assessment</h2>
          ${basicData.usersAffected ? `<p><strong>Users Affected:</strong> ${basicData.usersAffected}</p>` : ''}
          ${basicData.downtimeMinutes ? `<p><strong>Downtime:</strong> ${basicData.downtimeMinutes} minutes</p>` : ''}
          ${basicData.financialImpactPct ? `<p><strong>Financial Impact:</strong> ${basicData.financialImpactPct}%</p>` : ''}
          ${updateData.gravity ? `<p><strong>Incident Gravity:</strong> ${GRAVITY_LEVELS.find(g => g.value === updateData.gravity)?.label || updateData.gravity}</p>` : ''}
          ${updateData.impact ? `<p><strong>Impact Description:</strong><br>${updateData.impact.replace(/\n/g, '<br>')}</p>` : ''}
          ${updateData.corrections ? `<p><strong>Interim Actions Taken:</strong><br>${updateData.corrections.replace(/\n/g, '<br>')}</p>` : ''}
          ${basicData.significant ? '<p>• Significant Incident</p>' : ''}
          ${basicData.recurring ? '<p>• Recurring Incident</p>' : ''}
        `;
        break;
      case 'final':
        reportTitle = 'Final Incident Report';
        reportContent = `
          <h2>Final Report</h2>
          ${finalData.rootCause ? `<p><strong>Root Cause Analysis:</strong><br>${finalData.rootCause.replace(/\n/g, '<br>')}</p>` : ''}
          ${finalData.mitigations ? `<p><strong>Mitigations Implemented:</strong><br>${finalData.mitigations.replace(/\n/g, '<br>')}</p>` : ''}
          ${finalData.lessons ? `<p><strong>Lessons Learned:</strong><br>${finalData.lessons.replace(/\n/g, '<br>')}</p>` : ''}
          ${finalData.crossBorderDesc ? `<p><strong>Cross-Border Effects:</strong><br>${finalData.crossBorderDesc.replace(/\n/g, '<br>')}</p>` : ''}
        `;
        break;
    }

    const htmlContent = `
      <!DOCTYPE html>
      <html>
      <head>
        <title>${reportTitle}</title>
        <style>
          body { font-family: Arial, sans-serif; margin: 20px; line-height: 1.6; }
          h1 { color: #333; border-bottom: 2px solid #333; padding-bottom: 10px; }
          h2 { color: #666; margin-top: 30px; }
          p { margin: 10px 0; }
          strong { color: #333; }
          @media print {
            body { margin: 0; }
            h1 { page-break-after: avoid; }
          }
        </style>
      </head>
      <body>
        <h1>${reportTitle}</h1>
        ${incidentId ? `<p><strong>Incident ID:</strong> ${incidentId}</p>` : ''}
        <p><strong>Generated:</strong> ${new Date().toLocaleString()}</p>
        ${reportContent}
      </body>
      </html>
    `;

    printWindow.document.write(htmlContent);
    printWindow.document.close();
    printWindow.focus();
    printWindow.print();
  }

</script>

<Dialog.Root bind:open>
  <Dialog.Content class="!max-w-[90vw] max-h-[90vh] overflow-y-auto">
    <!-- Header -->
    <div class="flex items-center justify-between px-8 py-6 border-b">
      <h2 class="text-2xl font-semibold">{editIncident ? 'Edit Incident' : 'Report Incident'}</h2>
    </div>

    <div class="px-8 py-6">
      <!-- Step indicator -->
      <div class="flex items-center justify-between mb-8 px-4">
        {#each INCIDENT_STAGES as step, index}
          <div class="flex items-center flex-1 {index < INCIDENT_STAGES.length - 1 ? 'mr-4' : ''}">
            <button
              class="flex items-center justify-center w-8 h-8 rounded-full border-2 flex-shrink-0 transition-colors hover:bg-muted {
                currentStep >= (step.value === 'initial' ? 1 : step.value === 'update' ? 2 : 3)
                  ? 'bg-primary border-primary text-primary-foreground'
                  : 'border-muted-foreground text-muted-foreground hover:border-primary'
              }"
              onclick={() => handleStepClick(step.value === 'initial' ? 1 : step.value === 'update' ? 2 : 3)}
            >
              {#if currentStep > (step.value === 'initial' ? 1 : step.value === 'update' ? 2 : 3)}
                <Check class="w-4 h-4" />
              {:else}
                <span class="text-xs font-medium">{step.value === 'initial' ? 1 : step.value === 'update' ? 2 : 3}</span>
              {/if}
            </button>
            <button
              class="ml-2 flex-1 min-w-0 text-left transition-colors hover:text-primary"
              onclick={() => handleStepClick(step.value === 'initial' ? 1 : step.value === 'update' ? 2 : 3)}
            >
              <div class="text-xs font-medium truncate">{step.label}</div>
              <div class="text-xs text-muted-foreground truncate">{step.description}</div>
            </button>
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
          <div class="flex items-center justify-between">
            <Card.Title>Initial Incident Report</Card.Title>
            <div class="flex space-x-2">
              <Button 
                variant="outline" 
                size="sm" 
                onclick={() => printReport('initial')}
                title="Print Initial Report"
              >
                <Printer class="w-4 h-4" />
              </Button>
              <Button 
                variant="outline" 
                size="sm" 
                onclick={() => exportToPDF('initial')}
                title="Export Initial Report as PDF"
              >
                <FileText class="w-4 h-4" />
              </Button>
            </div>
          </div>
        </Card.Header>
        <Card.Content class="space-y-6">
          <div class="space-y-2">
            <Label for="title" class="text-sm font-medium">Incident Title *</Label>
            <Input
              id="title"
              placeholder="Short descriptive title for the incident..."
              bind:value={initialData.title}
            />
          </div>
          
          <div class="space-y-2">
            <Label for="summary" class="text-sm font-medium">Incident Summary *</Label>
            <textarea
              id="summary"
              placeholder="Detailed description of what happened..."
              bind:value={initialData.summary}
              class="flex min-h-[120px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
            ></textarea>
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
          <div class="flex items-center justify-between">
            <Card.Title>Impact Assessment</Card.Title>
            <div class="flex space-x-2">
              <Button 
                variant="outline" 
                size="sm" 
                onclick={() => printReport('update')}
                title="Print Update Report"
              >
                <Printer class="w-4 h-4" />
              </Button>
              <Button 
                variant="outline" 
                size="sm" 
                onclick={() => exportToPDF('update')}
                title="Export Update Report as PDF"
              >
                <FileText class="w-4 h-4" />
              </Button>
            </div>
          </div>
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
            <Label for="gravity" class="text-sm font-medium">Incident Gravity *</Label>
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
            <Label for="impact" class="text-sm font-medium">Impact Description *</Label>
            <textarea
              id="impact"
              placeholder="Describe the impact on systems and operations..."
              bind:value={updateData.impact}
              class="flex min-h-[120px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
            ></textarea>
          </div>

          <div>
            <Label for="corrections">Interim Actions Taken</Label>
            <textarea
              id="corrections"
              placeholder="What immediate actions were taken to contain the incident..."
              bind:value={updateData.corrections}
              class="flex min-h-[120px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
            ></textarea>
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
          <div class="flex items-center justify-between">
            <Card.Title>Final Report</Card.Title>
            <div class="flex space-x-2">
              <Button 
                variant="outline" 
                size="sm" 
                onclick={() => printReport('final')}
                title="Print Final Report"
              >
                <Printer class="w-4 h-4" />
              </Button>
              <Button 
                variant="outline" 
                size="sm" 
                onclick={() => exportToPDF('final')}
                title="Export Final Report as PDF"
              >
                <FileText class="w-4 h-4" />
              </Button>
            </div>
          </div>
        </Card.Header>
        <Card.Content class="space-y-4">
          <div>
            <Label for="rootCause" class="text-sm font-medium">Root Cause Analysis *</Label>
            <textarea
              id="rootCause"
              placeholder="What was the underlying cause of this incident..."
              bind:value={finalData.rootCause}
              class="flex min-h-[120px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
            ></textarea>
          </div>

          <div>
            <Label for="mitigations" class="text-sm font-medium">Mitigations Implemented *</Label>
            <textarea
              id="mitigations"
              placeholder="What measures were put in place to prevent recurrence..."
              bind:value={finalData.mitigations}
              class="flex min-h-[120px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
            ></textarea>
          </div>

          <div>
            <Label for="lessons">Lessons Learned</Label>
            <textarea
              id="lessons"
              placeholder="Key takeaways and improvements for the future..."
              bind:value={finalData.lessons}
              class="flex min-h-[120px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
            ></textarea>
          </div>

          <div>
            <Label for="crossBorderDesc">Cross-Border Effects (if any)</Label>
            <textarea
              id="crossBorderDesc"
              placeholder="Describe any international implications..."
              bind:value={finalData.crossBorderDesc}
              class="flex min-h-[120px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
            ></textarea>
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
        <Button variant="outline" onclick={handleSaveAndExit}>
          Save & Exit
        </Button>
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
