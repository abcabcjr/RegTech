import { useState, useEffect } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { StatusBadge } from "@/components/ui/status-badge";
import { Badge } from "@/components/ui/badge";
import { useIncidentStore } from "@/lib/incidents/store";
import { IncidentWizard } from "@/components/incidents/incident-wizard";
import { PlusIcon, DocumentTextIcon, ClockIcon } from "@heroicons/react/24/outline";

export default function Incidents() {
  const [wizardOpen, setWizardOpen] = useState(false);
  const { incidents, selectedIncident, loadIncidents, selectIncident, exportIncidentJSON } = useIncidentStore();

  useEffect(() => {
    loadIncidents();
  }, [loadIncidents]);

  const handleNewIncident = () => {
    setWizardOpen(true);
  };

  const handleExportJSON = () => {
    if (selectedIncident) {
      exportIncidentJSON(selectedIncident.id);
    }
  };

  const handlePrintReport = () => {
    if (selectedIncident) {
      const printWindow = window.open(`/reports/incident/print?id=${selectedIncident.id}`, '_blank');
      if (printWindow) {
        printWindow.onload = () => {
          printWindow.print();
        };
      }
    }
  };

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-foreground mb-4">Incident Management</h1>
        <p className="text-muted-foreground mb-6">
          Report and manage cybersecurity incidents through our 3-stage workflow: 
          Initial Report → Update Report → Final Report.
        </p>
      </div>

      <div className="grid lg:grid-cols-3 gap-8">
        {/* Incident List */}
        <div className="lg:col-span-1">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <CardTitle>Incidents</CardTitle>
                <Button onClick={handleNewIncident} size="sm">
                  <PlusIcon className="h-4 w-4 mr-2" />
                  New Incident
                </Button>
              </div>
              <CardDescription>
                {incidents.length} total incidents
              </CardDescription>
            </CardHeader>
            <CardContent>
              {incidents.length === 0 ? (
                <div className="text-center py-8">
                  <DocumentTextIcon className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
                  <p className="text-muted-foreground mb-4">No incidents reported yet</p>
                  <Button onClick={handleNewIncident} variant="outline">
                    Report First Incident
                  </Button>
                </div>
              ) : (
                <div className="space-y-3">
                  {incidents.map((incident) => (
                    <Card 
                      key={incident.id}
                      className={`cursor-pointer transition-colors ${
                        selectedIncident?.id === incident.id ? 'ring-2 ring-brand' : ''
                      }`}
                      onClick={() => selectIncident(incident)}
                    >
                      <CardContent className="p-4">
                        <div className="flex items-start justify-between mb-2">
                          <h3 className="font-medium text-sm">
                            {incident.details.initial?.summary?.substring(0, 50) || "Untitled Incident"}...
                          </h3>
                          <StatusBadge status={incident.stage} />
                        </div>
                        <div className="flex items-center text-xs text-muted-foreground mb-2">
                          <ClockIcon className="h-3 w-3 mr-1" />
                          {new Date(incident.createdAt).toLocaleDateString()}
                        </div>
                        <p className="text-xs text-muted-foreground line-clamp-2">
                          {incident.details.initial?.summary || "No summary available"}
                        </p>
                        <div className="flex items-center justify-between mt-2">
                          <Badge variant="outline" className="text-xs">
                            {incident.causeTag.replace('_', ' ')}
                          </Badge>
                          {incident.significant && (
                            <Badge variant="destructive" className="text-xs">
                              Significant
                            </Badge>
                          )}
                        </div>
                      </CardContent>
                    </Card>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </div>

        {/* Incident Details / Wizard */}
        <div className="lg:col-span-2">
          {selectedIncident ? (
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center justify-between">
                  {selectedIncident.details.initial?.summary?.substring(0, 60) || "Incident Details"}
                  <StatusBadge status={selectedIncident.stage} />
                </CardTitle>
                <CardDescription>
                  Created {new Date(selectedIncident.createdAt).toLocaleDateString()} • 
                  Last updated {new Date(selectedIncident.updatedAt).toLocaleDateString()}
                </CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-6">
                  {/* Initial Report */}
                  <div>
                    <h3 className="font-semibold text-lg mb-3">Initial Report</h3>
                    <div className="grid gap-4">
                      <div>
                        <label className="text-sm font-medium text-muted-foreground">Summary</label>
                        <p className="text-sm">{selectedIncident.details.initial?.summary || "No summary"}</p>
                      </div>
                      <div className="grid grid-cols-2 gap-4">
                        <div>
                          <label className="text-sm font-medium text-muted-foreground">Detected At</label>
                          <p className="text-sm">{selectedIncident.details.initial?.detectedAt || "Not specified"}</p>
                        </div>
                        <div>
                          <label className="text-sm font-medium text-muted-foreground">Cause</label>
                          <p className="text-sm">{selectedIncident.causeTag.replace('_', ' ')}</p>
                        </div>
                      </div>
                      <div className="grid grid-cols-2 gap-4">
                        <div className="flex items-center space-x-2">
                          <span className="text-sm font-medium text-muted-foreground">Suspected Illegal:</span>
                          <Badge variant={selectedIncident.details.initial?.suspectedIllegal ? "destructive" : "outline"}>
                            {selectedIncident.details.initial?.suspectedIllegal ? "Yes" : "No"}
                          </Badge>
                        </div>
                        <div className="flex items-center space-x-2">
                          <span className="text-sm font-medium text-muted-foreground">Cross-Border:</span>
                          <Badge variant={selectedIncident.details.initial?.possibleCrossBorder ? "destructive" : "outline"}>
                            {selectedIncident.details.initial?.possibleCrossBorder ? "Possible" : "No"}
                          </Badge>
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* Update Report */}
                  {selectedIncident.stage !== "initial" && (
                    <div>
                      <h3 className="font-semibold text-lg mb-3">Update Report</h3>
                      <div className="grid gap-4">
                        <div className="grid grid-cols-3 gap-4">
                          <div>
                            <label className="text-sm font-medium text-muted-foreground">Users Affected</label>
                            <p className="text-sm">{selectedIncident.usersAffected || 0}</p>
                          </div>
                          <div>
                            <label className="text-sm font-medium text-muted-foreground">Downtime (min)</label>
                            <p className="text-sm">{selectedIncident.downtimeMinutes || 0}</p>
                          </div>
                          <div>
                            <label className="text-sm font-medium text-muted-foreground">Financial Impact %</label>
                            <p className="text-sm">{selectedIncident.financialImpactPct || 0}%</p>
                          </div>
                        </div>
                        <div>
                          <label className="text-sm font-medium text-muted-foreground">Gravity</label>
                          <p className="text-sm">{selectedIncident.details.update?.gravity || "Not assessed"}</p>
                        </div>
                        <div>
                          <label className="text-sm font-medium text-muted-foreground">Impact</label>
                          <p className="text-sm">{selectedIncident.details.update?.impact || "Not described"}</p>
                        </div>
                        <div>
                          <label className="text-sm font-medium text-muted-foreground">Interim Actions</label>
                          <p className="text-sm">{selectedIncident.details.update?.corrections || "No actions documented"}</p>
                        </div>
                      </div>
                    </div>
                  )}

                  {/* Final Report */}
                  {selectedIncident.stage === "final" && (
                    <div>
                      <h3 className="font-semibold text-lg mb-3">Final Report</h3>
                      <div className="grid gap-4">
                        <div>
                          <label className="text-sm font-medium text-muted-foreground">Root Cause</label>
                          <p className="text-sm">{selectedIncident.details.final?.rootCause || "Not determined"}</p>
                        </div>
                        <div>
                          <label className="text-sm font-medium text-muted-foreground">Gravity</label>
                          <Badge variant={selectedIncident.details.final?.gravity === "critical" ? "destructive" : "outline"}>
                            {selectedIncident.details.final?.gravity || "Not assessed"}
                          </Badge>
                        </div>
                        <div>
                          <label className="text-sm font-medium text-muted-foreground">Mitigations</label>
                          <p className="text-sm">{selectedIncident.details.final?.mitigations || "Not documented"}</p>
                        </div>
                        <div>
                          <label className="text-sm font-medium text-muted-foreground">Cross-Border Effects</label>
                          <p className="text-sm">{selectedIncident.details.final?.crossBorderDesc || "None identified"}</p>
                        </div>
                        <div>
                          <label className="text-sm font-medium text-muted-foreground">Lessons Learned</label>
                          <p className="text-sm">{selectedIncident.details.final?.lessons || "Not documented"}</p>
                        </div>
                      </div>
                    </div>
                  )}

                  {/* Actions */}
                  <div className="flex space-x-2 pt-4 border-t">
                    <Button variant="outline" size="sm" onClick={handleExportJSON}>
                      Export JSON
                    </Button>
                    <Button variant="outline" size="sm" onClick={handlePrintReport}>
                      Print Report
                    </Button>
                  </div>
                </div>
              </CardContent>
            </Card>
          ) : (
            <Card>
              <CardContent className="p-12 text-center">
                <DocumentTextIcon className="h-16 w-16 text-muted-foreground mx-auto mb-4" />
                <h3 className="text-lg font-semibold mb-2">Select an Incident</h3>
                <p className="text-muted-foreground mb-6">
                  Choose an incident from the list to view details, or create a new incident report.
                </p>
                <Button onClick={handleNewIncident}>
                  <PlusIcon className="h-4 w-4 mr-2" />
                  Report New Incident
                </Button>
              </CardContent>
            </Card>
          )}
        </div>
      </div>

      <IncidentWizard open={wizardOpen} onOpenChange={setWizardOpen} />
    </div>
  );
}