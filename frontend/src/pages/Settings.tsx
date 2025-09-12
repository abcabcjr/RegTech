import { useState, useEffect } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Label } from "@/components/ui/label";
import { Separator } from "@/components/ui/separator";
import { Badge } from "@/components/ui/badge";
import { useToast } from "@/hooks/use-toast";
import { OrganizationProfile } from "@/lib/types";
import { 
  loadOrganizationProfile, 
  saveOrganizationProfile, 
  resetAllData,
  loadChecklistState,
  loadIncidents
} from "@/lib/persistence";
import { 
  BuildingOfficeIcon, 
  TrashIcon, 
  InformationCircleIcon,
  ExclamationTriangleIcon
} from "@heroicons/react/24/outline";

const sectors = [
  "Financial Services",
  "Healthcare",
  "Government",
  "Education", 
  "Energy & Utilities",
  "Transportation",
  "Telecommunications",
  "Manufacturing",
  "Retail & E-commerce",
  "Technology",
  "Other"
];

export default function Settings() {
  const [profile, setProfile] = useState<OrganizationProfile>(() => loadOrganizationProfile());
  const [isLoading, setIsLoading] = useState(false);
  const { toast } = useToast();

  const [stats, setStats] = useState({
    checklistItems: 0,
    incidents: 0,
    complianceScore: 0
  });

  useEffect(() => {
    const checklistState = loadChecklistState();
    const incidents = loadIncidents();
    
    setStats({
      checklistItems: checklistState.sections.reduce((acc, section) => acc + section.items.length, 0),
      incidents: incidents.length,
      complianceScore: checklistState.complianceScore
    });
  }, []);

  const handleSave = async () => {
    setIsLoading(true);
    try {
      saveOrganizationProfile(profile);
      toast({
        title: "Settings saved",
        description: "Your organization profile has been updated successfully.",
      });
    } catch (error) {
      toast({
        title: "Error saving settings",
        description: "There was a problem saving your settings. Please try again.",
        variant: "destructive",
      });
    } finally {
      setIsLoading(false);
    }
  };

  const handleReset = () => {
    if (window.confirm("Are you sure you want to reset all data? This action cannot be undone.")) {
      resetAllData();
      setProfile({
        name: "",
        sector: "",
        turnoverPrevYear: 0,
        lastUpdated: new Date().toISOString()
      });
      
      setStats({
        checklistItems: 0,
        incidents: 0,
        complianceScore: 0
      });

      toast({
        title: "Data reset",
        description: "All application data has been cleared.",
      });
    }
  };

  return (
    <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-foreground mb-4">Settings</h1>
        <p className="text-muted-foreground">
          Configure your organization profile and manage application data.
        </p>
      </div>

      <div className="space-y-8">
        {/* Organization Profile */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center">
              <BuildingOfficeIcon className="h-5 w-5 mr-2" />
              Organization Profile
            </CardTitle>
            <CardDescription>
              Basic information about your organization for compliance reporting.
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="space-y-2">
                <Label htmlFor="org-name">Organization Name</Label>
                <Input
                  id="org-name"
                  placeholder="Enter your organization name"
                  value={profile.name}
                  onChange={(e) => setProfile({ ...profile, name: e.target.value })}
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="sector">Business Sector</Label>
                <Select value={profile.sector} onValueChange={(value) => setProfile({ ...profile, sector: value })}>
                  <SelectTrigger>
                    <SelectValue placeholder="Select your sector" />
                  </SelectTrigger>
                  <SelectContent>
                    {sectors.map((sector) => (
                      <SelectItem key={sector} value={sector}>
                        {sector}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label htmlFor="turnover">Previous Year Turnover (EUR)</Label>
                <Input
                  id="turnover"
                  type="number"
                  placeholder="0"
                  value={profile.turnoverPrevYear}
                  onChange={(e) => setProfile({ ...profile, turnoverPrevYear: Number(e.target.value) })}
                />
                <p className="text-xs text-muted-foreground">
                  Used to determine applicable cybersecurity requirements
                </p>
              </div>

              <div className="space-y-2">
                <Label>Last Updated</Label>
                <p className="text-sm text-muted-foreground">
                  {profile.lastUpdated ? new Date(profile.lastUpdated).toLocaleDateString() : "Never"}
                </p>
              </div>
            </div>

            <div className="flex justify-end">
              <Button onClick={handleSave} disabled={isLoading}>
                {isLoading ? "Saving..." : "Save Profile"}
              </Button>
            </div>
          </CardContent>
        </Card>

        {/* Data Overview */}
        <Card>
          <CardHeader>
            <CardTitle>Data Overview</CardTitle>
            <CardDescription>
              Summary of your compliance and incident data.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              <div className="text-center p-4 border rounded-lg">
                <div className="text-2xl font-bold text-primary mb-2">
                  {stats.checklistItems}
                </div>
                <p className="text-sm text-muted-foreground">Checklist Items</p>
              </div>
              
              <div className="text-center p-4 border rounded-lg">
                <div className="text-2xl font-bold text-warning mb-2">
                  {stats.incidents}
                </div>
                <p className="text-sm text-muted-foreground">Incidents Reported</p>
              </div>
              
              <div className="text-center p-4 border rounded-lg">
                <div className="text-2xl font-bold text-success mb-2">
                  {stats.complianceScore}%
                </div>
                <p className="text-sm text-muted-foreground">Compliance Score</p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Legal Information */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center">
              <InformationCircleIcon className="h-5 w-5 mr-2" />
              Legal Information
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="p-4 bg-blue-50 border border-blue-200 rounded-md">
              <h3 className="font-semibold text-blue-800 mb-2">Disclaimer</h3>
              <p className="text-sm text-blue-700">
                CyberCare is a demonstration application created for educational and hackathon purposes. 
                This tool is not intended to provide legal advice or guarantee compliance with Moldova's 
                Cybersecurity Law or any other regulations.
              </p>
            </div>

            <div className="p-4 bg-yellow-50 border border-yellow-200 rounded-md">
              <h3 className="font-semibold text-yellow-800 mb-2">Data Storage</h3>
              <p className="text-sm text-yellow-700">
                All data is stored locally in your browser. No information is transmitted to external servers. 
                Data will be lost if you clear your browser storage or use a different device.
              </p>
            </div>

            <div className="space-y-2">
              <h3 className="font-semibold text-foreground">About the Cybersecurity Law</h3>
              <p className="text-sm text-muted-foreground">
                This application is designed to help organizations understand and track compliance with 
                Moldova's Cybersecurity Law. For official requirements and legal interpretations, 
                please consult the official legislation and qualified legal professionals.
              </p>
            </div>
          </CardContent>
        </Card>

        {/* Data Management */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center text-destructive">
              <ExclamationTriangleIcon className="h-5 w-5 mr-2" />
              Data Management
            </CardTitle>
            <CardDescription>
              Reset all application data. This action cannot be undone.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <p className="text-sm text-muted-foreground">
                This will permanently delete all your compliance checklist data, incident reports, 
                and organization profile. Use this feature if you want to start fresh or clear 
                demonstration data.
              </p>
              
              <div className="flex items-center space-x-2">
                <Button variant="destructive" onClick={handleReset}>
                  <TrashIcon className="h-4 w-4 mr-2" />
                  Reset All Data
                </Button>
                <Badge variant="outline" className="text-destructive">
                  Irreversible Action
                </Badge>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}