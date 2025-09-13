#!/bin/bash

# Script to migrate organizational checklist items from the old frontend to new backend templates
# This creates global (organization-wide) checklist templates based on the manual items

BASE_URL="http://localhost:8080/api/v1"

echo "Migrating organizational checklist templates from old frontend..."

# Governance & Risk Management
curl -X POST "$BASE_URL/checklist/templates" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "risk-assessment",
    "title": "Risk Assessment Documentation",
    "description": "Documented cybersecurity risk assessment for your organization",
    "category": "Governance & Risk Management",
    "required": true,
    "scope": "global",
    "recommendation": "Conduct a formal cybersecurity risk assessment and document the findings. Required by law to identify and document cybersecurity risks to your business operations."
  }'

curl -X POST "$BASE_URL/checklist/templates" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "security-policy",
    "title": "Cybersecurity Policy",
    "description": "Formal cybersecurity policy document approved by management",
    "category": "Governance & Risk Management",
    "required": true,
    "scope": "global",
    "recommendation": "Develop and approve a comprehensive cybersecurity policy. A written policy covering cybersecurity roles, responsibilities, and procedures establishes the foundation for your cybersecurity program."
  }'

# Identity & Access Management
curl -X POST "$BASE_URL/checklist/templates" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "mfa-privileged",
    "title": "MFA for Privileged Accounts",
    "description": "Multi-factor authentication enabled for administrator and privileged user accounts",
    "category": "Identity & Access Management",
    "required": true,
    "scope": "global",
    "recommendation": "Enable MFA for all administrator and privileged accounts immediately. All admin accounts should require at least two authentication factors to prevent unauthorized access even if passwords are compromised."
  }'

curl -X POST "$BASE_URL/checklist/templates" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "access-review",
    "title": "Regular Access Reviews",
    "description": "Periodic review of user access rights and permissions",
    "category": "Identity & Access Management",
    "required": true,
    "scope": "global",
    "recommendation": "Establish a quarterly access review process. Review who has access to what systems at least annually to ensure employees only have access to systems they need for their current role."
  }'

# Logging & Monitoring
curl -X POST "$BASE_URL/checklist/templates" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "centralized-logs",
    "title": "Centralized Security Logging",
    "description": "Security events are logged in a centralized system",
    "category": "Logging & Monitoring",
    "required": true,
    "scope": "global",
    "recommendation": "Implement centralized logging for all critical systems. All security-relevant events should be collected in one place to enable detection of security incidents and forensic investigation."
  }'

curl -X POST "$BASE_URL/checklist/templates" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "log-retention",
    "title": "Log Retention (≥12 months)",
    "description": "Security logs are retained for at least 12 months",
    "category": "Logging & Monitoring",
    "required": true,
    "scope": "global",
    "recommendation": "Configure log retention for at least 12 months. This is a legal requirement for incident investigation and compliance audits."
  }'

# Backup & Disaster Recovery
curl -X POST "$BASE_URL/checklist/templates" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "backup-strategy",
    "title": "Backup Strategy Documented",
    "description": "Formal backup and recovery procedures are documented",
    "category": "Backup & Disaster Recovery",
    "required": true,
    "scope": "global",
    "recommendation": "Document your backup strategy and test it regularly. Written procedures for backing up and restoring critical data ensure business continuity in case of data loss or ransomware attacks."
  }'

curl -X POST "$BASE_URL/checklist/templates" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "restore-test",
    "title": "Last Successful Restore Test",
    "description": "Recent test of backup restoration procedures",
    "category": "Backup & Disaster Recovery",
    "required": true,
    "scope": "global",
    "recommendation": "Test backup restoration procedures at least quarterly. Backups are only useful if they can be successfully restored when needed."
  }'

# Email Security
curl -X POST "$BASE_URL/checklist/templates" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "spf-dkim-dmarc",
    "title": "SPF/DKIM/DMARC Implementation",
    "description": "Email authentication protocols are properly configured",
    "category": "Email Security",
    "required": true,
    "scope": "global",
    "recommendation": "Configure SPF, DKIM, and DMARC records for your email domain. These protocols help prevent email spoofing and phishing attacks, protecting your domain from being used in phishing attacks and improving email deliverability."
  }'

# Audits & Certifications
curl -X POST "$BASE_URL/checklist/templates" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "security-audit",
    "title": "Security Audit (≤3 years)",
    "description": "External security audit within the last 3 years",
    "category": "Audits & Certifications",
    "required": true,
    "scope": "global",
    "recommendation": "Schedule an external security audit. Independent assessment of your cybersecurity controls provides objective validation of your security measures."
  }'

curl -X POST "$BASE_URL/checklist/templates" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "iso27001",
    "title": "ISO 27001 Certification",
    "description": "ISO 27001 information security management certification",
    "category": "Audits & Certifications",
    "required": false,
    "scope": "global",
    "recommendation": "Consider pursuing ISO 27001 certification. International standard for information security management demonstrates commitment to information security best practices."
  }'

# Awareness & Training
curl -X POST "$BASE_URL/checklist/templates" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "security-training",
    "title": "Last Security Awareness Training",
    "description": "Date of most recent cybersecurity training for employees",
    "category": "Awareness & Training",
    "required": true,
    "scope": "global",
    "recommendation": "Provide annual cybersecurity awareness training for all employees. All employees should receive cybersecurity awareness training as they are the first line of defense against cyber attacks."
  }'

echo ""
echo "Migration complete! Created 12 global checklist templates."
echo "Note: Excluded automatic items (Web Security, Vulnerability Management) as they will be handled by Lua plugins."
