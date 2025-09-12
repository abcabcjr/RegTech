import { z } from "zod";

export const IncidentStageSchema = z.enum(["initial", "update", "final"]);
export type IncidentStage = z.infer<typeof IncidentStageSchema>;

export const CauseTagSchema = z.enum(["phishing", "vuln_exploit", "misconfig", "malware", "other"]);
export type CauseTag = z.infer<typeof CauseTagSchema>;

export const InitialDetailsSchema = z.object({
  summary: z.string().min(1, "Summary is required"),
  detectedAt: z.string().min(1, "Detection time is required"),
  suspectedIllegal: z.boolean().optional(),
  possibleCrossBorder: z.boolean().optional(),
});

export const UpdateDetailsSchema = z.object({
  gravity: z.string().optional(),
  impact: z.string().optional(),
  iocs: z.array(z.string()).optional(),
  corrections: z.string().optional(),
});

export const FinalDetailsSchema = z.object({
  rootCause: z.string().optional(),
  gravity: z.string().optional(),
  impact: z.string().optional(),
  mitigations: z.string().optional(),
  crossBorderDesc: z.string().optional(),
  lessons: z.string().optional(),
});

export const AttachmentSchema = z.object({
  name: z.string(),
  note: z.string().optional(),
});

export const IncidentRecordSchema = z.object({
  id: z.string(),
  createdAt: z.string(),
  updatedAt: z.string(),
  stage: IncidentStageSchema,
  significant: z.boolean().default(false),
  recurring: z.boolean().default(false),
  causeTag: CauseTagSchema,
  usersAffected: z.number().optional(),
  downtimeMinutes: z.number().optional(),
  financialImpactPct: z.number().optional(),
  sectorPreset: z.string().optional(),
  details: z.object({
    initial: InitialDetailsSchema.optional(),
    update: UpdateDetailsSchema.optional(),
    final: FinalDetailsSchema.optional(),
  }),
  attachments: z.array(AttachmentSchema).optional(),
});

export type IncidentRecord = z.infer<typeof IncidentRecordSchema>;
export type InitialDetails = z.infer<typeof InitialDetailsSchema>;
export type UpdateDetails = z.infer<typeof UpdateDetailsSchema>;
export type FinalDetails = z.infer<typeof FinalDetailsSchema>;
export type Attachment = z.infer<typeof AttachmentSchema>;