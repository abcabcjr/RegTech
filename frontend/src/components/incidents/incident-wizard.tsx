import { useState } from "react";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Checkbox } from "@/components/ui/checkbox";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { useIncidentStore } from "@/lib/incidents/store";
import { CauseTag, InitialDetails, UpdateDetails, FinalDetails } from "@/lib/incidents/schema";
import { CheckIcon, ChevronLeftIcon, ChevronRightIcon } from "@heroicons/react/24/outline";
import { useToast } from "@/hooks/use-toast";

interface IncidentWizardProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

const STEPS = [
  { id: 1, title: "Initial Report", description: "Basic incident details" },
  { id: 2, title: "Update Report", description: "Impact and scope analysis" },
  { id: 3, title: "Final Report", description: "Root cause and mitigation" },
];

const CAUSE_TAGS: { value: CauseTag; label: string }[] = [
  { value: "phishing", label: "Phishing Attack" },
  { value: "vuln_exploit", label: "Vulnerability Exploitation" },
  { value: "misconfig", label: "Misconfiguration" },
  { value: "malware", label: "Malware" },
  { value: "other", label: "Other" },
];

export function IncidentWizard({ open, onOpenChange }: IncidentWizardProps) {
  const [currentStep, setCurrentStep] = useState(1);
  const [incidentId, setIncidentId] = useState<string | null>(null);
  const { toast } = useToast();
  
  // Form states
  const [initialData, setInitialData] = useState<Partial<InitialDetails>>({});
  const [updateData, setUpdateData] = useState<Partial<UpdateDetails>>({});
  const [finalData, setFinalData] = useState<Partial<FinalDetails>>({});
  const [basicData, setBasicData] = useState({
    causeTag: "other" as CauseTag,
    significant: false,
    recurring: false,
    usersAffected: 0,
    downtimeMinutes: 0,
    financialImpactPct: 0,
  });

  const { createIncident, setStageData, updateIncident } = useIncidentStore();

  const resetForm = () => {
    setCurrentStep(1);
    setIncidentId(null);
    setInitialData({});
    setUpdateData({});
    setFinalData({});
    setBasicData({
      causeTag: "other" as CauseTag,
      significant: false,
      recurring: false,
      usersAffected: 0,
      downtimeMinutes: 0,
      financialImpactPct: 0,
    });
  };

  const handleNext = () => {
    if (currentStep === 1) {
      // Validate and save initial data
      if (!initialData.summary || !initialData.detectedAt) {
        toast({
          title: "Missing Information",
          description: "Please fill in all required fields.",
          variant: "destructive",
        });
        return;
      }

      let id = incidentId;
      if (!id) {
        const incident = createIncident(basicData);
        id = incident.id;
        setIncidentId(id);
      }
      
      setStageData(id, "initial", initialData as InitialDetails);
      setCurrentStep(2);
    } else if (currentStep === 2) {
      // Save update data and move to final
      if (incidentId) {
        updateIncident(incidentId, basicData);
        if (updateData.gravity || updateData.impact) {
          setStageData(incidentId, "update", updateData as UpdateDetails);
        }
      }
      setCurrentStep(3);
    } else if (currentStep === 3) {
      // Save final data and close
      if (incidentId) {
        if (finalData.rootCause || finalData.mitigations) {
          setStageData(incidentId, "final", finalData as FinalDetails);
        }
      }
      toast({
        title: "Incident Created",
        description: "The incident has been successfully reported.",
      });
      onOpenChange(false);
      resetForm();
    }
  };

  const handlePrevious = () => {
    if (currentStep > 1) {
      setCurrentStep(currentStep - 1);
    }
  };

  const handleClose = () => {
    onOpenChange(false);
    resetForm();
  };

  return (
    <Dialog open={open} onOpenChange={handleClose}>
      <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Report Incident</DialogTitle>
        </DialogHeader>

        {/* Step indicator */}
        <div className="flex items-center space-x-4 mb-6">
          {STEPS.map((step, index) => (
            <div key={step.id} className="flex items-center">
              <div className={`flex items-center justify-center w-8 h-8 rounded-full border-2 ${
                currentStep >= step.id
                  ? 'bg-brand border-brand text-white'
                  : 'border-gray-300 text-gray-500'
              }`}>
                {currentStep > step.id ? (
                  <CheckIcon className="w-4 h-4" />
                ) : (
                  step.id
                )}
              </div>
              <div className="ml-2">
                <div className="text-sm font-medium">{step.title}</div>
                <div className="text-xs text-muted-foreground">{step.description}</div>
              </div>
              {index < STEPS.length - 1 && (
                <ChevronRightIcon className="w-4 h-4 text-gray-400 mx-4" />
              )}
            </div>
          ))}
        </div>

        {/* Step 1: Initial Report */}
        {currentStep === 1 && (
          <Card>
            <CardHeader>
              <CardTitle>Initial Incident Report</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <Label htmlFor="summary">Incident Summary *</Label>
                <Textarea
                  id="summary"
                  placeholder="Brief description of what happened..."
                  value={initialData.summary || ''}
                  onChange={(e) => setInitialData({ ...initialData, summary: e.target.value })}
                />
              </div>
              
              <div>
                <Label htmlFor="detectedAt">Detected At *</Label>
                <Input
                  id="detectedAt"
                  type="datetime-local"
                  value={initialData.detectedAt || ''}
                  onChange={(e) => setInitialData({ ...initialData, detectedAt: e.target.value })}
                />
              </div>

              <div>
                <Label htmlFor="causeTag">Suspected Cause</Label>
                <Select value={basicData.causeTag} onValueChange={(value) => setBasicData({ ...basicData, causeTag: value as CauseTag })}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {CAUSE_TAGS.map((cause) => (
                      <SelectItem key={cause.value} value={cause.value}>
                        {cause.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div className="flex items-center space-x-4">
                <div className="flex items-center space-x-2">
                  <Checkbox
                    id="suspectedIllegal"
                    checked={initialData.suspectedIllegal || false}
                    onCheckedChange={(checked) => setInitialData({ ...initialData, suspectedIllegal: !!checked })}
                  />
                  <Label htmlFor="suspectedIllegal">Suspected illegal activity</Label>
                </div>
                
                <div className="flex items-center space-x-2">
                  <Checkbox
                    id="possibleCrossBorder"
                    checked={initialData.possibleCrossBorder || false}
                    onCheckedChange={(checked) => setInitialData({ ...initialData, possibleCrossBorder: !!checked })}
                  />
                  <Label htmlFor="possibleCrossBorder">Possible cross-border effects</Label>
                </div>
              </div>
            </CardContent>
          </Card>
        )}

        {/* Step 2: Update Report */}
        {currentStep === 2 && (
          <Card>
            <CardHeader>
              <CardTitle>Impact Assessment</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-3 gap-4">
                <div>
                  <Label htmlFor="usersAffected">Users Affected</Label>
                  <Input
                    id="usersAffected"
                    type="number"
                    min="0"
                    value={basicData.usersAffected}
                    onChange={(e) => setBasicData({ ...basicData, usersAffected: parseInt(e.target.value) || 0 })}
                  />
                </div>
                
                <div>
                  <Label htmlFor="downtimeMinutes">Downtime (minutes)</Label>
                  <Input
                    id="downtimeMinutes"
                    type="number"
                    min="0"
                    value={basicData.downtimeMinutes}
                    onChange={(e) => setBasicData({ ...basicData, downtimeMinutes: parseInt(e.target.value) || 0 })}
                  />
                </div>
                
                <div>
                  <Label htmlFor="financialImpactPct">Financial Impact (%)</Label>
                  <Input
                    id="financialImpactPct"
                    type="number"
                    min="0"
                    max="100"
                    step="0.1"
                    value={basicData.financialImpactPct}
                    onChange={(e) => setBasicData({ ...basicData, financialImpactPct: parseFloat(e.target.value) || 0 })}
                  />
                </div>
              </div>

              <div>
                <Label htmlFor="gravity">Incident Gravity</Label>
                <Select value={updateData.gravity || ''} onValueChange={(value) => setUpdateData({ ...updateData, gravity: value })}>
                  <SelectTrigger>
                    <SelectValue placeholder="Select gravity level" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="low">Low</SelectItem>
                    <SelectItem value="medium">Medium</SelectItem>
                    <SelectItem value="high">High</SelectItem>
                    <SelectItem value="critical">Critical</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div>
                <Label htmlFor="impact">Impact Description</Label>
                <Textarea
                  id="impact"
                  placeholder="Describe the impact on systems and operations..."
                  value={updateData.impact || ''}
                  onChange={(e) => setUpdateData({ ...updateData, impact: e.target.value })}
                />
              </div>

              <div>
                <Label htmlFor="corrections">Interim Actions Taken</Label>
                <Textarea
                  id="corrections"
                  placeholder="What immediate actions were taken to contain the incident..."
                  value={updateData.corrections || ''}
                  onChange={(e) => setUpdateData({ ...updateData, corrections: e.target.value })}
                />
              </div>

              <div className="flex items-center space-x-4">
                <div className="flex items-center space-x-2">
                  <Checkbox
                    id="significant"
                    checked={basicData.significant}
                    onCheckedChange={(checked) => setBasicData({ ...basicData, significant: !!checked })}
                  />
                  <Label htmlFor="significant">Mark as significant incident</Label>
                </div>
                
                <div className="flex items-center space-x-2">
                  <Checkbox
                    id="recurring"
                    checked={basicData.recurring}
                    onCheckedChange={(checked) => setBasicData({ ...basicData, recurring: !!checked })}
                  />
                  <Label htmlFor="recurring">Mark as recurring incident</Label>
                </div>
              </div>
            </CardContent>
          </Card>
        )}

        {/* Step 3: Final Report */}
        {currentStep === 3 && (
          <Card>
            <CardHeader>
              <CardTitle>Final Report</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <Label htmlFor="rootCause">Root Cause Analysis</Label>
                <Textarea
                  id="rootCause"
                  placeholder="What was the underlying cause of this incident..."
                  value={finalData.rootCause || ''}
                  onChange={(e) => setFinalData({ ...finalData, rootCause: e.target.value })}
                />
              </div>

              <div>
                <Label htmlFor="mitigations">Mitigations Implemented</Label>
                <Textarea
                  id="mitigations"
                  placeholder="What measures were put in place to prevent recurrence..."
                  value={finalData.mitigations || ''}
                  onChange={(e) => setFinalData({ ...finalData, mitigations: e.target.value })}
                />
              </div>

              <div>
                <Label htmlFor="lessons">Lessons Learned</Label>
                <Textarea
                  id="lessons"
                  placeholder="Key takeaways and improvements for the future..."
                  value={finalData.lessons || ''}
                  onChange={(e) => setFinalData({ ...finalData, lessons: e.target.value })}
                />
              </div>

              <div>
                <Label htmlFor="crossBorderDesc">Cross-Border Effects (if any)</Label>
                <Textarea
                  id="crossBorderDesc"
                  placeholder="Describe any international implications..."
                  value={finalData.crossBorderDesc || ''}
                  onChange={(e) => setFinalData({ ...finalData, crossBorderDesc: e.target.value })}
                />
              </div>
            </CardContent>
          </Card>
        )}

        {/* Navigation buttons */}
        <div className="flex justify-between pt-4">
          <Button
            variant="outline"
            onClick={handlePrevious}
            disabled={currentStep === 1}
          >
            <ChevronLeftIcon className="w-4 h-4 mr-2" />
            Previous
          </Button>
          
          <div className="flex space-x-2">
            <Button variant="outline" onClick={handleClose}>
              Cancel
            </Button>
            <Button onClick={handleNext} className="bg-brand text-white hover:bg-brand/90">
              {currentStep === 3 ? 'Complete Report' : 'Next'}
              {currentStep < 3 && <ChevronRightIcon className="w-4 h-4 ml-2" />}
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}