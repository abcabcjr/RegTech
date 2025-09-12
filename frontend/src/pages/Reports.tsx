import { useState, useEffect } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Badge } from "@/components/ui/badge";
import { StatusBadge } from "@/components/ui/status-badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { ChecklistState, IncidentRecord, OrganizationProfile } from "@/lib/types";
import { loadChecklistState, loadIncidents, loadOrganizationProfile } from "@/lib/persistence";
import { mockFindings, severityColors } from "@/lib/mock-findings";
import { 
  PrinterIcon, 
  DocumentArrowDownIcon, 
  ShieldCheckIcon,
  ExclamationTriangleIcon,
  InformationCircleIcon
} from "@heroicons/react/24/outline";

export default function Reports() {
  const [checklistState, setChecklistState] = useState<ChecklistState>(() => loadChecklistState());
  const [incidents, setIncidents] = useState<IncidentRecord[]>([]);
  const [organization, setOrganization] = useState<OrganizationProfile>(() => loadOrganizationProfile());
  const [selectedIncident, setSelectedIncident] = useState<string>("");

  useEffect(() => {
    setChecklistState(loadChecklistState());
    setIncidents(loadIncidents());
    setOrganization(loadOrganizationProfile());
  }, []);

  const handlePrint = () => {
    window.print();
  };

  const handleExportJSON = (type: "compliance" | "incident") => {
    let data: any;
    let filename: string;

    if (type === "compliance") {
      data = { organization, checklist: checklistState, scanFindings: mockFindings };
      filename = "compliance-report.json";
    } else {
      const incident = incidents.find(i => i.id === selectedIncident);
      data = { organization, incident };
      filename = `incident-report-${selectedIncident}.json`;
    }

    const blob = new Blob([JSON.stringify(data, null, 2)], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  };

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-foreground mb-4">Reports</h1>
        <p className="text-muted-foreground mb-6">
          Generate and export compliance and incident reports for audits and regulatory submissions.
        </p>
        
        <div className="bg-blue-50 border border-blue-200 rounded-md p-4 mb-6">
          <div className="flex items-start">
            <InformationCircleIcon className="h-5 w-5 text-blue-500 mt-0.5 mr-3 flex-shrink-0" />
            <div>
              <p className="text-sm font-medium text-blue-800">Demo Mode</p>
              <p className="text-sm text-blue-700">
                This is a demonstration version. No data is sent anywhere and reports are for display purposes only.
              </p>
            </div>
          </div>
        </div>
      </div>

      <Tabs defaultValue="compliance" className="w-full">
        <TabsList className="grid w-full grid-cols-2 mb-8">
          <TabsTrigger value="compliance" className="flex items-center">
            <ShieldCheckIcon className="h-4 w-4 mr-2" />
            Compliance Report
          </TabsTrigger>
          <TabsTrigger value="incident" className="flex items-center">
            <ExclamationTriangleIcon className="h-4 w-4 mr-2" />
            Incident Report
          </TabsTrigger>
        </TabsList>

        {/* Compliance Report */}
        <TabsContent value="compliance">
          <div className="space-y-6">
            <div className="flex justify-between items-center">
              <h2 className="text-2xl font-semibold">Compliance Report Preview</h2>
              <div className="flex space-x-2">
                <Button variant="outline" onClick={() => handleExportJSON("compliance")}>
                  <DocumentArrowDownIcon className="h-4 w-4 mr-2" />
                  Export JSON
                </Button>
                <Button onClick={handlePrint}>
                  <PrinterIcon className="h-4 w-4 mr-2" />
                  Print / Save PDF
                </Button>
              </div>
            </div>

            <div className="print:shadow-none">
              {/* Organization Info */}
              <Card className="mb-6">
                <CardHeader>
                  <CardTitle>Organization Information</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="text-sm font-medium text-muted-foreground">Organization Name</label>
                      <p className="text-sm">{organization.name || "Not specified"}</p>
                    </div>
                    <div>
                      <label className="text-sm font-medium text-muted-foreground">Sector</label>
                      <p className="text-sm">{organization.sector || "Not specified"}</p>
                    </div>
                    <div>
                      <label className="text-sm font-medium text-muted-foreground">Previous Year Turnover</label>
                      <p className="text-sm">{organization.turnoverPrevYear || 0} EUR</p>
                    </div>
                    <div>
                      <label className="text-sm font-medium text-muted-foreground">Report Generated</label>
                      <p className="text-sm">{new Date().toLocaleDateString()}</p>
                    </div>
                  </div>
                </CardContent>
              </Card>

              {/* Compliance Summary */}
              <Card className="mb-6">
                <CardHeader>
                  <CardTitle>Compliance Summary</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="grid grid-cols-3 gap-4 mb-4">
                    <div className="text-center">
                      <div className="text-2xl font-bold text-success">
                        {checklistState.sections.reduce((acc, section) => 
                          acc + section.items.filter(item => item.status === "yes").length, 0
                        )}
                      </div>
                      <p className="text-sm text-muted-foreground">Compliant</p>
                    </div>
                    <div className="text-center">
                      <div className="text-2xl font-bold text-destructive">
                        {checklistState.sections.reduce((acc, section) => 
                          acc + section.items.filter(item => item.status === "no").length, 0
                        )}
                      </div>
                      <p className="text-sm text-muted-foreground">Non-Compliant</p>
                    </div>
                    <div className="text-center">
                      <div className="text-2xl font-bold text-muted-foreground">
                        {checklistState.sections.reduce((acc, section) => 
                          acc + section.items.filter(item => item.status === "na").length, 0
                        )}
                      </div>
                      <p className="text-sm text-muted-foreground">Not Applicable</p>
                    </div>
                  </div>
                  <div className="text-center">
                    <div className="text-3xl font-bold text-primary mb-2">
                      {checklistState.complianceScore}%
                    </div>
                    <p className="text-muted-foreground">Overall Compliance Score</p>
                  </div>
                </CardContent>
              </Card>

              {/* Checklist Details */}
              {checklistState.sections.map((section) => (
                <Card key={section.id} className="mb-4">
                  <CardHeader>
                    <CardTitle className="text-lg">{section.title}</CardTitle>
                  </CardHeader>
                  <CardContent>
                    <div className="space-y-3">
                      {section.items.map((item) => (
                        <div key={item.id} className="flex items-center justify-between p-3 border rounded">
                          <div className="flex-1">
                            <p className="font-medium text-sm">{item.title}</p>
                            {item.evidence && (
                              <p className="text-xs text-muted-foreground">Evidence: {item.evidence}</p>
                            )}
                            {item.justification && (
                              <p className="text-xs text-muted-foreground">Justification: {item.justification}</p>
                            )}
                          </div>
                          <StatusBadge status={item.status} />
                        </div>
                      ))}
                    </div>
                  </CardContent>
                </Card>
              ))}

              {/* Security Findings */}
              <Card>
                <CardHeader>
                  <CardTitle>Security Scan Findings (Demo)</CardTitle>
                  <CardDescription>Automated security scan results</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="space-y-3">
                    {mockFindings.map((finding) => (
                      <div key={finding.id} className="flex items-start justify-between p-3 border rounded">
                        <div className="flex-1">
                          <div className="flex items-center space-x-2 mb-1">
                            <p className="font-medium text-sm">{finding.title}</p>
                            <span className={`text-xs px-2 py-1 rounded ${severityColors[finding.severity]}`}>
                              {finding.severity}
                            </span>
                          </div>
                          <p className="text-xs text-muted-foreground mb-1">{finding.summary}</p>
                          {finding.recommendation && (
                            <p className="text-xs text-blue-600">Recommendation: {finding.recommendation}</p>
                          )}
                        </div>
                      </div>
                    ))}
                  </div>
                </CardContent>
              </Card>
            </div>
          </div>
        </TabsContent>

        {/* Incident Report */}
        <TabsContent value="incident">
          <div className="space-y-6">
            <div className="flex justify-between items-center">
              <h2 className="text-2xl font-semibold">Incident Report Preview</h2>
              <div className="flex space-x-2">
                <Select value={selectedIncident} onValueChange={setSelectedIncident}>
                  <SelectTrigger className="w-64">
                    <SelectValue placeholder="Select an incident..." />
                  </SelectTrigger>
                  <SelectContent>
                    {incidents.map((incident) => (
                      <SelectItem key={incident.id} value={incident.id}>
                        {incident.title}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                <Button 
                  variant="outline" 
                  onClick={() => handleExportJSON("incident")}
                  disabled={!selectedIncident}
                >
                  <DocumentArrowDownIcon className="h-4 w-4 mr-2" />
                  Export JSON
                </Button>
                <Button onClick={handlePrint} disabled={!selectedIncident}>
                  <PrinterIcon className="h-4 w-4 mr-2" />
                  Print / Save PDF
                </Button>
              </div>
            </div>

            {selectedIncident ? (
              <div className="print:shadow-none">
                {(() => {
                  const incident = incidents.find(i => i.id === selectedIncident);
                  if (!incident) return null;

                  return (
                    <>
                      {/* Organization Info */}
                      <Card className="mb-6">
                        <CardHeader>
                          <CardTitle>Incident Report</CardTitle>
                          <CardDescription>
                            {incident.title} • Generated {new Date().toLocaleDateString()}
                          </CardDescription>
                        </CardHeader>
                        <CardContent>
                          <div className="grid grid-cols-2 gap-4">
                            <div>
                              <label className="text-sm font-medium text-muted-foreground">Organization</label>
                              <p className="text-sm">{organization.name || "Not specified"}</p>
                            </div>
                            <div>
                              <label className="text-sm font-medium text-muted-foreground">Incident ID</label>
                              <p className="text-sm">{incident.id}</p>
                            </div>
                            <div>
                              <label className="text-sm font-medium text-muted-foreground">Report Stage</label>
                              <StatusBadge status={incident.stage} />
                            </div>
                            <div>
                              <label className="text-sm font-medium text-muted-foreground">Status</label>
                              <StatusBadge status={incident.status} />
                            </div>
                          </div>
                        </CardContent>
                      </Card>

                      {/* Full incident details would be rendered here */}
                      <Card>
                        <CardHeader>
                          <CardTitle>Incident Details</CardTitle>
                        </CardHeader>
                        <CardContent>
                          <div className="space-y-6">
                            <div>
                              <h3 className="font-semibold mb-2">Summary</h3>
                              <p className="text-sm">{incident.summary}</p>
                            </div>
                            
                            <div className="grid grid-cols-2 gap-4">
                              <div>
                                <h3 className="font-semibold mb-2">Detection Time</h3>
                                <p className="text-sm">{incident.detectedAt}</p>
                              </div>
                              <div>
                                <h3 className="font-semibold mb-2">Reported By</h3>
                                <p className="text-sm">{incident.reportedBy}</p>
                              </div>
                            </div>

                            {incident.stage !== "initial" && (
                              <div className="grid grid-cols-3 gap-4">
                                <div>
                                  <h3 className="font-semibold mb-2">Users Affected</h3>
                                  <p className="text-sm">{incident.usersAffected || 0}</p>
                                </div>
                                <div>
                                  <h3 className="font-semibold mb-2">Downtime (minutes)</h3>
                                  <p className="text-sm">{incident.downtimeMinutes || 0}</p>
                                </div>
                                <div>
                                  <h3 className="font-semibold mb-2">Financial Impact</h3>
                                  <p className="text-sm">{incident.financialImpactPct || 0}%</p>
                                </div>
                              </div>
                            )}

                            {incident.stage === "final" && (
                              <>
                                <div>
                                  <h3 className="font-semibold mb-2">Root Cause</h3>
                                  <p className="text-sm">{incident.rootCause}</p>
                                </div>
                                <div>
                                  <h3 className="font-semibold mb-2">Mitigations</h3>
                                  <p className="text-sm">{incident.mitigations}</p>
                                </div>
                                <div>
                                  <h3 className="font-semibold mb-2">Lessons Learned</h3>
                                  <p className="text-sm">{incident.lessonsLearned}</p>
                                </div>
                              </>
                            )}
                          </div>
                        </CardContent>
                      </Card>
                    </>
                  );
                })()}
              </div>
            ) : (
              <Card>
                <CardContent className="p-12 text-center">
                  <ExclamationTriangleIcon className="h-16 w-16 text-muted-foreground mx-auto mb-4" />
                  <h3 className="text-lg font-semibold mb-2">No Incident Selected</h3>
                  <p className="text-muted-foreground">
                    Select an incident from the dropdown above to generate a report.
                  </p>
                </CardContent>
              </Card>
            )}
          </div>
        </TabsContent>
      </Tabs>
    </div>
  );
}