import { Link } from "react-router-dom";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { ProgressBar } from "@/components/ui/progress-bar";
import { Badge } from "@/components/ui/badge";
import { 
  CheckCircleIcon, 
  ExclamationTriangleIcon, 
  DocumentTextIcon,
  ShieldCheckIcon,
  ArrowRightIcon
} from "@heroicons/react/24/outline";
import { loadChecklistState, loadIncidents } from "@/lib/persistence";
import { mockFindings, severityColors } from "@/lib/mock-findings";
import { useEffect, useState } from "react";

const Index = () => {
  const [checklistState, setChecklistState] = useState(() => loadChecklistState());
  const [incidents, setIncidents] = useState(() => loadIncidents());

  useEffect(() => {
    setChecklistState(loadChecklistState());
    setIncidents(loadIncidents());
  }, []);

  const recentFindings = mockFindings.slice(0, 3);

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      {/* Hero Section */}
      <div className="text-center mb-12">
        <div className="flex justify-center mb-4">
          <ShieldCheckIcon className="h-16 w-16 text-primary" />
        </div>
        <h1 className="text-4xl font-bold text-foreground mb-4">
          Welcome to CyberCare
        </h1>
        <p className="text-xl text-muted-foreground max-w-3xl mx-auto mb-6">
          Help Moldovan businesses comply with the Cybersecurity Law by turning complex requirements 
          into plain-language checklists and an easy, 3-step incident reporting workflow.
        </p>
        <div className="flex flex-wrap justify-center gap-2 mb-8">
          <Badge variant="outline" className="text-sm">Compliance Records</Badge>
          <Badge variant="outline" className="text-sm">Incident Reporting</Badge>
          <Badge variant="outline" className="text-sm">Evidence Management</Badge>
        </div>
      </div>

      {/* How It Works */}
      <div className="mb-12">
        <h2 className="text-2xl font-semibold text-center mb-8">How CyberCare Works</h2>
        <div className="grid md:grid-cols-3 gap-6">
          <Card>
            <CardHeader className="text-center">
              <CheckCircleIcon className="h-8 w-8 text-primary mx-auto mb-2" />
              <CardTitle className="text-lg">1. Compliance Checklist</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-muted-foreground text-center">
                Track your compliance with plain-language checklists, upload evidence, and monitor your progress.
              </p>
            </CardContent>
          </Card>
          
          <Card>
            <CardHeader className="text-center">
              <ExclamationTriangleIcon className="h-8 w-8 text-warning mx-auto mb-2" />
              <CardTitle className="text-lg">2. Incident Reporting</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-muted-foreground text-center">
                Report incidents through our 3-stage workflow: Initial → Update → Final reports.
              </p>
            </CardContent>
          </Card>
          
          <Card>
            <CardHeader className="text-center">
              <DocumentTextIcon className="h-8 w-8 text-success mx-auto mb-2" />
              <CardTitle className="text-lg">3. Generate Reports</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-muted-foreground text-center">
                Export compliance and incident reports for audits and regulatory submissions.
              </p>
            </CardContent>
          </Card>
        </div>
      </div>

      {/* Dashboard Overview */}
      <div className="grid lg:grid-cols-2 gap-8 mb-8">
        {/* Compliance Overview */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center">
              <CheckCircleIcon className="h-5 w-5 mr-2" />
              Compliance Overview
            </CardTitle>
          </CardHeader>
          <CardContent>
            <ProgressBar 
              value={checklistState.complianceScore} 
              className="mb-4"
            />
            <div className="flex justify-between items-center mb-4">
              <span className="text-sm text-muted-foreground">
                {checklistState.sections.reduce((acc, section) => 
                  acc + section.items.filter(item => item.status === "yes").length, 0
                )} compliant items
              </span>
              <span className="text-sm text-muted-foreground">
                {checklistState.sections.reduce((acc, section) => 
                  acc + section.items.filter(item => item.required).length, 0
                )} total required
              </span>
            </div>
            <Link to="/checklist">
              <Button className="w-full">
                View Checklist
                <ArrowRightIcon className="h-4 w-4 ml-2" />
              </Button>
            </Link>
          </CardContent>
        </Card>

        {/* Recent Incidents */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center">
              <ExclamationTriangleIcon className="h-5 w-5 mr-2" />
              Incident Center
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3 mb-4">
              {incidents.length > 0 ? (
                incidents.slice(0, 3).map((incident) => (
                  <div key={incident.id} className="flex items-center justify-between p-2 bg-muted/50 rounded">
                    <div>
                      <p className="font-medium text-sm">{incident.title}</p>
                      <p className="text-xs text-muted-foreground">
                        {new Date(incident.createdAt).toLocaleDateString()}
                      </p>
                    </div>
                    <Badge variant="outline">{incident.stage}</Badge>
                  </div>
                ))
              ) : (
                <p className="text-muted-foreground text-center py-4">
                  No incidents reported yet
                </p>
              )}
            </div>
            <Link to="/incidents">
              <Button className="w-full">
                Manage Incidents
                <ArrowRightIcon className="h-4 w-4 ml-2" />
              </Button>
            </Link>
          </CardContent>
        </Card>
      </div>

      {/* Mini Audit Findings */}
      <Card>
        <CardHeader>
          <CardTitle>Mini-Audit Findings (Demo)</CardTitle>
          <CardDescription>
            Sample security findings to demonstrate reporting capabilities
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid md:grid-cols-3 gap-4 mb-4">
            {recentFindings.map((finding) => (
              <div key={finding.id} className="p-3 border rounded-md">
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm font-medium">{finding.title}</span>
                  <span className={`text-xs px-2 py-1 rounded ${severityColors[finding.severity]}`}>
                    {finding.severity}
                  </span>
                </div>
                <p className="text-xs text-muted-foreground">{finding.summary}</p>
              </div>
            ))}
          </div>
          <p className="text-xs text-muted-foreground mb-4">
            Note: This is demo data only. No actual security scans are performed.
          </p>
          <Link to="/reports">
            <Button variant="outline" className="w-full">
              View Full Report
              <ArrowRightIcon className="h-4 w-4 ml-2" />
            </Button>
          </Link>
        </CardContent>
      </Card>
    </div>
  );
};

export default Index;
