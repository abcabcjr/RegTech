# CyberCare - Moldovan Cybersecurity Compliance Platform

🛡️ **Mission**: Help Moldovan businesses comply with the Cybersecurity Law by turning complex requirements into plain-language checklists and an easy, 3-step incident reporting workflow.

## 🎯 Core Focus

**CyberCare focuses on two main areas:**
1. **Compliance Records with Evidence**: Track compliance status, upload evidence, and maintain audit trails
2. **Incident Reporting Workflow**: 3-stage process (Initial → Update → Final) for cybersecurity incident reporting

*Note: Security scanning features are placeholder/demo only - no actual scans are performed.*

## 🌟 Features

### ✅ Compliance Checklist
- **9 key compliance areas** covering Moldova's Cybersecurity Law requirements
- **Plain-language explanations** of complex legal requirements  
- **Evidence upload and tracking** (mock implementation)
- **Progress scoring** with color-coded compliance levels
- **Recommendations** for non-compliant items

### 🚨 Incident Reporting
- **3-stage workflow**: Initial → Update → Final reports
- **Structured data collection** for regulatory requirements
- **Draft saving** and submission tracking
- **JSON export** for external systems
- **Printable reports** for audits

### 📊 Reports & Export
- **Compliance reports** with organization profile and checklist status
- **Incident reports** with full details across all stages
- **Print/PDF export** functionality
- **JSON data export** for integration

### ⚙️ Settings & Profile
- Organization profile management
- Data overview and statistics
- Data reset functionality
- Legal disclaimers and guidance

## 🏗️ Technical Architecture

### Stack
- **Frontend**: React 18 + TypeScript + Vite
- **Styling**: Tailwind CSS + shadcn/ui components
- **Routing**: React Router v6
- **Data Validation**: Zod schemas
- **Storage**: localStorage (browser-based)
- **Icons**: Heroicons

### Project Structure
```
src/
├── components/
│   ├── ui/              # Reusable UI components
│   ├── layout/          # Navigation and layout
│   └── compliance/      # Compliance-specific components
├── lib/
│   ├── types.ts         # TypeScript interfaces
│   ├── checklist-data.ts # Default compliance items
│   ├── mock-findings.ts  # Demo security findings
│   └── persistence.ts   # localStorage utilities
├── pages/               # Route components
│   ├── Index.tsx        # Dashboard/home
│   ├── Checklist.tsx    # Compliance tracking
│   ├── Incidents.tsx    # Incident management
│   ├── Reports.tsx      # Report generation
│   └── Settings.tsx     # Configuration
└── App.tsx             # Main application
```

## 🚀 Getting Started

### Prerequisites
- Node.js 18+ and npm (install with [nvm](https://github.com/nvm-sh/nvm#installing-and-updating))

### Installation & Development
```bash
# Clone the repository
git clone <YOUR_GIT_URL>
cd cybercare

# Install dependencies
npm install

# Start development server
npm run dev

# Open http://localhost:8080
```

### Building for Production
```bash
# Build for production
npm run build

# Preview production build
npm run preview
```

## 📋 Compliance Areas Covered

1. **Governance & Risk Management** - Risk assessments and security policies
2. **Identity & Access Management** - MFA and access controls
3. **Logging & Monitoring** - Security event logging and retention
4. **Backup & Disaster Recovery** - Backup strategies and testing
5. **Email Security** - SPF/DKIM/DMARC implementation
6. **Web Security** - TLS/HTTPS and security headers *(auto-checked)*
7. **Vulnerability Management** - Scanning and patch management *(auto-checked)*
8. **Audits & Certifications** - External audits and ISO 27001
9. **Awareness & Training** - Employee security training

## 🔧 Extending CyberCare

### Adding Real Security Scanning
To integrate actual security scanning capabilities:

1. **Review `src/lib/scan/TODO.md`** for integration guidelines
2. **Replace mock findings** in `src/lib/mock-findings.ts` with real scan results
3. **Add API endpoints** for scanner integration
4. **Update findings display** to handle live data

### Expected Scanner Integration Points
```typescript
// Expected API contract for scan results
interface ScanResult {
  findings: Finding[];
  scanDate: string;
  scanType: string;
  target: string;
}

// Integration points in the codebase
- src/lib/mock-findings.ts (replace with API calls)
- src/pages/Index.tsx (Mini-Audit section)
- src/pages/Reports.tsx (Security findings section)
```

### Database Integration
Currently uses localStorage. To add backend storage:

1. Replace `src/lib/persistence.ts` functions with API calls
2. Add authentication and user management
3. Implement multi-tenant organization support
4. Add real-time sync capabilities

## ⚖️ Legal Disclaimers

**Important**: CyberCare is a demonstration application created for educational and hackathon purposes.

- ❌ **Not legal advice** - Does not constitute legal advice or guarantee compliance
- ❌ **Not certified** - Not certified or endorsed by Moldovan authorities  
- ❌ **Demo purposes only** - Use real legal consultation for actual compliance
- ✅ **Educational tool** - Helps understand compliance concepts and workflows

For official requirements and legal interpretations, consult:
- Official Moldova Cybersecurity Law documentation
- Qualified legal professionals specializing in cybersecurity law
- Certified compliance consultants

## 🔒 Data & Privacy

- **Local storage only** - All data stored in browser localStorage
- **No external transmission** - No data sent to external servers
- **Demo data included** - Sample findings and examples for demonstration
- **Reset available** - Full data reset available in Settings

## 🎨 Design System

CyberCare uses a professional cybersecurity-themed design system:
- **Primary**: Professional cyber blue (#3B82F6)
- **Status colors**: Success (green), Warning (yellow), Destructive (red)
- **Typography**: Clean, accessible fonts optimized for compliance documentation
- **Components**: Based on shadcn/ui with custom variants for cybersecurity context

## 🤝 Contributing

This project was created for hackathon demonstration. To extend or adapt:

1. Fork the repository
2. Create feature branches for new capabilities
3. Maintain the focus on compliance and incident reporting
4. Follow the existing design patterns and component structure
5. Update documentation for any new integration points

## 📄 License

This project is open source and available for educational and demonstration purposes.

---

**Built for Moldova's cybersecurity compliance needs** 🇲🇩