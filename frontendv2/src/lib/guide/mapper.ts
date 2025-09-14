// Mapper to convert Guide data to InfoPanel format

import type { Guide, InfoBlock, GuideResource, GuideImage, GuideVideo, GuideSchema, EvidenceTemplate } from './types';

export interface InfoPanelData {
  overview: {
    what_it_means: string;
    why_it_matters: string;
  };
  risks?: {
    attack_vectors?: string[];
    potential_impact?: string[];
  };
  guide?: {
    non_technical_steps?: string[];
    scope_caveats?: string | null;
    acceptance_summary?: string | null;
    faq?: Array<{q: string; a: string}>;
  };
  media: {
    images: GuideImage[];
    videos: GuideVideo[];
    schemas: GuideSchema[];
  };
  legal?: {
    requirement_summary?: string;
    article_refs?: string[];
    priority?: string;
    priority_number?: number;
  };
  resources: GuideResource[];
  evidence_template?: EvidenceTemplate;
  pdf_guide?: {
    id: string;
    title: string;
    description: string;
    url: string;
    sections: string[];
    tips: string[];
    file_size?: string;
    last_updated?: string;
  };
}

/**
 * Map Guide data to InfoPanel structure
 */
export function mapGuideToInfoPanel(guide: Guide | null): InfoPanelData | null {
  if (!guide) {
    return null;
  }

  return {
    overview: {
      what_it_means: guide.what_it_is,
      why_it_matters: guide.why_it_matters
    },
    risks: {
      attack_vectors: guide.attack_vectors,
      potential_impact: guide.potential_impact
    },
    guide: {
      non_technical_steps: guide.non_technical_steps
    },
    media: {
      images: guide.images || [],
      videos: guide.videos || [],
      schemas: guide.schemas || []
    },
    legal: {
      requirement_summary: guide.law.requirement_summary,
      article_refs: guide.law.article_refs,
      priority: guide.priority
    },
    resources: guide.resources,
    evidence_template: guide.evidence_template
  };
}

/**
 * Map Guide data to legacy InfoBlock format for backward compatibility
 * This can be used during the transition period
 */
export function mapGuideToInfoBlock(guide: Guide | null): InfoBlock | null {
  if (!guide) {
    return null;
  }

  return {
    what_it_means: guide.what_it_is,
    why_it_matters: guide.why_it_matters,
    law_refs: guide.law.article_refs,
    priority: guide.priority,
    resources: guide.resources
  };
}

/**
 * Convert raw JSON template info to Guide format
 * This function uses the data directly from the JSON file
 */
export function convertRawInfoToGuide(rawTemplate: any): Guide {
  const info = rawTemplate.info;
  
  return {
    what_it_is: info.what_it_means,
    why_it_matters: info.why_it_matters,
    attack_vectors: info.risks?.attack_vectors || [],
    potential_impact: info.risks?.potential_impact || [],
    non_technical_steps: info.guide?.non_technical_steps || [],
    law: {
      requirement_summary: info.legal?.requirement_summary || info.what_it_means,
      article_refs: info.law_refs || []
    },
    resources: info.resources || [],
    priority: info.priority as "critical" | "high" | "medium" | "low",
    priority_number: info.priority_number,
    // Additional guide information from JSON
    scope_caveats: info.guide?.scope_caveats || null,
    acceptance_summary: info.guide?.acceptance_summary || null,
    faq: info.guide?.faq || [],
    // Risks information from JSON
    risks: info.risks ? {
      attack_vectors: info.risks.attack_vectors || [],
      potential_impact: info.risks.potential_impact || []
    } : undefined,
    // Legal information from JSON
    legal: info.legal ? {
      requirement_summary: info.legal.requirement_summary || info.what_it_means,
      article_refs: info.legal.article_refs || info.law_refs || [],
      quotes: info.legal.quotes || [],
      priority: info.legal.priority || info.priority,
      priority_number: info.legal.priority_number || info.priority_number
    } : undefined
  };
}

/**
 * Map backend checklist item info to InfoPanel structure
 * This function handles both Guide objects and backend info objects
 */
export function mapBackendInfoToInfoPanel(backendInfo: any): InfoPanelData | null {
  if (!backendInfo) {
    return null;
  }

  // Debug logging
  console.log('mapBackendInfoToInfoPanel - backendInfo:', backendInfo);
  console.log('Risks from backend:', backendInfo.risks);
  console.log('Guide from backend:', backendInfo.guide);
  console.log('Legal from backend:', backendInfo.legal);

  // Check if this is a Guide object (has what_it_is instead of what_it_means)
  const isGuideObject = backendInfo.what_it_is !== undefined;
  
  const mapped: InfoPanelData = {
    overview: {
      what_it_means: isGuideObject ? backendInfo.what_it_is : (backendInfo.what_it_means || "—"),
      why_it_matters: backendInfo.why_it_matters || "—"
    },
    risks: {
      attack_vectors: backendInfo.risks?.attack_vectors || backendInfo.attack_vectors || [],
      potential_impact: backendInfo.risks?.potential_impact || backendInfo.potential_impact || []
    },
    guide: {
      non_technical_steps: backendInfo.guide?.non_technical_steps || backendInfo.non_technical_steps || [],
      scope_caveats: backendInfo.guide?.scope_caveats || backendInfo.scope_caveats || null,
      acceptance_summary: backendInfo.guide?.acceptance_summary || backendInfo.acceptance_summary || null,
      faq: backendInfo.guide?.faq || backendInfo.faq || []
    },
    media: {
      images: backendInfo.images || [],
      videos: backendInfo.videos || [],
      schemas: backendInfo.schemas || []
    },
    legal: {
      requirement_summary: backendInfo.legal?.requirement_summary || backendInfo.law?.requirement_summary || "—",
      article_refs: backendInfo.legal?.article_refs || backendInfo.law?.article_refs || [],
      priority: (backendInfo.legal?.priority || backendInfo.priority as "critical" | "high" | "medium" | "low") || "medium",
      priority_number: backendInfo.legal?.priority_number || backendInfo.priority_number
    },
    resources: backendInfo.resources || []
  };

  return mapped;
}

/**
 * Create placeholder InfoPanelData when guide is missing
 */
export function createPlaceholderInfoPanel(): InfoPanelData {
  return {
    overview: {
      what_it_means: "—",
      why_it_matters: "—"
    },
    risks: {
      attack_vectors: [],
      potential_impact: []
    },
    guide: {
      non_technical_steps: []
    },
    media: {
      images: [],
      videos: [],
      schemas: []
    },
    legal: {
      requirement_summary: "—",
      article_refs: [],
      priority: "medium",
      priority_number: 3
    },
    resources: []
  };
}
