import type { 
  IncidentRecord, 
  IncidentStage, 
  CauseTag, 
  InitialDetails, 
  UpdateDetails, 
  FinalDetails 
} from '$lib/types/incidents';

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
  loadIncidents() {
    if (this.loading) return;
    this.loading = true;
    this.error = null;

    try {
      const stored = localStorage.getItem('cybercare_incidents');
      const data = stored ? JSON.parse(stored) : [];
      // Deep copy to avoid reference issues
      this.incidents = JSON.parse(JSON.stringify(data));
    } catch (error) {
      console.error('Failed to load incidents:', error);
      this.error = error instanceof Error ? error.message : 'Failed to load incidents';
      this.incidents = [];
    } finally {
      this.loading = false;
    }
  }

  private saveIncidents() {
    try {
      localStorage.setItem('cybercare_incidents', JSON.stringify(this.incidents));
    } catch (error) {
      console.error('Failed to save incidents:', error);
      this.error = 'Failed to save incidents';
    }
  }

  createIncident(initialData: Partial<IncidentRecord> = {}): IncidentRecord {
    const newIncident: IncidentRecord = {
      id: crypto.randomUUID(),
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      stage: 'initial',
      significant: false,
      recurring: false,
      causeTag: 'other',
      details: {},
      attachments: [],
      ...initialData
    };

    this.incidents = [...this.incidents, newIncident];
    this.saveIncidents();
    return newIncident;
  }

  updateIncident(id: string, updates: Partial<IncidentRecord>) {
    const index = this.incidents.findIndex(incident => incident.id === id);
    if (index === -1) return;

    const updatedIncident = {
      ...this.incidents[index],
      ...updates,
      updatedAt: new Date().toISOString()
    };

    this.incidents = [
      ...this.incidents.slice(0, index),
      updatedIncident,
      ...this.incidents.slice(index + 1)
    ];

    // Update selected incident if it's the one being updated
    if (this.selectedIncident?.id === id) {
      this.selectedIncident = updatedIncident;
    }

    this.saveIncidents();
  }

  setStageData(id: string, stage: IncidentStage, data: InitialDetails | UpdateDetails | FinalDetails) {
    const incident = this.incidents.find(i => i.id === id);
    if (!incident) return;

    const updatedIncident = {
      ...incident,
      stage,
      details: {
        ...incident.details,
        [stage]: data
      },
      updatedAt: new Date().toISOString()
    };

    this.updateIncident(id, updatedIncident);
  }

  deleteIncident(id: string) {
    this.incidents = this.incidents.filter(incident => incident.id !== id);
    
    // Clear selection if deleted incident was selected
    if (this.selectedIncident?.id === id) {
      this.selectedIncident = null;
    }

    this.saveIncidents();
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
    return incident.details.initial?.summary?.substring(0, 50) || 'Untitled Incident';
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
}

// Export singleton instance
export const incidentsStore = new IncidentsStore();
