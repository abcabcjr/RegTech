import { create } from 'zustand';
import { IncidentRecord, IncidentStage, CauseTag, InitialDetails, UpdateDetails, FinalDetails } from './schema';
import { loadIncidents, saveIncidents } from './persistence';

interface IncidentStore {
  incidents: IncidentRecord[];
  selectedIncident: IncidentRecord | null;
  
  // Actions
  loadIncidents: () => void;
  createIncident: (initialData: Partial<IncidentRecord>) => IncidentRecord;
  updateIncident: (id: string, updates: Partial<IncidentRecord>) => void;
  setStageData: (id: string, stage: IncidentStage, data: InitialDetails | UpdateDetails | FinalDetails) => void;
  deleteIncident: (id: string) => void;
  selectIncident: (incident: IncidentRecord | null) => void;
  exportIncidentJSON: (id: string) => void;
}

export const useIncidentStore = create<IncidentStore>((set, get) => ({
  incidents: [],
  selectedIncident: null,

  loadIncidents: () => {
    const incidents = loadIncidents();
    set({ incidents });
  },

  createIncident: (initialData) => {
    const newIncident: IncidentRecord = {
      id: crypto.randomUUID(),
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      stage: "initial",
      significant: false,
      recurring: false,
      causeTag: "other" as CauseTag,
      details: {},
      attachments: [],
      ...initialData,
    };

    const incidents = [...get().incidents, newIncident];
    set({ incidents });
    saveIncidents(incidents);
    
    return newIncident;
  },

  updateIncident: (id, updates) => {
    const incidents = get().incidents.map(incident =>
      incident.id === id
        ? { ...incident, ...updates, updatedAt: new Date().toISOString() }
        : incident
    );
    
    set({ 
      incidents,
      selectedIncident: get().selectedIncident?.id === id 
        ? { ...get().selectedIncident!, ...updates, updatedAt: new Date().toISOString() }
        : get().selectedIncident
    });
    saveIncidents(incidents);
  },

  setStageData: (id, stage, data) => {
    const incident = get().incidents.find(i => i.id === id);
    if (!incident) return;

    const updatedIncident = {
      ...incident,
      stage,
      details: {
        ...incident.details,
        [stage]: data,
      },
      updatedAt: new Date().toISOString(),
    };

    get().updateIncident(id, updatedIncident);
  },

  deleteIncident: (id) => {
    const incidents = get().incidents.filter(incident => incident.id !== id);
    set({ 
      incidents,
      selectedIncident: get().selectedIncident?.id === id ? null : get().selectedIncident
    });
    saveIncidents(incidents);
  },

  selectIncident: (incident) => {
    set({ selectedIncident: incident });
  },

  exportIncidentJSON: (id) => {
    const incident = get().incidents.find(i => i.id === id);
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
  },
}));