#!/bin/bash

# Script to migrate organizational checklist items from the old frontend to new backend templates
# This creates global (organization-wide) checklist templates based on the manual items

BASE_URL="http://localhost:8080/api/v1"

echo "Migrating organizational checklist templates from old frontend..."

# Create JSON payload with all templates
cat > /tmp/checklist_templates.json << 'EOF'
{
  "templates": [
    {
      "id": "risk-assessment",
      "title": "Risk Assessment Documentation",
      "description": "Documented cybersecurity risk assessment for your organization",
      "category": "Governance & Risk Management",
      "required": true,
      "scope": "global",
      "recommendation": "Conduct a formal cybersecurity risk assessment and document the findings. Required by law to identify and document cybersecurity risks to your business operations.",
      "help_text": "Upload or reference your latest cybersecurity risk assessment document",
      "why_matters": "Required by law to identify and document cybersecurity risks to your business operations",
      "kind": "manual",
      "info": {
        "what_it_means": "A formal document that identifies, analyzes, and evaluates cybersecurity risks to your organization's information systems and data.",
        "why_it_matters": "Required by Moldova's Cybersecurity Law to demonstrate proactive risk management and compliance with regulatory requirements.",
        "law_refs": ["Art. 11 - Risk Assessment", "NU-49-MDED-2025 §3.2"],
        "priority": "must",
        "resources": [
          {"title": "Cybersecurity Risk Assessment Guide", "url": "https://example.com/risk-assessment"},
          {"title": "Moldova Cybersecurity Law", "url": "https://example.com/cyber-law"}
        ]
      }
    },
    {
      "id": "security-policy",
      "title": "Cybersecurity Policy",
      "description": "Formal cybersecurity policy document approved by management",
      "category": "Governance & Risk Management",
      "required": true,
      "scope": "global",
      "recommendation": "Develop and approve a comprehensive cybersecurity policy. A written policy covering cybersecurity roles, responsibilities, and procedures establishes the foundation for your cybersecurity program."
    },
    {
      "id": "mfa-privileged",
      "title": "MFA for Privileged Accounts",
      "description": "Multi-factor authentication enabled for administrator and privileged user accounts",
      "category": "Identity & Access Management",
      "required": true,
      "scope": "global",
      "recommendation": "Enable MFA for all administrator and privileged accounts immediately. All admin accounts should require at least two authentication factors to prevent unauthorized access even if passwords are compromised."
    },
    {
      "id": "access-review",
      "title": "Regular Access Reviews",
      "description": "Periodic review of user access rights and permissions",
      "category": "Identity & Access Management",
      "required": true,
      "scope": "global",
      "recommendation": "Establish a quarterly access review process. Review who has access to what systems at least annually to ensure employees only have access to systems they need for their current role."
    },
    {
      "id": "centralized-logs",
      "title": "Centralized Security Logging",
      "description": "Security events are logged in a centralized system",
      "category": "Logging & Monitoring",
      "required": true,
      "scope": "global",
      "recommendation": "Implement centralized logging for all critical systems. All security-relevant events should be collected in one place to enable detection of security incidents and forensic investigation."
    },
    {
      "id": "log-retention",
      "title": "Log Retention (≥12 months)",
      "description": "Security logs are retained for at least 12 months",
      "category": "Logging & Monitoring",
      "required": true,
      "scope": "global",
      "recommendation": "Configure log retention for at least 12 months. This is a legal requirement for incident investigation and compliance audits."
    },
    {
      "id": "backup-strategy",
      "title": "Backup Strategy Documented",
      "description": "Formal backup and recovery procedures are documented",
      "category": "Backup & Disaster Recovery",
      "required": true,
      "scope": "global",
      "recommendation": "Document your backup strategy and test it regularly. Written procedures for backing up and restoring critical data ensure business continuity in case of data loss or ransomware attacks."
    },
    {
      "id": "restore-test",
      "title": "Last Successful Restore Test",
      "description": "Recent test of backup restoration procedures",
      "category": "Backup & Disaster Recovery",
      "required": true,
      "scope": "global",
      "recommendation": "Test backup restoration procedures at least quarterly. Backups are only useful if they can be successfully restored when needed."
    },
    {
      "id": "spf-dkim-dmarc",
      "title": "SPF/DKIM/DMARC Implementation",
      "description": "Email authentication protocols are properly configured",
      "category": "Email Security",
      "required": true,
      "scope": "global",
      "recommendation": "Configure SPF, DKIM, and DMARC records for your email domain. These protocols help prevent email spoofing and phishing attacks, protecting your domain from being used in phishing attacks and improving email deliverability."
    },
    {
      "id": "security-audit",
      "title": "Security Audit (≤3 years)",
      "description": "External security audit within the last 3 years",
      "category": "Audits & Certifications",
      "required": true,
      "scope": "global",
      "recommendation": "Schedule an external security audit. Independent assessment of your cybersecurity controls provides objective validation of your security measures."
    },
    {
      "id": "iso27001",
      "title": "ISO 27001 Certification",
      "description": "ISO 27001 information security management certification",
      "category": "Audits & Certifications",
      "required": false,
      "scope": "global",
      "recommendation": "Consider pursuing ISO 27001 certification. International standard for information security management demonstrates commitment to information security best practices."
    },
    {
      "id": "security-training",
      "title": "Last Security Awareness Training",
      "description": "Date of most recent cybersecurity training for employees",
      "category": "Awareness & Training",
      "required": true,
      "scope": "global",
      "recommendation": "Provide annual cybersecurity awareness training for all employees. All employees should receive cybersecurity awareness training as they are the first line of defense against cyber attacks."
    },
    {
      "id": "ssl-certificate-validation-012",
      "title": "SSL Certificate Validation",
      "description": "SSL certificates are valid and properly configured",
      "category": "Network Security",
      "required": true,
      "scope": "asset",
      "recommendation": "Ensure all HTTPS services have valid SSL certificates. Invalid or expired certificates create security vulnerabilities and user trust issues.",
      "scanner_validation": true
    },
    {
      "id": "http-security-headers-013",
      "title": "HTTP Security Headers",
      "description": "Security headers like HSTS are properly configured",
      "category": "Network Security",
      "required": true,
      "scope": "asset",
      "recommendation": "Configure security headers including HSTS, CSP, and X-Frame-Options to protect against common web vulnerabilities.",
      "scanner_validation": true
    },
    {
      "id": "open-ports-review-014",
      "title": "Open Ports Security Review",
      "description": "All open ports have been reviewed and justified",
      "category": "Network Security",
      "required": true,
      "scope": "asset",
      "recommendation": "Regularly review all open ports and services. Close unnecessary ports and ensure exposed services are properly secured.",
      "scanner_validation": true
    },
    {
      "id": "service-authentication-020",
      "title": "Service Authentication",
      "description": "Services require proper authentication and authorization",
      "category": "Identity & Access Management",
      "required": true,
      "scope": "asset",
      "recommendation": "Ensure all exposed services implement proper authentication mechanisms. Database and admin services should never be directly accessible from the internet.",
      "scanner_validation": true
    },
    {
      "id": "web-service-security-021",
      "title": "Web Service Security",
      "description": "Web services are properly secured and configured",
      "category": "Web Security",
      "required": true,
      "scope": "asset",
      "recommendation": "Web services should use HTTPS, implement proper authentication, and include security headers to protect against common attacks.",
      "scanner_validation": true
    },
    {
      "id": "http-to-https-redirect-022",
      "title": "HTTP to HTTPS Redirect",
      "description": "HTTP traffic is properly redirected to HTTPS",
      "category": "Web Security",
      "required": true,
      "scope": "asset",
      "recommendation": "Configure automatic redirection from HTTP to HTTPS to ensure all web traffic is encrypted.",
      "scanner_validation": true
    },
    {
      "id": "insecure-service-detection-023",
      "title": "Insecure Service Detection",
      "description": "No insecure services (FTP, Telnet, unencrypted protocols) are exposed",
      "category": "Vulnerability Management",
      "required": true,
      "scope": "asset",
      "recommendation": "Replace insecure protocols like FTP, Telnet, and unencrypted HTTP with secure alternatives (SFTP, SSH, HTTPS).",
      "scanner_validation": true
    },
    {
      "id": "development-environment-exposure-024",
      "title": "Development Environment Exposure",
      "description": "Development and staging environments are not publicly accessible",
      "category": "Vulnerability Management",
      "required": true,
      "scope": "asset",
      "recommendation": "Ensure development, staging, and test environments are not accessible from the public internet to prevent information disclosure.",
      "scanner_validation": true
    },
    {
      "id": "high-risk-port-exposure-025",
      "title": "High-Risk Port Exposure",
      "description": "High-risk ports (RDP, SMB, database) are not exposed to the internet",
      "category": "Vulnerability Management",
      "required": true,
      "scope": "asset",
      "recommendation": "High-risk services like RDP (3389), SMB (445), and database ports should never be directly accessible from the internet. Use VPN or other secure access methods.",
      "scanner_validation": true
    }
  ]
}
EOF

echo "Uploading templates to backend..."

# Upload all templates at once
curl -X POST "$BASE_URL/checklist/templates/upload" \
  -H "Content-Type: application/json" \
  -d @/tmp/checklist_templates.json

# Clean up temporary file
rm -f /tmp/checklist_templates.json

echo ""
echo "Migration complete! Uploaded 21 global checklist templates (12 manual + 9 scanner-based)."
echo "Scanner-based templates will be automatically validated by Lua plugins during asset scanning."