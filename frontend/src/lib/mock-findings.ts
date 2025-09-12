import { Finding } from './types';

export const mockFindings: Finding[] = [
  {
    id: "email-dmarc-missing",
    category: "email",
    severity: "medium",
    title: "DMARC Record Missing",
    summary: "No DMARC record found for your domain. This leaves you vulnerable to email spoofing attacks.",
    recommendation: "Configure a DMARC policy to prevent email spoofing and improve deliverability"
  },
  {
    id: "tls-weak-cipher",
    category: "tls",
    severity: "low",
    title: "Weak TLS Cipher Suite",
    summary: "Some weak cipher suites are still enabled on your web server.",
    recommendation: "Disable weak cipher suites and enable only strong, modern ciphers"
  },
  {
    id: "headers-missing-hsts",
    category: "headers",
    severity: "medium",
    title: "HSTS Header Missing",
    summary: "HTTP Strict Transport Security (HSTS) header is not configured.",
    recommendation: "Enable HSTS to force secure connections and prevent downgrade attacks"
  },
  {
    id: "ports-unnecessary-open",
    category: "ports",
    severity: "high",
    title: "Unnecessary Open Ports",
    summary: "Several non-essential ports are exposed to the internet.",
    evidence: "Ports 23 (Telnet), 21 (FTP) detected as open",
    recommendation: "Close unnecessary ports and restrict access to essential services only"
  },
  {
    id: "backup-no-encryption",
    category: "backup",
    severity: "medium",
    title: "Unencrypted Backups",
    summary: "Backup files are not encrypted, exposing sensitive data if compromised.",
    recommendation: "Enable encryption for all backup storage locations"
  },
  {
    id: "logging-insufficient",
    category: "logging",
    severity: "low",
    title: "Insufficient Security Logging",
    summary: "Not all security events are being logged consistently.",
    recommendation: "Expand logging coverage to include all authentication and access events"
  },
  {
    id: "cve-outdated-software",
    category: "cve",
    severity: "high",
    title: "Outdated Software with Known CVEs",
    summary: "Several software components have known security vulnerabilities.",
    evidence: "WordPress 5.8.0 (CVE-2021-34646), Apache 2.4.41 (CVE-2021-44790)",
    recommendation: "Update all software to the latest versions and establish a patch management process"
  },
  {
    id: "iam-weak-passwords",
    category: "iam",
    severity: "medium",
    title: "Weak Password Policy",
    summary: "Current password policy allows weak passwords.",
    recommendation: "Strengthen password requirements and consider implementing password managers"
  }
];

export const findingsByCategory = {
  email: mockFindings.filter(f => f.category === "email"),
  tls: mockFindings.filter(f => f.category === "tls"),
  headers: mockFindings.filter(f => f.category === "headers"),
  ports: mockFindings.filter(f => f.category === "ports"),
  backup: mockFindings.filter(f => f.category === "backup"),
  logging: mockFindings.filter(f => f.category === "logging"),
  cve: mockFindings.filter(f => f.category === "cve"),
  iam: mockFindings.filter(f => f.category === "iam")
};

export const severityColors = {
  info: "bg-blue-50 text-blue-700 border-blue-200",
  low: "bg-yellow-50 text-yellow-700 border-yellow-200",
  medium: "bg-orange-50 text-orange-700 border-orange-200",
  high: "bg-red-50 text-red-700 border-red-200"
};