#!/bin/bash

# Simple test script to create basic templates for testing

BASE_URL="http://localhost:8080/api/v1"

echo "Creating test checklist templates..."

# Create JSON payload with basic templates for testing
cat > /tmp/test_templates.json << 'EOF'
{
  "templates": [
    {
      "id": "risk-assessment",
      "title": "Risk Assessment Documentation",
      "description": "Documented cybersecurity risk assessment for your organization",
      "category": "Governance & Risk Management",
      "required": true,
      "scope": "global",
      "recommendation": "Conduct a formal cybersecurity risk assessment and document the findings",
      "help_text": "Upload or reference your latest cybersecurity risk assessment document",
      "why_matters": "Required by law to identify and document cybersecurity risks",
      "kind": "manual"
    },
    {
      "id": "security-policy", 
      "title": "Cybersecurity Policy",
      "description": "Formal cybersecurity policy document approved by management",
      "category": "Governance & Risk Management", 
      "required": true,
      "scope": "global",
      "recommendation": "Develop and approve a comprehensive cybersecurity policy",
      "help_text": "A written policy covering cybersecurity roles, responsibilities, and procedures",
      "why_matters": "Establishes the foundation for your cybersecurity program",
      "kind": "manual"
    },
    {
      "id": "mfa-privileged",
      "title": "MFA for Privileged Accounts", 
      "description": "Multi-factor authentication enabled for administrator accounts",
      "category": "Identity & Access Management",
      "required": true,
      "scope": "global", 
      "recommendation": "Enable MFA for all administrator and privileged accounts",
      "help_text": "All admin accounts should require at least two authentication factors",
      "why_matters": "Prevents unauthorized access even if passwords are compromised",
      "kind": "manual"
    }
  ]
}
EOF

echo "Uploading test templates to backend..."

# Upload templates
curl -X POST "$BASE_URL/checklist/templates/upload" \
  -H "Content-Type: application/json" \
  -d @/tmp/test_templates.json

# Clean up temporary file
rm -f /tmp/test_templates.json

echo ""
echo "Test templates uploaded! Check the frontend to see if they load correctly."
