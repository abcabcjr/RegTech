import type { 
  IncidentRecord, 
  IncidentStage, 
  CauseTag, 
  InitialDetails, 
  UpdateDetails, 
  FinalDetails 
} from '$lib/types/incidents';
import { apiClient } from '$lib/api/client';
import type { 
  V1IncidentResponse,
  V1IncidentSummaryResponse,
  V1CreateIncidentRequest,
  V1UpdateIncidentRequest,
  V1IncidentStatsResponse
} from '$lib/api/Api';

export class IncidentsStore {
  // State
  incidents: IncidentRecord[] = $state([]);
  selectedIncident: IncidentRecord | null = $state(null);
  loading = $state(false);
  error: string | null = $state(null);

  // Computed
  get incidentCount() {
    return this.incidents.length;
  }

  get significantIncidents() {
    return this.incidents.filter(incident => incident.significant);
  }

  get incidentsByStage() {
    return {
      initial: this.incidents.filter(incident => incident.stage === 'initial'),
      update: this.incidents.filter(incident => incident.stage === 'update'),
      final: this.incidents.filter(incident => incident.stage === 'final')
    };
  }

  // Actions
  async loadIncidents() {
    if (this.loading) return;
    this.loading = true;
    this.error = null;

    try {
      const response = await apiClient.incidents.incidentsList();
      // Convert API response to frontend types
      this.incidents = response.data.incidents.map(this.convertFromAPI);
    } catch (error) {
      console.error('Failed to load incidents:', error);
      this.error = error instanceof Error ? error.message : 'Failed to load incidents';
      this.incidents = [];
    } finally {
      this.loading = false;
    }
  }

  async loadIncidentSummaries() {
    if (this.loading) return;
    this.loading = true;
    this.error = null;

    try {
      const response = await apiClient.incidents.incidentsSummariesList();
      // Convert summaries to full incident records for UI compatibility
      this.incidents = response.data.summaries.map(this.convertSummaryToIncident);
    } catch (error) {
      console.error('Failed to load incident summaries:', error);
      this.error = error instanceof Error ? error.message : 'Failed to load incident summaries';
      this.incidents = [];
    } finally {
      this.loading = false;
    }
  }

  async createIncident(
    initialDetails: InitialDetails,
    options: {
      significant?: boolean;
      recurring?: boolean;
      causeTag?: CauseTag;
      usersAffected?: number;
      downtimeMinutes?: number;
      financialImpactPct?: number;
      sectorPreset?: string;
      attachments?: Array<{ name: string; note?: string }>;
    } = {}
  ): Promise<IncidentRecord | null> {
    this.loading = true;
    this.error = null;

    try {
      const request: V1CreateIncidentRequest = {
        initialDetails: {
          title: initialDetails.title,
          summary: initialDetails.summary,
          detectedAt: initialDetails.detectedAt,
          suspectedIllegal: initialDetails.suspectedIllegal,
          possibleCrossBorder: initialDetails.possibleCrossBorder
        },
        significant: options.significant || false,
        recurring: options.recurring || false,
        causeTag: options.causeTag || 'other',
        usersAffected: options.usersAffected,
        downtimeMinutes: options.downtimeMinutes,
        financialImpactPct: options.financialImpactPct,
        sectorPreset: options.sectorPreset,
        attachments: options.attachments || []
      };

      const response = await apiClient.incidents.incidentsCreate(request);
      const newIncident = this.convertFromAPI(response.data);
      
      // Add to local state
      this.incidents = [...this.incidents, newIncident];
      return newIncident;
    } catch (error) {
      console.error('Failed to create incident:', error);
      this.error = error instanceof Error ? error.message : 'Failed to create incident';
      return null;
    } finally {
      this.loading = false;
    }
  }

  async updateIncident(
    id: string, 
    stage: IncidentStage,
    updates: {
      significant?: boolean;
      recurring?: boolean;
      causeTag?: CauseTag;
      usersAffected?: number;
      downtimeMinutes?: number;
      financialImpactPct?: number;
      sectorPreset?: string;
      initialDetails?: InitialDetails;
      updateDetails?: UpdateDetails;
      finalDetails?: FinalDetails;
      attachments?: Array<{ name: string; note?: string }>;
    }
  ): Promise<IncidentRecord | null> {
    this.loading = true;
    this.error = null;

    try {
      const request: V1UpdateIncidentRequest = {
        stage,
        significant: updates.significant || false,
        recurring: updates.recurring || false,
        causeTag: updates.causeTag || 'other',
        usersAffected: updates.usersAffected,
        downtimeMinutes: updates.downtimeMinutes,
        financialImpactPct: updates.financialImpactPct,
        sectorPreset: updates.sectorPreset,
        initialDetails: updates.initialDetails ? {
          title: updates.initialDetails.title,
          summary: updates.initialDetails.summary,
          detectedAt: updates.initialDetails.detectedAt,
          suspectedIllegal: updates.initialDetails.suspectedIllegal,
          possibleCrossBorder: updates.initialDetails.possibleCrossBorder
        } : undefined,
        updateDetails: updates.updateDetails ? {
          gravity: updates.updateDetails.gravity,
          impact: updates.updateDetails.impact,
          iocs: updates.updateDetails.iocs,
          corrections: updates.updateDetails.corrections
        } : undefined,
        finalDetails: updates.finalDetails ? {
          rootCause: updates.finalDetails.rootCause,
          gravity: updates.finalDetails.gravity,
          impact: updates.finalDetails.impact,
          mitigations: updates.finalDetails.mitigations,
          crossBorderDesc: updates.finalDetails.crossBorderDesc,
          lessons: updates.finalDetails.lessons
        } : undefined,
        attachments: updates.attachments
      };

      const response = await apiClient.incidents.incidentsUpdate(id, request);
      const updatedIncident = this.convertFromAPI(response.data);

      // Update local state
      const index = this.incidents.findIndex(incident => incident.id === id);
      if (index !== -1) {
        this.incidents = [
          ...this.incidents.slice(0, index),
          updatedIncident,
          ...this.incidents.slice(index + 1)
        ];
      }

      // Update selected incident if it's the one being updated
      if (this.selectedIncident?.id === id) {
        this.selectedIncident = updatedIncident;
      }

      return updatedIncident;
    } catch (error) {
      console.error('Failed to update incident:', error);
      this.error = error instanceof Error ? error.message : 'Failed to update incident';
      return null;
    } finally {
      this.loading = false;
    }
  }

  async deleteIncident(id: string): Promise<boolean> {
    this.loading = true;
    this.error = null;

    try {
      await apiClient.incidents.incidentsDelete(id);
      
      // Remove from local state
      this.incidents = this.incidents.filter(incident => incident.id !== id);
      
      // Clear selection if deleted incident was selected
      if (this.selectedIncident?.id === id) {
        this.selectedIncident = null;
      }

      return true;
    } catch (error) {
      console.error('Failed to delete incident:', error);
      this.error = error instanceof Error ? error.message : 'Failed to delete incident';
      return false;
    } finally {
      this.loading = false;
    }
  }

  async getIncident(id: string): Promise<IncidentRecord | null> {
    this.loading = true;
    this.error = null;

    try {
      const response = await apiClient.incidents.incidentsDetail(id);
      return this.convertFromAPI(response.data);
    } catch (error) {
      console.error('Failed to get incident:', error);
      this.error = error instanceof Error ? error.message : 'Failed to get incident';
      return null;
    } finally {
      this.loading = false;
    }
  }

  async getIncidentStats(): Promise<V1IncidentStatsResponse | null> {
    this.loading = true;
    this.error = null;

    try {
      const response = await apiClient.incidents.incidentsStats();
      return response.data;
    } catch (error) {
      console.error('Failed to get incident stats:', error);
      this.error = error instanceof Error ? error.message : 'Failed to get incident stats';
      return null;
    } finally {
      this.loading = false;
    }
  }

  selectIncident(incident: IncidentRecord | null) {
    this.selectedIncident = incident;
  }

  exportIncidentJSON(id: string) {
    const incident = this.incidents.find(i => i.id === id);
    if (!incident) return;

    const dataStr = JSON.stringify(incident, null, 2);
    const dataBlob = new Blob([dataStr], { type: 'application/json' });
    const url = URL.createObjectURL(dataBlob);
    
    const link = document.createElement('a');
    link.href = url;
    link.download = `incident-${incident.id}-${new Date().toISOString().split('T')[0]}.json`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
  }

  // Utility methods
  getIncidentSummary(incident: IncidentRecord): string {
    return incident.details.initial?.title || 'Untitled Incident';
  }

  getIncidentStatusColor(stage: IncidentStage): string {
    switch (stage) {
      case 'initial':
        return 'bg-yellow-100 text-yellow-800';
      case 'update':
        return 'bg-blue-100 text-blue-800';
      case 'final':
        return 'bg-green-100 text-green-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  }

  getCauseTagLabel(causeTag: CauseTag): string {
    const labels = {
      phishing: 'Phishing Attack',
      vuln_exploit: 'Vulnerability Exploitation',
      misconfig: 'Misconfiguration',
      malware: 'Malware',
      other: 'Other'
    };
    return labels[causeTag] || causeTag;
  }

  // Conversion methods
  private convertFromAPI(apiIncident: V1IncidentResponse): IncidentRecord {
    return {
      id: apiIncident.id,
      createdAt: apiIncident.createdAt,
      updatedAt: apiIncident.updatedAt,
      stage: apiIncident.stage as IncidentStage,
      significant: apiIncident.significant,
      recurring: apiIncident.recurring,
      causeTag: apiIncident.causeTag as CauseTag,
      usersAffected: apiIncident.usersAffected,
      downtimeMinutes: apiIncident.downtimeMinutes,
      financialImpactPct: apiIncident.financialImpactPct,
      sectorPreset: apiIncident.sectorPreset,
      details: {
        initial: apiIncident.details.initial ? {
          title: apiIncident.details.initial.title,
          summary: apiIncident.details.initial.summary,
          detectedAt: apiIncident.details.initial.detectedAt,
          suspectedIllegal: apiIncident.details.initial.suspectedIllegal,
          possibleCrossBorder: apiIncident.details.initial.possibleCrossBorder
        } : undefined,
        update: apiIncident.details.update ? {
          gravity: apiIncident.details.update.gravity,
          impact: apiIncident.details.update.impact,
          iocs: apiIncident.details.update.iocs,
          corrections: apiIncident.details.update.corrections
        } : undefined,
        final: apiIncident.details.final ? {
          rootCause: apiIncident.details.final.rootCause,
          gravity: apiIncident.details.final.gravity,
          impact: apiIncident.details.final.impact,
          mitigations: apiIncident.details.final.mitigations,
          crossBorderDesc: apiIncident.details.final.crossBorderDesc,
          lessons: apiIncident.details.final.lessons
        } : undefined
      },
      attachments: apiIncident.attachments?.map(att => ({
        name: att.name,
        note: att.note
      })) || []
    };
  }

  private convertSummaryToIncident(summary: V1IncidentSummaryResponse): IncidentRecord {
    return {
      id: summary.id,
      createdAt: summary.createdAt,
      updatedAt: summary.updatedAt,
      stage: summary.stage as IncidentStage,
      significant: summary.significant,
      recurring: summary.recurring,
      causeTag: summary.causeTag as CauseTag,
      details: {
        initial: {
          title: summary.title,
          summary: summary.summary,
          detectedAt: summary.createdAt, // Fallback
          suspectedIllegal: undefined,
          possibleCrossBorder: undefined
        }
      },
      attachments: []
    };
  }
}

// Export singleton instance
export const incidentsStore = new IncidentsStore();
