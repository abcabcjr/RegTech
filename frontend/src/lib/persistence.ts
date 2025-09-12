import { ChecklistState, IncidentRecord as OldIncidentRecord, OrganizationProfile } from './types';
import { defaultChecklistSections } from './checklist-data';

const STORAGE_KEYS = {
  CHECKLIST: 'cybercare_checklist',
  INCIDENTS: 'cybercare_incidents',
  NEW_INCIDENTS: 'cybercare_new_incidents',
  ORGANIZATION: 'cybercare_organization'
};

// Checklist State Management
export function loadChecklistState(): ChecklistState {
  try {
    const stored = localStorage.getItem(STORAGE_KEYS.CHECKLIST);
    if (stored) {
      const parsed = JSON.parse(stored);
      return {
        ...parsed,
        complianceScore: calculateComplianceScore(parsed.sections)
      };
    }
  } catch (error) {
    console.warn('Failed to load checklist state from localStorage:', error);
  }
  
  return {
    sections: defaultChecklistSections,
    lastUpdated: new Date().toISOString(),
    complianceScore: 0
  };
}

export function saveChecklistState(state: ChecklistState): void {
  try {
    const stateToSave = {
      ...state,
      complianceScore: calculateComplianceScore(state.sections),
      lastUpdated: new Date().toISOString()
    };
    localStorage.setItem(STORAGE_KEYS.CHECKLIST, JSON.stringify(stateToSave));
  } catch (error) {
    console.error('Failed to save checklist state to localStorage:', error);
  }
}

export function calculateComplianceScore(sections: any[]): number {
  let totalRequired = 0;
  let compliantRequired = 0;
  
  sections.forEach(section => {
    section.items.forEach((item: any) => {
      if (item.required) {
        totalRequired++;
        if (item.status === 'yes') {
          compliantRequired++;
        }
      }
    });
  });
  
  return totalRequired > 0 ? Math.round((compliantRequired / totalRequired) * 100) : 0;
}

// Legacy Incident Management (old format)
export function loadIncidents(): OldIncidentRecord[] {
  try {
    const stored = localStorage.getItem(STORAGE_KEYS.INCIDENTS);
    return stored ? JSON.parse(stored) : [];
  } catch (error) {
    console.warn('Failed to load incidents from localStorage:', error);
    return [];
  }
}

export function saveIncidents(incidents: OldIncidentRecord[]): void {
  try {
    localStorage.setItem(STORAGE_KEYS.INCIDENTS, JSON.stringify(incidents));
  } catch (error) {
    console.error('Failed to save incidents to localStorage:', error);
  }
}

export function saveIncident(incident: OldIncidentRecord): void {
  const incidents = loadIncidents();
  const existingIndex = incidents.findIndex(i => i.id === incident.id);
  
  if (existingIndex >= 0) {
    incidents[existingIndex] = { ...incident, updatedAt: new Date().toISOString() };
  } else {
    incidents.push(incident);
  }
  
  saveIncidents(incidents);
}

// Organization Profile
export function loadOrganizationProfile(): OrganizationProfile {
  try {
    const stored = localStorage.getItem(STORAGE_KEYS.ORGANIZATION);
    if (stored) {
      return JSON.parse(stored);
    }
  } catch (error) {
    console.warn('Failed to load organization profile from localStorage:', error);
  }
  
  return {
    name: '',
    sector: '',
    turnoverPrevYear: 0,
    lastUpdated: new Date().toISOString()
  };
}

export function saveOrganizationProfile(profile: OrganizationProfile): void {
  try {
    const profileToSave = {
      ...profile,
      lastUpdated: new Date().toISOString()
    };
    localStorage.setItem(STORAGE_KEYS.ORGANIZATION, JSON.stringify(profileToSave));
  } catch (error) {
    console.error('Failed to save organization profile to localStorage:', error);
  }
}

// Reset all data
export function resetAllData(): void {
  try {
    Object.values(STORAGE_KEYS).forEach(key => {
      localStorage.removeItem(key);
    });
  } catch (error) {
    console.error('Failed to reset data:', error);
  }
}