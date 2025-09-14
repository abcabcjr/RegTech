// Import the templates data from the backend JSON file
import type { TemplatesData, Guide } from './types';
import { mockTemplatesData } from './mock-data';
import { loadTemplatesData as loadFromJson } from './json-loader';

// Cache for loaded data
let templatesData: TemplatesData | null = null;

/**
 * Load the templates data from the JSON file
 * This loads the actual data from checklist_templates_full.json
 */
async function loadTemplatesData(): Promise<TemplatesData> {
  if (templatesData) {
    return templatesData;
  }

  try {
    // Load from the actual JSON file
    templatesData = await loadFromJson();
    return templatesData;
  } catch (error) {
    console.error('Failed to load templates data from JSON:', error);
    // Fallback to mock data
    templatesData = mockTemplatesData;
    return templatesData;
  }
}

/**
 * Get guide data by checklist item ID
 * This is the main helper function for components
 */
export async function getGuideById(id: string): Promise<Guide | null> {
  try {
    const data = await loadTemplatesData();
    const template = data.templates.find(t => t.id === id);
    return template?.guide || null;
  } catch (error) {
    console.error(`Failed to get guide for ID ${id}:`, error);
    return null;
  }
}

/**
 * Synchronous version that uses pre-loaded data
 * For use in components where data is already available
 */
export function getGuideByIdSync(id: string, templatesData: TemplatesData): Guide | null {
  const template = templatesData.templates.find(t => t.id === id);
  return template?.guide || null;
}

/**
 * Get all available templates
 */
export async function getAllTemplates(): Promise<TemplatesData> {
  return loadTemplatesData();
}
