import type { ChecklistState } from './types';
import { defaultChecklistSections } from './checklist-data';

const STORAGE_KEY = 'cybercare-checklist-state';

export function loadChecklistState(): ChecklistState {
  try {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (stored) {
      const parsed = JSON.parse(stored);
      // Ensure we have all required fields
      return {
        sections: parsed.sections || defaultChecklistSections,
        lastUpdated: parsed.lastUpdated || new Date().toISOString(),
        complianceScore: parsed.complianceScore || 0
      };
    }
  } catch (error) {
    console.error('Failed to load checklist state from localStorage:', error);
  }

  // Return default state if loading fails
  return {
    sections: defaultChecklistSections,
    lastUpdated: new Date().toISOString(),
    complianceScore: 0
  };
}

export function saveChecklistState(state: ChecklistState): void {
  try {
    // Calculate compliance score
    const totalRequired = state.sections.reduce((acc, section) => 
      acc + section.items.filter(item => item.required).length, 0
    );
    const completedRequired = state.sections.reduce((acc, section) => 
      acc + section.items.filter(item => item.required && item.status === "yes").length, 0
    );
    
    const complianceScore = totalRequired > 0 ? Math.round((completedRequired / totalRequired) * 100) : 0;
    
    const stateToSave = {
      ...state,
      complianceScore,
      lastUpdated: new Date().toISOString()
    };
    
    localStorage.setItem(STORAGE_KEY, JSON.stringify(stateToSave));
  } catch (error) {
    console.error('Failed to save checklist state to localStorage:', error);
  }
}

export function clearChecklistState(): void {
  try {
    localStorage.removeItem(STORAGE_KEY);
  } catch (error) {
    console.error('Failed to clear checklist state from localStorage:', error);
  }
}
