import { cn } from "@/lib/utils";

interface StatusBadgeProps {
  status: "yes" | "no" | "na" | "draft" | "submitted" | "initial" | "update" | "final";
  className?: string;
}

const statusConfig = {
  yes: {
    label: "Compliant",
    className: "bg-success/10 text-success border-success/20"
  },
  no: {
    label: "Non-Compliant", 
    className: "bg-destructive/10 text-destructive border-destructive/20"
  },
  na: {
    label: "Not Applicable",
    className: "bg-muted text-muted-foreground border-border"
  },
  draft: {
    label: "Draft",
    className: "bg-warning/10 text-warning border-warning/20"
  },
  submitted: {
    label: "Submitted",
    className: "bg-success/10 text-success border-success/20"
  },
  initial: {
    label: "Initial Report",
    className: "bg-primary/10 text-primary border-primary/20"
  },
  update: {
    label: "Update Report",
    className: "bg-warning/10 text-warning border-warning/20"
  },
  final: {
    label: "Final Report",
    className: "bg-success/10 text-success border-success/20"
  }
};

export function StatusBadge({ status, className }: StatusBadgeProps) {
  const config = statusConfig[status];
  
  return (
    <span className={cn(
      "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium border",
      config.className,
      className
    )}>
      {config.label}
    </span>
  );
}