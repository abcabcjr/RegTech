import { useState } from "react";
import { ChecklistItem as ChecklistItemType } from "@/lib/types";
import { StatusBadge } from "@/components/ui/status-badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "@/components/ui/tooltip";
import { 
  InformationCircleIcon, 
  DocumentArrowUpIcon,
  ExclamationCircleIcon 
} from "@heroicons/react/24/outline";

interface ChecklistItemProps {
  item: ChecklistItemType;
  onUpdate: (updates: Partial<ChecklistItemType>) => void;
}

export function ChecklistItem({ item, onUpdate }: ChecklistItemProps) {
  const [isExpanded, setIsExpanded] = useState(false);

  const handleStatusChange = (status: "yes" | "no" | "na") => {
    onUpdate({ 
      status, 
      lastUpdated: new Date().toISOString(),
      // Clear justification if switching to "yes"
      ...(status === "yes" && { justification: "" })
    });
  };

  const handleJustificationChange = (justification: string) => {
    onUpdate({ justification, lastUpdated: new Date().toISOString() });
  };

  const handleEvidenceChange = (evidence: string) => {
    onUpdate({ evidence, lastUpdated: new Date().toISOString() });
  };

  const isDisplayOnly = item.category === "web" || item.category === "vulnerability";

  return (
    <Card className="transition-all duration-200 hover:shadow-md">
      <CardHeader className="pb-3">
        <div className="flex items-start justify-between">
          <div className="flex-1">
            <div className="flex items-center space-x-2 mb-2">
              <CardTitle className="text-base font-medium">{item.title}</CardTitle>
              {item.required && (
                <Badge variant="outline" className="text-xs">Required</Badge>
              )}
              {isDisplayOnly && (
                <Badge variant="secondary" className="text-xs">Auto-checked</Badge>
              )}
            </div>
            <p className="text-sm text-muted-foreground">{item.description}</p>
          </div>
          <div className="flex items-center space-x-2">
            <StatusBadge status={item.status} />
            <TooltipProvider>
              <Tooltip>
                <TooltipTrigger asChild>
                  <Button 
                    variant="ghost" 
                    size="sm"
                    onClick={() => setIsExpanded(!isExpanded)}
                  >
                    <InformationCircleIcon className="h-4 w-4" />
                  </Button>
                </TooltipTrigger>
                <TooltipContent>
                  <p className="max-w-xs">{item.whyMatters}</p>
                </TooltipContent>
              </Tooltip>
            </TooltipProvider>
          </div>
        </div>
      </CardHeader>

      {(isExpanded || item.status !== "yes") && (
        <CardContent className="pt-0 space-y-4">
          <div className="text-sm text-muted-foreground p-3 bg-muted/50 rounded-md">
            <strong>Help:</strong> {item.helpText}
          </div>

          {!isDisplayOnly && (
            <div className="space-y-3">
              <div>
                <label className="text-sm font-medium mb-2 block">Compliance Status</label>
                <Select
                  value={item.status}
                  onValueChange={handleStatusChange}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="yes">Yes - Compliant</SelectItem>
                    <SelectItem value="no">No - Non-Compliant</SelectItem>
                    <SelectItem value="na">Not Applicable</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              {item.status === "na" && (
                <div>
                  <label className="text-sm font-medium mb-2 block">
                    Justification <span className="text-destructive">*</span>
                  </label>
                  <Textarea
                    placeholder="Please explain why this requirement is not applicable to your organization..."
                    value={item.justification || ""}
                    onChange={(e) => handleJustificationChange(e.target.value)}
                    className="min-h-[80px]"
                  />
                </div>
              )}

              <div>
                <label className="text-sm font-medium mb-2 block">Evidence</label>
                <div className="flex items-center space-x-2">
                  <DocumentArrowUpIcon className="h-4 w-4 text-muted-foreground" />
                  <Input
                    placeholder="Upload evidence file or enter reference..."
                    value={item.evidence || ""}
                    onChange={(e) => handleEvidenceChange(e.target.value)}
                  />
                </div>
                <p className="text-xs text-muted-foreground mt-1">
                  In a real implementation, this would allow file uploads
                </p>
              </div>
            </div>
          )}

          {item.status === "no" && item.recommendation && (
            <div className="flex items-start space-x-2 p-3 bg-warning/10 border border-warning/20 rounded-md">
              <ExclamationCircleIcon className="h-4 w-4 text-warning mt-0.5 flex-shrink-0" />
              <div>
                <p className="text-sm font-medium text-warning">Recommendation</p>
                <p className="text-sm text-warning/80">{item.recommendation}</p>
              </div>
            </div>
          )}

          {item.lastUpdated && (
            <p className="text-xs text-muted-foreground">
              Last updated: {new Date(item.lastUpdated).toLocaleDateString()}
            </p>
          )}
        </CardContent>
      )}
    </Card>
  );
}