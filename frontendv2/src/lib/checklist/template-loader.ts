import type { ChecklistSection, ChecklistItem, InfoBlock } from '../types';

// Interface matching the JSON template structure
interface JsonTemplate {
  id: string;
  title: string;
  description: string;
  category: string;
  required: boolean;
  scope: 'global' | 'asset';
  recommendation: string;
  help_text: string;
  why_matters: string;
  kind: 'manual' | 'auto';
  read_only: boolean;
  script_controlled?: boolean;
  info: {
    what_it_means: string;
    why_it_matters: string;
    law_refs: string[];
    priority?: 'must' | 'should';
    resources?: Array<{ title: string; url: string }>;
    non_technical_steps?: string[];
    scope_caveats?: string;
    acceptance_summary?: string;
    faq?: Array<{ q: string; a: string }>;
  };
}

interface JsonTemplateFile {
  templates: JsonTemplate[];
}

// Category mapping for organizing sections
const CATEGORY_SECTIONS: Record<string, { title: string; description: string }> = {
  'Governance & Risk Management': {
    title: 'Governance & Risk Management',
    description: 'Organizational cybersecurity governance and risk assessment'
  },
  'Identity & Access Management': {
    title: 'Identity & Access Management',
    description: 'User access controls and multi-factor authentication'
  },
  'Logging & Monitoring': {
    title: 'Logging & Monitoring',
    description: 'Security event logging and monitoring systems'
  },
  'Backup & Disaster Recovery': {
    title: 'Backup & Disaster Recovery',
    description: 'Data backup and recovery capabilities'
  },
  'Email Security': {
    title: 'Email Security',
    description: 'Email authentication and security measures'
  },
  'Network Security': {
    title: 'Network Security',
    description: 'Network infrastructure security and encryption'
  },
  'Web Security': {
    title: 'Web Security',
    description: 'Website security headers and configurations'
  },
  'Vulnerability Management': {
    title: 'Vulnerability Management',
    description: 'Vulnerability scanning and patch management'
  },
  'Audits & Certifications': {
    title: 'Audits & Certifications',
    description: 'External security audits and certifications'
  },
  'Awareness & Training': {
    title: 'Awareness & Training',
    description: 'Cybersecurity awareness and training programs'
  },
  'Data Protection': {
    title: 'Data Protection',
    description: 'Data protection and privacy measures'
  }
};

function convertJsonTemplateToChecklistItem(template: JsonTemplate): ChecklistItem {
  const info: InfoBlock = {
    whatItMeans: template.info.what_it_means,
    whyItMatters: template.info.why_it_matters,
    lawRefs: template.info.law_refs,
    priority: template.info.priority,
    resources: template.info.resources,
    guide: {
      non_technical_steps: template.info.non_technical_steps,
      scope_caveats: template.info.scope_caveats || null,
      acceptance_summary: template.info.acceptance_summary || null,
      faq: template.info.faq
    }
  };

  return {
    id: template.id,
    title: template.title,
    description: template.description,
    helpText: template.help_text,
    whyMatters: template.why_matters,
    category: template.category.toLowerCase().replace(/\s+/g, '_'),
    required: template.required,
    status: 'no' as const,
    recommendation: template.recommendation,
    kind: template.kind,
    readOnly: template.read_only || template.script_controlled || false,
    info,
    coveredAssets: template.scope === 'asset' ? [] : undefined,
    attachments: []
  };
}

function groupTemplatesByCategory(templates: JsonTemplate[]): ChecklistSection[] {
  const categoryGroups: Record<string, ChecklistItem[]> = {};
  
  // Group templates by category
  templates.forEach(template => {
    const category = template.category;
    if (!categoryGroups[category]) {
      categoryGroups[category] = [];
    }
    categoryGroups[category].push(convertJsonTemplateToChecklistItem(template));
  });

  // Convert to ChecklistSection array
  return Object.entries(categoryGroups).map(([categoryName, items]) => {
    const sectionConfig = CATEGORY_SECTIONS[categoryName] || {
      title: categoryName,
      description: `${categoryName} requirements and controls`
    };

    return {
      id: categoryName.toLowerCase().replace(/\s+/g, '_').replace(/[^a-z0-9_]/g, ''),
      title: sectionConfig.title,
      description: sectionConfig.description,
      items: items.sort((a, b) => {
        // Sort required items first, then by title
        if (a.required !== b.required) {
          return a.required ? -1 : 1;
        }
        return a.title.localeCompare(b.title);
      })
    };
  }).sort((a, b) => {
    // Sort sections in logical order
    const order = [
      'governance_risk_management',
      'identity_access_management', 
      'logging_monitoring',
      'backup_disaster_recovery',
      'email_security',
      'network_security',
      'web_security',
      'vulnerability_management',
      'audits_certifications',
      'awareness_training',
      'data_protection'
    ];
    
    const indexA = order.indexOf(a.id);
    const indexB = order.indexOf(b.id);
    
    if (indexA === -1 && indexB === -1) return a.title.localeCompare(b.title);
    if (indexA === -1) return 1;
    if (indexB === -1) return -1;
    
    return indexA - indexB;
  });
}

/**
 * Load and parse checklist templates from JSON file
 */
export async function loadChecklistTemplates(): Promise<ChecklistSection[]> {
  try {
    // Try to load from backend first
    const backendResponse = await fetch('/api/checklist/templates');
    if (backendResponse.ok) {
      const data: JsonTemplateFile = await backendResponse.json();
      return groupTemplatesByCategory(data.templates);
    }
  } catch (error) {
    console.warn('Failed to load templates from backend:', error);
  }

  try {
    // Fallback to static file
    const response = await fetch('/checklist_templates_full.json');
    if (!response.ok) {
      throw new Error(`Failed to load templates: ${response.status}`);
    }
    
    const data: JsonTemplateFile = await response.json();
    return groupTemplatesByCategory(data.templates);
  } catch (error) {
    console.error('Failed to load checklist templates:', error);
    
    // Return minimal fallback structure
    return [{
      id: 'error',
      title: 'Configuration Error',
      description: 'Failed to load checklist templates',
      items: [{
        id: 'template-error',
        title: 'Template Loading Error',
        description: 'Could not load checklist templates from server',
        helpText: 'Please check server configuration and try again',
        whyMatters: 'Templates are required for compliance assessment',
        category: 'error',
        required: true,
        status: 'no',
        kind: 'manual',
        readOnly: true,
        recommendation: 'Contact system administrator',
        attachments: []
      }]
    }];
  }
}

/**
 * Get template by ID
 */
export async function getTemplateById(id: string): Promise<ChecklistItem | null> {
  const sections = await loadChecklistTemplates();
  
  for (const section of sections) {
    const item = section.items.find(item => item.id === id);
    if (item) return item;
  }
  
  return null;
}

/**
 * Get all templates for a specific category
 */
export async function getTemplatesByCategory(category: string): Promise<ChecklistItem[]> {
  const sections = await loadChecklistTemplates();
  const section = sections.find(s => s.id === category || s.title === category);
  return section?.items || [];
}

/**
 * Filter templates by scope (global vs asset-specific)
 */
export function filterTemplatesByScope(items: ChecklistItem[], scope: 'global' | 'asset'): ChecklistItem[] {
  return items.filter(item => {
    if (scope === 'asset') {
      return item.coveredAssets !== undefined;
    } else {
      return item.coveredAssets === undefined;
    }
  });
}

/**
 * Get template statistics
 */
export function getTemplateStats(sections: ChecklistSection[]) {
  let total = 0;
  let required = 0;
  let manual = 0;
  let automated = 0;
  
  sections.forEach(section => {
    section.items.forEach(item => {
      total++;
      if (item.required) required++;
      if (item.kind === 'manual') manual++;
      if (item.kind === 'auto') automated++;
    });
  });
  
  return {
    total,
    required,
    optional: total - required,
    manual,
    automated
  };
}