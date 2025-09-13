# PDF Template Guides

This folder contains PDF implementation guides for compliance requirements.

## How to Add New PDF Guides

1. **Add the PDF file** to this folder with a descriptive name (e.g., `risk-assessment-guide.pdf`)

2. **Update the mapping** in `frontendv2/src/lib/data/pdf-guides.ts`:
   ```typescript
   "your-template-id": {
     id: "your-template-id",
     title: "Your Guide Title",
     description: "Description of what this guide covers",
     url: "/assets/templateGuides/your-file.pdf",
     sections: [
       "Section 1: Overview",
       "Section 2: Implementation Steps",
       "Section 3: Templates and Checklists"
     ],
     tips: [
       "Tip 1: Important consideration",
       "Tip 2: Best practice recommendation"
     ],
     file_size: "1.5 MB",
     last_updated: "2024-01-15"
   }
   ```

3. **Test the integration** by checking the PDF Guide tab in the compliance interface

## Current PDF Guides

- `risk-assessment-guide.pdf` - Risk Assessment Implementation Guide
- `security-policy-guide.pdf` - Cybersecurity Policy Development Guide  
- `mfa-implementation-guide.pdf` - Multi-Factor Authentication Implementation Guide
- `access-review-guide.pdf` - Access Review Process Guide

## File Naming Convention

Use kebab-case with descriptive names:
- `risk-assessment-guide.pdf`
- `security-policy-guide.pdf`
- `mfa-implementation-guide.pdf`
- `access-review-guide.pdf`

## PDF Content Guidelines

Each PDF should include:
- Executive summary
- Step-by-step implementation instructions
- Templates and checklists
- Compliance verification procedures
- Best practices and tips
- Legal and regulatory context
