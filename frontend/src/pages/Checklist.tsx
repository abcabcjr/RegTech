import { useState, useEffect } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { ProgressBar } from "@/components/ui/progress-bar";
import { ChecklistItem } from "@/components/compliance/checklist-item";
import { ChecklistItem as ChecklistItemType, ChecklistState } from "@/lib/types";
import { loadChecklistState, saveChecklistState } from "@/lib/persistence";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";

export default function Checklist() {
  const [checklistState, setChecklistState] = useState<ChecklistState>(() => loadChecklistState());

  const updateChecklistItem = (sectionId: string, itemId: string, updates: Partial<ChecklistItemType>) => {
    const newState = {
      ...checklistState,
      sections: checklistState.sections.map(section => 
        section.id === sectionId 
          ? {
              ...section,
              items: section.items.map(item => 
                item.id === itemId ? { ...item, ...updates } : item
              )
            }
          : section
      )
    };
    setChecklistState(newState);
    saveChecklistState(newState);
  };

  useEffect(() => {
    setChecklistState(loadChecklistState());
  }, []);

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-foreground mb-4">Compliance Checklist</h1>
        <p className="text-muted-foreground mb-6">
          Track your compliance with Moldova's Cybersecurity Law requirements. 
          Complete the checklist items below and upload evidence where applicable.
        </p>
        
        <Card className="mb-6">
          <CardHeader>
            <CardTitle>Overall Compliance Score</CardTitle>
            <CardDescription>
              Your current compliance based on required checklist items
            </CardDescription>
          </CardHeader>
          <CardContent>
            <ProgressBar value={checklistState.complianceScore} size="lg" />
            <div className="flex justify-between text-sm text-muted-foreground mt-2">
              <span>
                {checklistState.sections.reduce((acc, section) => 
                  acc + section.items.filter(item => item.required && item.status === "yes").length, 0
                )} of {checklistState.sections.reduce((acc, section) => 
                  acc + section.items.filter(item => item.required).length, 0
                )} required items completed
              </span>
              <span>
                Last updated: {new Date(checklistState.lastUpdated).toLocaleDateString()}
              </span>
            </div>
          </CardContent>
        </Card>
      </div>

      <Tabs defaultValue={checklistState.sections[0]?.id} className="w-full">
        <TabsList className="grid w-full grid-cols-3 lg:grid-cols-9 mb-8">
          {checklistState.sections.map((section) => (
            <TabsTrigger 
              key={section.id} 
              value={section.id}
              className="text-xs p-1"
            >
              {section.title.split(' ')[0]}
            </TabsTrigger>
          ))}
        </TabsList>

        {checklistState.sections.map((section) => (
          <TabsContent key={section.id} value={section.id}>
            <Card className="mb-6">
              <CardHeader>
                <CardTitle>{section.title}</CardTitle>
                <CardDescription>{section.description}</CardDescription>
              </CardHeader>
            </Card>

            <div className="space-y-4">
              {section.items.map((item) => (
                <ChecklistItem
                  key={item.id}
                  item={item}
                  onUpdate={(updates) => updateChecklistItem(section.id, item.id, updates)}
                />
              ))}
            </div>
          </TabsContent>
        ))}
      </Tabs>
    </div>
  );
}