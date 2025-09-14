// Import the JSON data directly
import checklistTemplatesFull from '../../../../backendnew/checklist_templates_full.json';
import type { RawTemplatesData, TemplatesData, Guide } from './types';
import { convertRawInfoToGuide } from './mapper';

/**
 * Load raw templates data from the JSON file
 */
export function loadRawTemplatesData(): RawTemplatesData {
  return checklistTemplatesFull as RawTemplatesData;
}

/**
 * Convert raw JSON templates to enhanced format with Guide data
 */
export function convertRawTemplatesToEnhanced(rawData: RawTemplatesData): TemplatesData {
  const enhancedTemplates = rawData.templates.map(rawTemplate => {
    const guide = convertRawInfoToGuide(rawTemplate);
    
    return {
      id: rawTemplate.id,
      title: rawTemplate.title,
      description: rawTemplate.description,
      category: rawTemplate.category,
      required: rawTemplate.required,
      scope: rawTemplate.scope,
      recommendation: rawTemplate.recommendation,
      help_text: rawTemplate.help_text,
      why_matters: rawTemplate.why_matters,
      kind: rawTemplate.kind,
      read_only: rawTemplate.read_only,
      script_controlled: rawTemplate.script_controlled,
      guide: guide
    };
  });

  return {
    templates: enhancedTemplates
  };
}

/**
 * Load templates data from JSON and convert to enhanced format
 */
export async function loadTemplatesData(): Promise<TemplatesData> {
  try {
    const rawData = loadRawTemplatesData();
    return convertRawTemplatesToEnhanced(rawData);
  } catch (error) {
    console.error('Failed to load templates data from JSON:', error);
    throw error;
  }
}
