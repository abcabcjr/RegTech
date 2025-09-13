// Mock data based on the updated JSON structure
// This simulates the data that would come from checklist_templates_full.json

import type { TemplatesData } from './types';

export const mockTemplatesData: TemplatesData = {
  templates: [
    {
      id: "risk-assessment",
      title: "Risk Assessment Documentation",
      description: "Documented cybersecurity risk assessment for your organization",
      category: "Governance & Risk Management",
      required: true,
      scope: "global",
      recommendation: "Conduct a formal cybersecurity risk assessment and document the findings",
      help_text: "Upload or reference your latest cybersecurity risk assessment document",
      why_matters: "Required by law to identify and document cybersecurity risks to your business operations",
      kind: "manual",
      read_only: false,
      guide: {
        what_it_is: "A formal document that identifies, analyzes, and evaluates cybersecurity risks to your organization's information systems and data. Think of it as a health checkup for your digital infrastructure - it looks at what could go wrong and how likely it is to happen.",
        why_it_matters: "Without knowing your risks, you're flying blind. This assessment helps you understand where you're vulnerable so you can protect what matters most to your business. It's also required by Moldova's Cybersecurity Law.",
        attack_vectors: [
          "Unidentified vulnerabilities remain unpatched and exploitable",
          "Lack of risk prioritization leads to inadequate resource allocation",
          "Compliance gaps expose organization to regulatory penalties"
        ],
        potential_impact: [
          "Cyber attacks succeed because critical vulnerabilities weren't identified",
          "Business operations disrupted due to unprotected critical systems",
          "Legal penalties and fines for non-compliance with cybersecurity regulations",
          "Loss of customer trust and business reputation damage"
        ],
        non_technical_steps: [
          "Schedule a meeting with your IT team or external cybersecurity consultant",
          "Create an inventory of all your important digital assets (computers, servers, data)",
          "Identify what information is most critical to your business operations",
          "Document potential threats specific to your industry and location",
          "Assess the likelihood and impact of each identified risk",
          "Create a written report with findings and recommendations",
          "Review and update the assessment annually or when major changes occur"
        ],
        law: {
          requirement_summary: "Moldova's Cybersecurity Law requires organizations to conduct regular cybersecurity risk assessments to identify, analyze, and evaluate threats to their information systems. This must be documented and updated regularly.",
          article_refs: ["Art. 11 - Risk Assessment", "NU-49-MDED-2025 §3.2"]
        },
        resources: [
          {"title": "Cybersecurity Risk Assessment Guide", "url": "https://example.com/risk-assessment", "type": "document", "description": "Step-by-step guide for conducting risk assessments"},
          {"title": "Moldova Cybersecurity Law", "url": "https://example.com/cyber-law", "type": "document", "description": "Official legal text"},
          {"title": "NIST Cybersecurity Framework", "url": "https://www.nist.gov/cyberframework", "type": "link", "description": "Industry standard framework"}
        ],
        priority: "must",
        images: [
          {
            url: "https://via.placeholder.com/600x400?text=Risk+Assessment+Process",
            alt: "Risk Assessment Process Diagram",
            caption: "Standard risk assessment process flow showing identification, analysis, and evaluation phases",
            width: 600,
            height: 400
          }
        ],
        videos: [
          {
            url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
            title: "How to Conduct a Cybersecurity Risk Assessment",
            description: "A comprehensive 15-minute tutorial on risk assessment methodology",
            thumbnail: "https://via.placeholder.com/320x180?text=Risk+Assessment+Video",
            duration: "15:23",
            platform: "youtube"
          }
        ],
        schemas: [
          {
            title: "Risk Assessment Flow Chart",
            description: "Interactive diagram showing the complete risk assessment process",
            type: "flow_chart",
            image_url: "https://via.placeholder.com/800x600?text=Risk+Flow+Chart",
            interactive_url: "https://example.com/interactive-risk-flow"
          }
        ],
        evidence_template: {
          title: "Risk Assessment Evidence Template",
          description: "Use this template to document your cybersecurity risk assessment. This template ensures you capture all required information according to Moldova's cybersecurity regulations.",
          template_type: "pdf",
          url: "https://example.com/templates/risk-assessment-template.pdf",
          examples: [
            "Completed risk assessment report with executive summary",
            "Asset inventory with criticality ratings (High/Medium/Low)",
            "Threat analysis specific to your industry and location",
            "Vulnerability assessment results",
            "Risk register with likelihood and impact scores",
            "Mitigation strategies and action plan",
            "Approval signatures from management"
          ],
          required_fields: [
            "Assessment date and scope",
            "Assets identified and categorized",
            "Threats and vulnerabilities identified",
            "Risk scores (likelihood × impact)",
            "Current controls and their effectiveness",
            "Residual risk after controls",
            "Recommended actions and timelines",
            "Management approval and sign-off"
          ],
          sample_entries: [
            "Risk Assessment conducted on 2024-01-15 covering all IT assets and data systems",
            "Critical Asset: Customer Database (Impact: High, Likelihood: Medium, Risk Score: 7/10)",
            "Vulnerability: Unpatched web server (CVE-2023-XXXX) - Priority: High",
            "Mitigation: Implement monthly security patches - Responsible: IT Manager - Due: 2024-02-01"
          ]
        }
      }
    },
    {
      id: "ssl-certificate-validation-012",
      title: "SSL Certificate Validation",
      description: "SSL certificates are valid and properly configured",
      category: "Network Security",
      required: true,
      scope: "asset",
      recommendation: "Ensure all HTTPS services have valid SSL certificates",
      help_text: "Certificate should be valid, not expired, and properly configured",
      why_matters: "Ensures encrypted communication and builds user trust",
      kind: "auto",
      read_only: true,
      script_controlled: true,
      guide: {
        what_it_is: "SSL certificates are digital certificates that encrypt the connection between your website and your visitors' browsers. When you see a padlock icon in the browser, that means the website has a valid SSL certificate protecting the connection.",
        why_it_matters: "Without a valid SSL certificate, all information sent between your website and visitors (passwords, credit card numbers, personal data) travels unencrypted and can be easily intercepted by criminals.",
        attack_vectors: [
          "Man-in-the-middle attacks where criminals intercept unencrypted data",
          "Browser warnings scare away customers and damage trust",
          "Search engines penalize websites without SSL certificates"
        ],
        potential_impact: [
          "Customer passwords and payment information stolen during transmission",
          "Loss of customer trust due to browser security warnings",
          "Lower search engine rankings affecting business visibility",
          "Compliance violations for handling sensitive customer data",
          "Legal liability for failing to protect customer information"
        ],
        non_technical_steps: [
          "Contact your web hosting provider or IT support team",
          "Ask them to install or renew SSL certificates for all your websites",
          "Verify that your website shows 'https://' and a padlock icon",
          "Set up automatic renewal so certificates don't expire unexpectedly",
          "Test all website forms and login pages to ensure they work with SSL",
          "Update any internal links to use 'https://' instead of 'http://'",
          "Monitor certificate expiration dates and set renewal reminders"
        ],
        law: {
          requirement_summary: "Moldova's Cybersecurity Law requires encryption of sensitive data in transit. SSL certificates are the primary method for encrypting web traffic and protecting customer information.",
          article_refs: ["Art. 16 - Data Encryption", "NU-49-MDED-2025 §8.3"]
        },
        resources: [
          {"title": "SSL Certificate Guide", "url": "https://example.com/ssl-guide", "type": "document", "description": "Complete guide to SSL certificate installation"},
          {"title": "Let's Encrypt Free SSL", "url": "https://letsencrypt.org/", "type": "link", "description": "Free SSL certificates with automatic renewal"},
          {"title": "SSL Checker Tool", "url": "https://www.sslshopper.com/ssl-checker.html", "type": "link", "description": "Test your SSL certificate configuration"}
        ],
        priority: "must",
        images: [
          {
            url: "https://via.placeholder.com/500x300?text=SSL+Certificate+Process",
            alt: "SSL Certificate Installation Process",
            caption: "Visual guide showing how SSL certificates encrypt data between browser and server",
            width: 500,
            height: 300
          },
          {
            url: "https://via.placeholder.com/400x200?text=Browser+Padlock+Icon",
            alt: "Browser Security Indicators",
            caption: "How SSL certificates appear in different web browsers",
            width: 400,
            height: 200
          }
        ],
        videos: [
          {
            url: "https://www.youtube.com/watch?v=example-ssl",
            title: "SSL Certificates Explained for Beginners",
            description: "Easy-to-understand explanation of how SSL certificates work and why they're important",
            thumbnail: "https://via.placeholder.com/320x180?text=SSL+Explained",
            duration: "8:45",
            platform: "youtube"
          }
        ],
        schemas: [
          {
            title: "HTTPS Connection Flow",
            description: "Interactive diagram showing how SSL/TLS handshake works",
            type: "network_diagram",
            image_url: "https://via.placeholder.com/700x500?text=HTTPS+Flow+Diagram",
            interactive_url: "https://example.com/ssl-handshake-demo"
          }
        ]
      }
    },
    {
      id: "security-policy",
      title: "Cybersecurity Policy",
      description: "Formal cybersecurity policy document approved by management",
      category: "Governance & Risk Management",
      required: true,
      scope: "global",
      recommendation: "Develop and approve a comprehensive cybersecurity policy",
      help_text: "A written policy covering cybersecurity roles, responsibilities, and procedures",
      why_matters: "Establishes the foundation for your cybersecurity program and compliance efforts",
      kind: "manual",
      read_only: false,
      guide: {
        what_it_is: "A comprehensive written document that outlines your organization's approach to cybersecurity. It's like your company's cybersecurity rulebook that tells everyone what they should and shouldn't do to keep your business safe online.",
        why_it_matters: "Without clear rules, employees don't know how to protect your business from cyber threats. A good policy ensures everyone is on the same page about cybersecurity and shows regulators that your management takes security seriously.",
        attack_vectors: [
          "Employees inadvertently expose sensitive data due to lack of clear guidelines",
          "Inconsistent security practices create vulnerabilities across the organization",
          "Social engineering attacks succeed when staff don't know proper security procedures"
        ],
        potential_impact: [
          "Data breaches occur because employees don't follow proper security procedures",
          "Regulatory fines for failing to demonstrate due diligence in cybersecurity",
          "Business partners lose confidence due to poor security governance",
          "Increased insurance premiums or denied coverage due to inadequate policies"
        ],
        non_technical_steps: [
          "Hold a management meeting to discuss cybersecurity commitment and responsibilities",
          "Outline acceptable use of company computers, email, and internet access",
          "Define password requirements and access control procedures",
          "Establish incident reporting procedures for suspected security issues",
          "Create guidelines for handling sensitive customer and business data",
          "Have management approve and sign the policy document",
          "Distribute the policy to all employees and ensure they understand it",
          "Schedule annual reviews to update the policy as needed"
        ],
        law: {
          requirement_summary: "Moldova's Cybersecurity Law requires organizations to establish and maintain documented cybersecurity policies that define roles, responsibilities, and procedures for protecting information systems.",
          article_refs: ["Art. 12 - Security Policies", "NU-49-MDED-2025 §4.1"]
        },
        resources: [
          {"title": "Cybersecurity Policy Template", "url": "https://example.com/policy-template"},
          {"title": "SANS Policy Templates", "url": "https://www.sans.org/information-security-policy/"}
        ],
        priority: "must"
      }
    },
    {
      id: "mfa-privileged",
      title: "MFA for Privileged Accounts",
      description: "Multi-factor authentication enabled for administrator and privileged user accounts",
      category: "Identity & Access Management",
      required: true,
      scope: "global",
      recommendation: "Enable MFA for all administrator and privileged accounts immediately",
      help_text: "All admin accounts should require at least two authentication factors",
      why_matters: "Prevents unauthorized access even if passwords are compromised",
      kind: "manual",
      read_only: false,
      guide: {
        what_it_is: "Multi-factor authentication (MFA) requires users to provide two or more pieces of evidence to access privileged accounts, like a password plus a code from their phone.",
        why_it_matters: "Even if criminals steal admin passwords, they still can't access your systems without the second factor. This dramatically reduces the risk of unauthorized access to critical business systems.",
        attack_vectors: [
          "Password-only authentication easily compromised through phishing or data breaches",
          "Administrative accounts are high-value targets for cybercriminals",
          "Compromised admin accounts allow full system access and data theft"
        ],
        potential_impact: [
          "Complete compromise of business systems and data",
          "Ransomware deployment across entire network",
          "Theft of customer data and business secrets",
          "Long-term persistent access by criminal organizations",
          "Regulatory penalties for inadequate access controls"
        ],
        non_technical_steps: [
          "Identify all administrator and privileged user accounts in your organization",
          "Contact your IT team or software vendors to enable MFA options",
          "Choose appropriate MFA methods (phone apps, SMS, hardware tokens)",
          "Train administrators on how to use the new MFA systems",
          "Test the MFA setup to ensure it works properly",
          "Create backup authentication methods in case primary method fails",
          "Document the MFA procedures for future reference",
          "Monitor MFA usage and failed authentication attempts"
        ],
        law: {
          requirement_summary: "Moldova's Cybersecurity Law requires strong authentication controls for privileged accounts to prevent unauthorized access to critical systems.",
          article_refs: ["Art. 8 - Access Controls", "NU-49-MDED-2025 §5.2"]
        },
        resources: [
          {"title": "MFA Implementation Guide", "url": "https://example.com/mfa-guide"},
          {"title": "Microsoft Authenticator Setup", "url": "https://support.microsoft.com/authenticator"},
          {"title": "Google Authenticator Guide", "url": "https://support.google.com/accounts/answer/1066447"}
        ],
        priority: "must"
      }
    }
  ]
};

/**
 * Mock function to get guide data by ID
 * In production, this would fetch from the backend API
 */
export function getMockGuideById(id: string) {
  const template = mockTemplatesData.templates.find(t => t.id === id);
  return template?.guide || null;
}
