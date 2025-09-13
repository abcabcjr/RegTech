// Mapper to convert Guide data to InfoPanel format

import type { Guide, InfoBlock, GuideResource, GuideImage, GuideVideo, GuideSchema, EvidenceTemplate } from './types';

export interface InfoPanelData {
  overview: {
    what_it_means: string;
    why_it_matters: string;
  };
  risks: {
    attack_vectors: string[];
    potential_impact: string[];
  };
  guide: {
    non_technical_steps: string[];
  };
  media: {
    images: GuideImage[];
    videos: GuideVideo[];
    schemas: GuideSchema[];
  };
  legal: {
    requirement_summary: string;
    article_refs: string[];
    priority: "must" | "should";
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
      priority: "should"
    },
    resources: []
  };
}
