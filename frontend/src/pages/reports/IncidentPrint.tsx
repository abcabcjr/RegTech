import { useEffect, useState } from "react";
import { useSearchParams } from "react-router-dom";
import { useIncidentStore } from "@/lib/incidents/store";
import { IncidentRecord } from "@/lib/incidents/schema";

export default function IncidentPrint() {
  const [searchParams] = useSearchParams();
  const incidentId = searchParams.get("id");
  const { incidents, loadIncidents } = useIncidentStore();
  const [incident, setIncident] = useState<IncidentRecord | null>(null);

  useEffect(() => {
    loadIncidents();
  }, [loadIncidents]);

  useEffect(() => {
    if (incidentId && incidents.length > 0) {
      const foundIncident = incidents.find(i => i.id === incidentId);
      setIncident(foundIncident || null);
    }
  }, [incidentId, incidents]);

  if (!incident) {
    return <div>Loading incident...</div>;
  }

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
        <h1 className="text-3xl font-bold text-brand mb-2">Cybersecurity Incident Report</h1>
        <div className="text-sm text-gray-600">
          <p>Incident ID: {incident.id}</p>
          <p>Report Generated: {new Date().toLocaleDateString()}</p>
          <p>Report Stage: {incident.stage.toUpperCase()}</p>
        </div>
      </div>

      {/* Incident Overview */}
      <div className="mb-8">
        <h2 className="text-2xl font-bold text-brand mb-4">Incident Overview</h2>
        <div className="grid grid-cols-2 gap-4">
          <div className="space-y-2">
            <div><strong>Created:</strong> {new Date(incident.createdAt).toLocaleString()}</div>
            <div><strong>Last Updated:</strong> {new Date(incident.updatedAt).toLocaleString()}</div>
            <div><strong>Cause Category:</strong> {incident.causeTag.replace('_', ' ')}</div>
          </div>
          <div className="space-y-2">
            <div><strong>Significant Incident:</strong> {incident.significant ? 'Yes' : 'No'}</div>
            <div><strong>Recurring Incident:</strong> {incident.recurring ? 'Yes' : 'No'}</div>
            <div><strong>Current Stage:</strong> {incident.stage}</div>
          </div>
        </div>
      </div>

      {/* Initial Report */}
      {incident.details.initial && (
        <div className="mb-8">
          <h2 className="text-xl font-bold text-brand mb-4">Initial Report</h2>
          <div className="space-y-4">
            <div>
              <h3 className="font-semibold mb-2">Incident Summary</h3>
              <p className="text-sm bg-gray-50 p-3 rounded border">
                {incident.details.initial.summary}
              </p>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <h3 className="font-semibold mb-2">Detection Time</h3>
                <p className="text-sm">{incident.details.initial.detectedAt}</p>
              </div>
              <div>
                <h3 className="font-semibold mb-2">Assessment Flags</h3>
                <div className="text-sm space-y-1">
                  <div>Suspected Illegal Activity: {incident.details.initial.suspectedIllegal ? 'Yes' : 'No'}</div>
                  <div>Possible Cross-Border Effects: {incident.details.initial.possibleCrossBorder ? 'Yes' : 'No'}</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Update Report */}
      {incident.details.update && incident.stage !== "initial" && (
        <div className="mb-8">
          <h2 className="text-xl font-bold text-brand mb-4">Impact Assessment</h2>
          <div className="space-y-4">
            <div className="grid grid-cols-3 gap-4">
              <div className="text-center p-3 border rounded">
                <div className="text-lg font-bold">{incident.usersAffected || 0}</div>
                <div className="text-sm text-gray-600">Users Affected</div>
              </div>
              <div className="text-center p-3 border rounded">
                <div className="text-lg font-bold">{incident.downtimeMinutes || 0}</div>
                <div className="text-sm text-gray-600">Downtime (min)</div>
              </div>
              <div className="text-center p-3 border rounded">
                <div className="text-lg font-bold">{incident.financialImpactPct || 0}%</div>
                <div className="text-sm text-gray-600">Financial Impact</div>
              </div>
            </div>
            
            {incident.details.update.gravity && (
              <div>
                <h3 className="font-semibold mb-2">Incident Gravity</h3>
                <p className="text-sm">{incident.details.update.gravity}</p>
              </div>
            )}
            
            {incident.details.update.impact && (
              <div>
                <h3 className="font-semibold mb-2">Impact Description</h3>
                <p className="text-sm bg-gray-50 p-3 rounded border">
                  {incident.details.update.impact}
                </p>
              </div>
            )}
            
            {incident.details.update.corrections && (
              <div>
                <h3 className="font-semibold mb-2">Interim Actions Taken</h3>
                <p className="text-sm bg-gray-50 p-3 rounded border">
                  {incident.details.update.corrections}
                </p>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Final Report */}
      {incident.details.final && incident.stage === "final" && (
        <div className="mb-8">
          <h2 className="text-xl font-bold text-brand mb-4">Final Analysis & Resolution</h2>
          <div className="space-y-4">
            {incident.details.final.rootCause && (
              <div>
                <h3 className="font-semibold mb-2">Root Cause Analysis</h3>
                <p className="text-sm bg-gray-50 p-3 rounded border">
                  {incident.details.final.rootCause}
                </p>
              </div>
            )}
            
            {incident.details.final.mitigations && (
              <div>
                <h3 className="font-semibold mb-2">Mitigations Implemented</h3>
                <p className="text-sm bg-gray-50 p-3 rounded border">
                  {incident.details.final.mitigations}
                </p>
              </div>
            )}
            
            {incident.details.final.crossBorderDesc && (
              <div>
                <h3 className="font-semibold mb-2">Cross-Border Effects</h3>
                <p className="text-sm bg-gray-50 p-3 rounded border">
                  {incident.details.final.crossBorderDesc}
                </p>
              </div>
            )}
            
            {incident.details.final.lessons && (
              <div>
                <h3 className="font-semibold mb-2">Lessons Learned</h3>
                <p className="text-sm bg-gray-50 p-3 rounded border">
                  {incident.details.final.lessons}
                </p>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Legal Footer */}
      <div className="mt-8 p-4 border rounded bg-gray-50">
        <div className="text-xs text-gray-500">
          <p><strong>Legal Basis:</strong> Republic of Moldova Cybersecurity Law</p>
          <p><strong>Confidentiality:</strong> This report contains sensitive information and should be handled according to organizational policies.</p>
          <p><strong>Generated by:</strong> CyberCare Incident Management System - Demo Version</p>
        </div>
      </div>
    </div>
  );
}