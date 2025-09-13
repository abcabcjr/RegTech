import type { ChecklistSection } from './types';

export const defaultChecklistSections: ChecklistSection[] = [
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
        recommendation: "Conduct a formal cybersecurity risk assessment and document the findings"
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
        recommendation: "Develop and approve a comprehensive cybersecurity policy"
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
        recommendation: "Enable MFA for all administrator and privileged accounts immediately"
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
        recommendation: "Establish a quarterly access review process"
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
        recommendation: "Implement centralized logging for all critical systems"
      },
      {
        id: "log-retention",
        title: "Log Retention (≥12 months)",
        description: "Security logs are retained for at least 12 months",
        helpText: "Legal requirement to maintain logs for investigation purposes",
        whyMatters: "Required by law for incident investigation and compliance audits",
        category: "logging",
        required: true,
        status: "no",
        recommendation: "Configure log retention for at least 12 months"
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
        recommendation: "Document your backup strategy and test it regularly"
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
        recommendation: "Test backup restoration procedures at least quarterly"
      }
    ]
  },
  {
    id: "email",
    title: "Email Security",
    description: "Email authentication and security measures",
    items: [
      {
        id: "spf-dkim-dmarc",
        title: "SPF/DKIM/DMARC Implementation",
        description: "Email authentication protocols are properly configured",
        helpText: "These protocols help prevent email spoofing and phishing attacks",
        whyMatters: "Protects your domain from being used in phishing attacks and improves email deliverability",
        category: "email",
        required: true,
        status: "no",
        recommendation: "Configure SPF, DKIM, and DMARC records for your email domain"
      }
    ]
  },
  {
    id: "web",
    title: "Web Security",
    description: "Website security headers and encryption (Display Only)",
    items: [
      {
        id: "tls-https",
        title: "TLS/HTTPS Implementation",
        description: "All websites use secure HTTPS connections",
        helpText: "This is automatically checked by our scanning tools",
        whyMatters: "Encrypts data in transit and builds user trust",
        category: "web",
        required: true,
        status: "no",
        recommendation: "Enable HTTPS for all web properties"
      },
      {
        id: "security-headers",
        title: "Security Headers",
        description: "Proper HTTP security headers are configured",
        helpText: "Headers like HSTS, CSP, and X-Frame-Options protect against common attacks",
        whyMatters: "Prevents common web vulnerabilities and attacks",
        category: "web",
        required: true,
        status: "no",
        recommendation: "Configure security headers (HSTS, CSP, X-Frame-Options)"
      }
    ]
  },
  {
    id: "vulnerability",
    title: "Vulnerability Management",
    description: "Vulnerability scanning and patch management (Display Only)",
    items: [
      {
        id: "vuln-scanning",
        title: "Regular Vulnerability Scanning",
        description: "Automated scanning for security vulnerabilities",
        helpText: "This is automatically performed by our scanning tools",
        whyMatters: "Identifies security weaknesses before attackers can exploit them",
        category: "vulnerability",
        required: true,
        status: "no",
        recommendation: "Implement regular vulnerability scanning"
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
        recommendation: "Schedule an external security audit"
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
        recommendation: "Consider pursuing ISO 27001 certification"
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
        recommendation: "Provide annual cybersecurity awareness training for all employees"
      }
    ]
  }
];
