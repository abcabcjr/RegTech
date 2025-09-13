import type { ChecklistSection } from '../types';

export const manualChecklistSections: ChecklistSection[] = [
  {
    id: "governance",
    title: "Governance & Risk Management",
    description: "Organizational cybersecurity governance and risk assessment",
    items: [
      {
        id: "risk-assessment",
        title: "Risk Assessment Documentation",
        description: "Documented cybersecurity risk assessment for your organization",
        helpText: "Upload or reference your latest cybersecurity risk assessment document",
        whyMatters: "Required by law to identify and document cybersecurity risks to your business operations",
        category: "governance",
        required: true,
        status: "no",
        recommendation: "Conduct a formal cybersecurity risk assessment and document the findings",
        kind: "manual",
        readOnly: false,
        info: {
          whatItMeans: "A formal document that identifies, analyzes, and evaluates cybersecurity risks to your organization's information systems and data.",
          whyItMatters: "Required by Moldova's Cybersecurity Law to demonstrate proactive risk management and compliance with regulatory requirements.",
          lawRefs: ["Art. 11 - Risk Assessment", "NU-49-MDED-2025 §3.2"],
          priority: "must",
          resources: [
            { title: "Cybersecurity Risk Assessment Guide", url: "https://example.com/risk-assessment" },
            { title: "Moldova Cybersecurity Law", url: "https://example.com/cyber-law" }
          ]
        }
      },
      {
        id: "security-policy",
        title: "Cybersecurity Policy",
        description: "Formal cybersecurity policy document approved by management",
        helpText: "A written policy covering cybersecurity roles, responsibilities, and procedures",
        whyMatters: "Establishes the foundation for your cybersecurity program and compliance efforts",
        category: "governance",
        required: true,
        status: "no",
        recommendation: "Develop and approve a comprehensive cybersecurity policy",
        kind: "manual",
        readOnly: false,
        info: {
          whatItMeans: "A comprehensive written document that outlines your organization's approach to cybersecurity, including roles, responsibilities, and procedures.",
          whyItMatters: "Provides clear guidance for employees and demonstrates management commitment to cybersecurity compliance.",
          lawRefs: ["Art. 12 - Security Policies", "NU-49-MDED-2025 §4.1"],
          priority: "must",
          resources: [
            { title: "Policy Template", url: "https://example.com/policy-template" }
          ]
        }
      }
    ]
  },
  {
    id: "iam",
    title: "Identity & Access Management",
    description: "User access controls and multi-factor authentication",
    items: [
      {
        id: "mfa-privileged",
        title: "MFA for Privileged Accounts",
        description: "Multi-factor authentication enabled for administrator and privileged user accounts",
        helpText: "All admin accounts should require at least two authentication factors",
        whyMatters: "Prevents unauthorized access even if passwords are compromised",
        category: "iam",
        required: true,
        status: "no",
        recommendation: "Enable MFA for all administrator and privileged accounts immediately",
        kind: "manual",
        readOnly: false,
        info: {
          whatItMeans: "Multi-factor authentication requires users to provide two or more verification factors to access privileged accounts.",
          whyItMatters: "Significantly reduces the risk of unauthorized access even if passwords are compromised or stolen.",
          lawRefs: ["Art. 8 - Access Controls", "NU-49-MDED-2025 §5.2"],
          priority: "must",
          resources: [
            { title: "MFA Implementation Guide", url: "https://example.com/mfa-guide" }
          ]
        }
      },
      {
        id: "access-review",
        title: "Regular Access Reviews",
        description: "Periodic review of user access rights and permissions",
        helpText: "Review who has access to what systems at least annually",
        whyMatters: "Ensures employees only have access to systems they need for their current role",
        category: "iam",
        required: true,
        status: "no",
        recommendation: "Establish a quarterly access review process",
        kind: "manual",
        readOnly: false,
        info: {
          whatItMeans: "Regular review and validation of user access rights to ensure employees only have access to systems necessary for their current role.",
          whyItMatters: "Prevents privilege creep and reduces security risks by ensuring access rights remain appropriate over time.",
          lawRefs: ["Art. 9 - Access Management", "NU-49-MDED-2025 §5.3"],
          priority: "must",
          resources: [
            { title: "Access Review Checklist", url: "https://example.com/access-review" }
          ]
        }
      }
    ]
  },
  {
    id: "logging",
    title: "Logging & Monitoring",
    description: "Security event logging and monitoring systems",
    items: [
      {
        id: "centralized-logs",
        title: "Centralized Security Logging",
        description: "Security events are logged in a centralized system",
        helpText: "All security-relevant events should be collected in one place",
        whyMatters: "Enables detection of security incidents and forensic investigation",
        category: "logging",
        required: true,
        status: "no",
        recommendation: "Implement centralized logging for all critical systems",
        kind: "manual",
        readOnly: false,
        info: {
          whatItMeans: "Centralized collection and storage of security events from all systems in a single, searchable location.",
          whyItMatters: "Essential for detecting security incidents, conducting forensic investigations, and meeting compliance requirements.",
          lawRefs: ["Art. 13 - Logging Requirements", "NU-49-MDED-2025 §6.1"],
          priority: "must",
          resources: [
            { title: "SIEM Implementation Guide", url: "https://example.com/siem-guide" }
          ]
        }
      },
      {
        id: "log-retention",
        title: "Log Retention Policy",
        description: "Security logs are retained for at least 12 months",
        helpText: "Legal requirement to maintain logs for investigation purposes",
        whyMatters: "Required by law for incident investigation and compliance audits",
        category: "logging",
        required: true,
        status: "no",
        recommendation: "Configure log retention for at least 12 months",
        kind: "manual",
        readOnly: false,
        info: {
          whatItMeans: "A documented policy that defines how long security logs must be retained, typically 12 months minimum.",
          whyItMatters: "Required by law to support incident investigation and compliance audits. Insufficient retention can result in penalties.",
          lawRefs: ["Art. 14 - Data Retention", "NU-49-MDED-2025 §6.2"],
          priority: "must",
          resources: [
            { title: "Log Retention Best Practices", url: "https://example.com/log-retention" }
          ]
        }
      }
    ]
  },
  {
    id: "backup",
    title: "Backup & Disaster Recovery",
    description: "Data backup and recovery capabilities",
    items: [
      {
        id: "backup-strategy",
        title: "Backup Strategy Documented",
        description: "Formal backup and recovery procedures are documented",
        helpText: "Written procedures for backing up and restoring critical data",
        whyMatters: "Ensures business continuity in case of data loss or ransomware attacks",
        category: "backup",
        required: true,
        status: "no",
        recommendation: "Document your backup strategy and test it regularly",
        kind: "manual",
        readOnly: false,
        info: {
          whatItMeans: "A comprehensive written plan that outlines how critical data is backed up, stored, and can be restored.",
          whyItMatters: "Essential for business continuity and recovery from data loss, ransomware attacks, or system failures.",
          lawRefs: ["Art. 16 - Data Protection", "NU-49-MDED-2025 §8.1"],
          priority: "must",
          resources: [
            { title: "Backup Strategy Template", url: "https://example.com/backup-strategy" }
          ]
        }
      },
      {
        id: "restore-test",
        title: "Last Successful Restore Test",
        description: "Recent test of backup restoration procedures",
        helpText: "When did you last verify that backups can be successfully restored?",
        whyMatters: "Backups are only useful if they can be successfully restored when needed",
        category: "backup",
        required: true,
        status: "no",
        recommendation: "Test backup restoration procedures at least quarterly",
        kind: "manual",
        readOnly: false,
        info: {
          whatItMeans: "Regular testing to verify that backup data can be successfully restored and systems can be recovered.",
          whyItMatters: "Backups are worthless if they cannot be restored. Regular testing ensures recovery procedures work when needed.",
          lawRefs: ["Art. 17 - Recovery Testing", "NU-49-MDED-2025 §8.2"],
          priority: "must",
          resources: [
            { title: "Disaster Recovery Testing Guide", url: "https://example.com/dr-testing" }
          ]
        }
      }
    ]
  },
  {
    id: "audits",
    title: "Audits & Certifications",
    description: "External security audits and certifications",
    items: [
      {
        id: "security-audit",
        title: "Security Audit (≤3 years)",
        description: "External security audit within the last 3 years",
        helpText: "Independent assessment of your cybersecurity controls",
        whyMatters: "Provides objective validation of your security measures",
        category: "audits",
        required: true,
        status: "no",
        recommendation: "Schedule an external security audit",
        kind: "manual",
        readOnly: false,
        info: {
          whatItMeans: "An independent, third-party assessment of your organization's cybersecurity controls and practices.",
          whyItMatters: "Provides objective validation of security measures and helps identify gaps that internal teams might miss.",
          lawRefs: ["Art. 18 - External Audits", "NU-49-MDED-2025 §9.1"],
          priority: "must",
          resources: [
            { title: "Security Audit Checklist", url: "https://example.com/security-audit" }
          ]
        }
      },
      {
        id: "iso27001",
        title: "ISO 27001 Certification",
        description: "ISO 27001 information security management certification",
        helpText: "International standard for information security management",
        whyMatters: "Demonstrates commitment to information security best practices",
        category: "audits",
        required: false,
        status: "na",
        recommendation: "Consider pursuing ISO 27001 certification",
        kind: "manual",
        readOnly: false,
        info: {
          whatItMeans: "An international standard that specifies requirements for establishing, implementing, and maintaining an information security management system.",
          whyItMatters: "Demonstrates commitment to information security best practices and can provide competitive advantage.",
          lawRefs: ["Art. 19 - Standards Compliance", "NU-49-MDED-2025 §9.2"],
          priority: "should",
          resources: [
            { title: "ISO 27001 Implementation Guide", url: "https://example.com/iso27001" }
          ]
        }
      }
    ]
  },
  {
    id: "training",
    title: "Awareness & Training",
    description: "Cybersecurity awareness and training programs",
    items: [
      {
        id: "security-training",
        title: "Last Security Awareness Training",
        description: "Date of most recent cybersecurity training for employees",
        helpText: "All employees should receive cybersecurity awareness training",
        whyMatters: "Employees are the first line of defense against cyber attacks",
        category: "training",
        required: true,
        status: "no",
        recommendation: "Provide annual cybersecurity awareness training for all employees",
        kind: "manual",
        readOnly: false,
        info: {
          whatItMeans: "Regular training programs that educate employees about cybersecurity threats, best practices, and their role in protecting organizational data.",
          whyItMatters: "Employees are often the first line of defense against cyber attacks. Well-trained staff significantly reduce security risks.",
          lawRefs: ["Art. 20 - Security Training", "NU-49-MDED-2025 §10.1"],
          priority: "must",
          resources: [
            { title: "Security Awareness Training Materials", url: "https://example.com/security-training" }
          ]
        }
      }
    ]
  }
];