export type IncidentStage = 'initial' | 'update' | 'final';

export type CauseTag = 'phishing' | 'vuln_exploit' | 'misconfig' | 'malware' | 'other';

export interface InitialDetails {
  summary: string;
  detectedAt: string;
  suspectedIllegal?: boolean;
  possibleCrossBorder?: boolean;
}

export interface UpdateDetails {
  gravity?: string;
  impact?: string;
  iocs?: string[];
  corrections?: string;
}

export interface FinalDetails {
  rootCause?: string;
  gravity?: string;
  impact?: string;
  mitigations?: string;
  crossBorderDesc?: string;
  lessons?: string;
}

export interface Attachment {
  name: string;
  note?: string;
}

export interface IncidentRecord {
  id: string;
  createdAt: string;
  updatedAt: string;
  stage: IncidentStage;
  significant: boolean;
  recurring: boolean;
  causeTag: CauseTag;
  usersAffected?: number;
  downtimeMinutes?: number;
  financialImpactPct?: number;
  sectorPreset?: string;
  details: {
    initial?: InitialDetails;
    update?: UpdateDetails;
    final?: FinalDetails;
  };
  attachments?: Attachment[];
}

export const CAUSE_TAGS: { value: CauseTag; label: string }[] = [
  { value: 'phishing', label: 'Phishing Attack' },
  { value: 'vuln_exploit', label: 'Vulnerability Exploitation' },
  { value: 'misconfig', label: 'Misconfiguration' },
  { value: 'malware', label: 'Malware' },
  { value: 'other', label: 'Other' }
];

export const INCIDENT_STAGES: { value: IncidentStage; label: string; description: string }[] = [
  { value: 'initial', label: 'Initial Report', description: 'Basic incident details' },
  { value: 'update', label: 'Update Report', description: 'Impact and scope analysis' },
  { value: 'final', label: 'Final Report', description: 'Root cause and mitigation' }
];

export const GRAVITY_LEVELS = [
  { value: 'low', label: 'Low' },
  { value: 'medium', label: 'Medium' },
  { value: 'high', label: 'High' },
  { value: 'critical', label: 'Critical' }
];
