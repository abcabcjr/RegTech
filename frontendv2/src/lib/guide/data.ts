// Import the templates data from the backend JSON file
import type { TemplatesData, Guide } from './types';
import { mockTemplatesData } from './mock-data';

// Import the JSON data directly
// Note: In a real implementation, this could be fetched from an API
// For now, we'll use mock data that simulates the updated JSON structure
let templatesData: TemplatesData | null = null;

/**
 * Load the templates data from the JSON file
 * This is a placeholder implementation that would normally fetch from an API
 */
async function loadTemplatesData(): Promise<TemplatesData> {
  if (templatesData) {
    return templatesData;
  }

  try {
    // In a real implementation, this would be an API call
    // For now, we'll use mock data
    // const response = await fetch('/api/checklist/templates');
    // if (!response.ok) {
    //   throw new Error('Failed to load templates data');
    // }
    // templatesData = await response.json();
    
    // Using mock data for now
    templatesData = mockTemplatesData;
    return templatesData;
  } catch (error) {
    console.error('Failed to load templates data:', error);
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
