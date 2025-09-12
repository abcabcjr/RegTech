import { useEffect, useState } from "react";
import { loadChecklistState, loadOrganizationProfile } from "@/lib/persistence";
import { ChecklistState, OrganizationProfile } from "@/lib/types";

export default function CompliancePrint() {
  const [checklistState, setChecklistState] = useState<ChecklistState | null>(null);
  const [orgProfile, setOrgProfile] = useState<OrganizationProfile | null>(null);

  useEffect(() => {
    setChecklistState(loadChecklistState());
    setOrgProfile(loadOrganizationProfile());
  }, []);

  if (!checklistState || !orgProfile) {
    return <div>Loading...</div>;
  }

  const totalItems = checklistState.sections.reduce((total, section) => total + section.items.length, 0);
  const compliantItems = checklistState.sections.reduce(
    (total, section) => total + section.items.filter(item => item.status === "yes").length,
    0
  );
  const nonCompliantItems = checklistState.sections.reduce(
    (total, section) => total + section.items.filter(item => item.status === "no").length,
    0
  );
  const naItems = checklistState.sections.reduce(
    (total, section) => total + section.items.filter(item => item.status === "na").length,
    0
  );

  const compliancePercentage = Math.round((compliantItems / (totalItems - naItems)) * 100);

  return (
    <div className="max-w-4xl mx-auto p-8 bg-white text-black print:shadow-none">
      <style>{`
        @media print {
          body { margin: 0; }
          .no-print { display: none !important; }
          .print-page { page-break-after: always; }
        }
      `}</style>

      {/* Header */}
      <div className="text-center mb-8 border-b-2 border-brand pb-4">
        <h1 className="text-3xl font-bold text-brand mb-2">Cybersecurity Compliance Report</h1>
        <h2 className="text-xl font-semibold mb-2">{orgProfile.name}</h2>
        <div className="text-sm text-gray-600">
          <p>Sector: {orgProfile.sector}</p>
          <p>Previous Year Turnover: €{orgProfile.turnoverPrevYear?.toLocaleString()}</p>
          <p>Report Generated: {new Date().toLocaleDateString()}</p>
        </div>
      </div>

      {/* Compliance Summary */}
      <div className="mb-8">
        <h2 className="text-2xl font-bold text-brand mb-4">Compliance Summary</h2>
        <div className="grid grid-cols-4 gap-4 mb-4">
          <div className="text-center p-4 border rounded">
            <div className="text-2xl font-bold text-green-600">{compliantItems}</div>
            <div className="text-sm">Compliant</div>
          </div>
          <div className="text-center p-4 border rounded">
            <div className="text-2xl font-bold text-red-600">{nonCompliantItems}</div>
            <div className="text-sm">Non-Compliant</div>
          </div>
          <div className="text-center p-4 border rounded">
            <div className="text-2xl font-bold text-gray-600">{naItems}</div>
            <div className="text-sm">Not Applicable</div>
          </div>
          <div className="text-center p-4 border rounded">
            <div className="text-2xl font-bold text-brand">{compliancePercentage}%</div>
            <div className="text-sm">Compliance Score</div>
          </div>
        </div>
      </div>

      {/* Detailed Sections */}
      {checklistState.sections.map((section, sectionIndex) => (
        <div key={section.id} className={`mb-8 ${sectionIndex > 0 ? 'print-page' : ''}`}>
          <h2 className="text-xl font-bold text-brand mb-2">{section.title}</h2>
          <p className="text-gray-600 mb-4">{section.description}</p>
          
          <table className="w-full border-collapse border border-gray-300 text-sm">
            <thead>
              <tr className="bg-gray-100">
                <th className="border border-gray-300 p-2 text-left">Item</th>
                <th className="border border-gray-300 p-2 text-center">Status</th>
                <th className="border border-gray-300 p-2 text-left">Why It Matters</th>
                <th className="border border-gray-300 p-2 text-left">Evidence/Justification</th>
                <th className="border border-gray-300 p-2 text-left">Recommendation</th>
              </tr>
            </thead>
            <tbody>
              {section.items.map((item) => (
                <tr key={item.id}>
                  <td className="border border-gray-300 p-2">
                    <div className="font-medium">{item.title}</div>
                    <div className="text-xs text-gray-500">{item.description}</div>
                  </td>
                  <td className="border border-gray-300 p-2 text-center">
                    <span className={`inline-block px-2 py-1 rounded text-xs font-medium ${
                      item.status === 'yes' ? 'bg-green-100 text-green-800' :
                      item.status === 'no' ? 'bg-red-100 text-red-800' :
                      'bg-gray-100 text-gray-800'
                    }`}>
                      {item.status === 'yes' ? 'Compliant' : 
                       item.status === 'no' ? 'Non-Compliant' : 'N/A'}
                    </span>
                  </td>
                  <td className="border border-gray-300 p-2 text-xs">
                    {item.whyMatters}
                  </td>
                  <td className="border border-gray-300 p-2 text-xs">
                    {item.status === 'na' ? item.justification : item.evidence || '-'}
                  </td>
                  <td className="border border-gray-300 p-2 text-xs">
                    {item.status === 'no' ? item.recommendation : '-'}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ))}

      {/* Key Obligations Reference */}
      <div className="mt-8 p-4 border rounded bg-gray-50 print-page">
        <h2 className="text-xl font-bold text-brand mb-4">Key Obligations Reference</h2>
        <div className="space-y-2 text-sm">
          <p><strong>Logging Retention:</strong> Maintain security logs for at least 12 months</p>
          <p><strong>Backup & Recovery:</strong> Regular backups with documented restore testing</p>
          <p><strong>Multi-Factor Authentication:</strong> Required for privileged and administrative accounts</p>
          <p><strong>Risk Assessment:</strong> Conduct regular risk assessments and document results</p>
          <p><strong>Incident Response:</strong> Implement and maintain incident response procedures</p>
          <p><strong>Security Awareness:</strong> Provide regular cybersecurity training to staff</p>
        </div>
        
        <div className="mt-4 text-xs text-gray-500">
          <p><strong>Legal Basis:</strong> Republic of Moldova Cybersecurity Law</p>
          <p><strong>Disclaimer:</strong> This report is for informational purposes only and does not constitute legal advice.</p>
          <p><strong>Generated by:</strong> CyberCare Compliance Assistant - Demo Version</p>
        </div>
      </div>
    </div>
  );
}