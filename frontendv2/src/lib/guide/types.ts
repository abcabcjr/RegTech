// Types for the comprehensive guide system

export interface GuideResource {
  title: string;
  url: string;
  type?: "link" | "video" | "document" | "image" | "schema";
  description?: string;
}

export interface GuideLaw {
  requirement_summary: string;
  article_refs: string[];
}

export interface Guide {
  what_it_is: string;
  why_it_matters: string;
  attack_vectors: string[];
  potential_impact: string[];
  non_technical_steps: string[];
  law: GuideLaw;
  resources: GuideResource[];
  priority: "must" | "should";
  // Rich content support
  images?: GuideImage[];
  videos?: GuideVideo[];
  schemas?: GuideSchema[];
  // Evidence template support
  evidence_template?: EvidenceTemplate;
  // Additional guide information from JSON
  scope_caveats?: string | null;
  acceptance_summary?: string | null;
  faq?: Array<{q: string; a: string}>;
  // Risks information from JSON
  risks?: {
    attack_vectors?: string[];
    potential_impact?: string[];
  };
  // Legal information from JSON
  legal?: {
    requirement_summary?: string;
    article_refs?: string[];
    quotes?: Array<{text: string; source: string}>;
    priority?: string;
  };
}

export interface EvidenceTemplate {
  title: string;
  description: string;
  template_type: "pdf" | "document" | "checklist" | "form";
  url?: string; // URL to PDF or document template
  examples: string[]; // Text examples of what evidence should include
  required_fields: string[]; // Fields that must be documented
  sample_entries?: string[]; // Sample text entries
}

export interface GuideImage {
  url: string;
  alt: string;
  caption?: string;
  width?: number;
  height?: number;
}

export interface GuideVideo {
  url: string;
  title: string;
  description?: string;
  thumbnail?: string;
  duration?: string;
  platform?: "youtube" | "vimeo" | "direct";
}

export interface GuideSchema {
  title: string;
  description?: string;
  type: "network_diagram" | "flow_chart" | "architecture" | "process";
  image_url?: string;
  interactive_url?: string;
}

export interface ChecklistTemplate {
  id: string;
  title: string;
  description: string;
  category: string;
  required: boolean;
  scope: string;
  recommendation: string;
  help_text: string;
  why_matters: string;
  kind: string;
  read_only: boolean;
  script_controlled?: boolean;
  guide: Guide;
}

export interface TemplatesData {
  templates: ChecklistTemplate[];
}

// Legacy info structure for backward compatibility
export interface InfoBlock {
  what_it_means: string;
  why_it_matters: string;
  law_refs: string[];
  priority: string;
  resources: GuideResource[];
}
