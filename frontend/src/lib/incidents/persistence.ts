import { IncidentRecord } from './schema';

const STORAGE_KEY = 'cybercare_new_incidents';

export function loadIncidents(): IncidentRecord[] {
  try {
    const stored = localStorage.getItem(STORAGE_KEY);
    return stored ? JSON.parse(stored) : [];
  } catch (error) {
    console.warn('Failed to load incidents from localStorage:', error);
    return [];
  }
}

export function saveIncidents(incidents: IncidentRecord[]): void {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(incidents));
  } catch (error) {
    console.error('Failed to save incidents to localStorage:', error);
  }
}