// Core types for CyberCare compliance system
export interface InfoBlock {
  whatItMeans: string;
  whyItMatters: string;
  lawRefs: string[];        // e.g., ["Art. 11", "NU-49-MDED-2025 §…"]
  priority?: 'must' | 'should';
  resources?: { title: string; url: string }[];
}

export interface ChecklistItem {
  id: string;
  title: string;
  description: string;
  helpText: string;
  whyMatters: string;
  category: string;
  required: boolean;
  status: "yes" | "no" | "na";
  justification?: string;
  evidence?: string;
  lastUpdated?: string;
  recommendation?: string;
  kind: 'manual' | 'auto';
  readOnly?: boolean;
  info?: InfoBlock;
}

export interface ChecklistSection {
  id: string;
  title: string;
  description: string;
  items: ChecklistItem[];
}

export interface ChecklistState {
  sections: ChecklistSection[];
  lastUpdated: string;
  complianceScore: number;
}

export type IncidentStage = "initial" | "update" | "final";

export interface IncidentRecord {
  id: string;
  title: string;
  stage: IncidentStage;
  status: "draft" | "submitted";
  createdAt: string;
  updatedAt: string;
  
  // Initial stage
  summary: string;
  detectedAt: string;
  reportedBy: string;
  
  // Update stage
  significant: boolean;
  recurring: boolean;
  causeTag: string;
  usersAffected: number;
  downtimeMinutes: number;
  financialImpactPct: number;
  systemsAffected: string[];
  iocs: string;
  interimActions: string;
  
  // Final stage
  rootCause: string;
  gravity: "low" | "medium" | "high" | "critical";
  mitigations: string;
  crossBorderEffects: boolean;
  lessonsLearned: string;
  
  attachments: string[];
}

export interface Finding {
  id: string;
  category: "ports" | "tls" | "headers" | "email" | "cve" | "iam" | "backup" | "logging";
  severity: "info" | "low" | "medium" | "high";
  title: string;
  summary: string;
  evidence?: string;
  recommendation?: string;
}

export interface OrganizationProfile {
  name: string;
  sector: string;
  turnoverPrevYear: number;
  lastUpdated: string;
}
