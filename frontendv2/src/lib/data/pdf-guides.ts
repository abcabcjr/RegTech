// PDF Guide mapping system for compliance templates
// Maps template IDs to their corresponding PDF guides

export interface PdfGuide {
  id: string;
  title: string;
  description: string;
  url: string;
  sections: string[];
  tips: string[];
  file_size?: string;
  last_updated?: string;
}

// PDF Guide mappings - add new guides here
export const pdfGuides: Record<string, PdfGuide> = {
  "risk-assessment": {
    id: "risk-assessment",
    title: "Risk Assessment Implementation Guide",
    description: "Complete step-by-step guide for conducting a cybersecurity risk assessment, including templates, checklists, and compliance requirements.",
    url: "/assets/templateGuides/risk-assessment-guide.pdf",
    sections: [
      "Asset inventory and classification",
      "Threat identification and analysis", 
      "Vulnerability assessment methodology",
      "Risk calculation and prioritization",
      "Mitigation strategy development",
      "Documentation and reporting templates",
      "Compliance verification checklist"
    ],
    tips: [
      "Include all IT assets, not just servers and workstations",
      "Use industry-standard risk rating scales (1-5 or High/Medium/Low)",
      "Document both likelihood and impact for each identified risk",
      "Get management approval for risk acceptance decisions",
      "Update the assessment annually or after major changes"
    ],
    file_size: "2.3 MB",
    last_updated: "2024-01-15"
  },
  
  "security-policy": {
    id: "security-policy", 
    title: "Cybersecurity Policy Development Guide",
    description: "Comprehensive guide for creating and implementing cybersecurity policies that meet regulatory requirements and industry best practices.",
    url: "/assets/templateGuides/security-policy-guide.pdf",
    sections: [
      "Policy framework and structure",
      "Key policy components and sections",
      "Legal and regulatory requirements",
      "Implementation and communication strategies",
      "Policy review and update procedures",
      "Template policies and examples",
      "Employee training and awareness"
    ],
    tips: [
      "Keep policies clear and understandable for all employees",
      "Include specific procedures, not just high-level statements",
      "Regularly review and update policies based on new threats",
      "Ensure management approval and support",
      "Provide training on policy requirements"
    ],
    file_size: "1.8 MB",
    last_updated: "2024-01-10"
  },

  "mfa-privileged": {
    id: "mfa-privileged",
    title: "Multi-Factor Authentication Implementation Guide", 
    description: "Detailed guide for implementing MFA for privileged accounts, including technology selection, deployment strategies, and user training.",
    url: "/assets/templateGuides/mfa-implementation-guide.pdf",
    sections: [
      "MFA technology options and comparison",
      "Privileged account identification",
      "Deployment planning and timeline",
      "User training and change management",
      "Technical implementation steps",
      "Testing and validation procedures",
      "Ongoing monitoring and maintenance"
    ],
    tips: [
      "Start with the most critical accounts first",
      "Provide multiple authentication methods for user convenience",
      "Test thoroughly before full deployment",
      "Have backup authentication methods available",
      "Monitor for failed authentication attempts"
    ],
    file_size: "1.5 MB",
    last_updated: "2024-01-12"
  },

  "access-review": {
    id: "access-review",
    title: "Access Review Process Guide",
    description: "Complete guide for establishing regular access reviews, including procedures, tools, and compliance requirements.",
    url: "/assets/templateGuides/access-review-guide.pdf", 
    sections: [
      "Access review framework and methodology",
      "User access inventory and classification",
      "Review procedures and responsibilities",
      "Automation tools and techniques",
      "Exception handling and approval processes",
      "Documentation and reporting requirements",
      "Compliance verification and auditing"
    ],
    tips: [
      "Automate where possible to reduce manual effort",
      "Set clear review schedules and deadlines",
      "Document all access decisions and justifications",
      "Include both technical and business reviewers",
      "Track and report on review completion rates"
    ],
    file_size: "1.2 MB",
    last_updated: "2024-01-08"
  }
};

/**
 * Get PDF guide for a specific template ID
 */
export function getPdfGuide(templateId: string): PdfGuide | null {
  return pdfGuides[templateId] || null;
}

/**
 * Get all available PDF guides
 */
export function getAllPdfGuides(): PdfGuide[] {
  return Object.values(pdfGuides);
}

/**
 * Check if a PDF guide exists for a template
 */
export function hasPdfGuide(templateId: string): boolean {
  return templateId in pdfGuides;
}
