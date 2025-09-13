import type { ChecklistSection } from '../types';

export const autoTemplateSections: ChecklistSection[] = [
  {
    id: "email-security",
    title: "Email Security",
    description: "Automated email security checks",
    items: [
      {
        id: "spf-dkim-dmarc",
        title: "SPF/DKIM/DMARC Implementation",
        description: "Email authentication protocols are properly configured",
        helpText: "These protocols help prevent email spoofing and phishing attacks",
        whyMatters: "Protects your domain from being used in phishing attacks and improves email deliverability",
        category: "email",
        required: true,
        status: "no",
        recommendation: "Configure SPF, DKIM, and DMARC records for your email domain",
        kind: "auto",
        readOnly: true,
        info: {
          whatItMeans: "Email authentication protocols that verify the legitimacy of emails sent from your domain.",
          whyItMatters: "Prevents email spoofing and phishing attacks, improving email security and deliverability.",
          lawRefs: ["Art. 15 - Email Security", "NU-49-MDED-2025 §7.3"],
          priority: "should",
          resources: [
            { title: "Email Authentication Guide", url: "https://example.com/email-auth" }
          ]
        }
      },
      {
        id: "spf-record",
        title: "SPF Record",
        description: "SPF record configured for email domain",
        helpText: "SPF prevents email spoofing by specifying authorized mail servers",
        whyMatters: "Prevents attackers from sending emails that appear to come from your domain",
        category: "email",
        required: true,
        status: "no",
        recommendation: "Configure SPF record for your email domain",
        kind: "auto",
        readOnly: true,
        info: {
          whatItMeans: "SPF (Sender Policy Framework) is an email authentication method that specifies which mail servers are authorized to send emails for your domain.",
          whyItMatters: "Prevents email spoofing and improves email deliverability by verifying the sender's identity.",
          lawRefs: ["Art. 15 - Email Security", "NU-49-MDED-2025 §7.3"],
          priority: "should",
          resources: [
            { title: "SPF Record Generator", url: "https://example.com/spf-generator" }
          ]
        }
      },
      {
        id: "dkim-signing",
        title: "DKIM Signing",
        description: "DKIM email authentication enabled",
        helpText: "DKIM provides cryptographic authentication for email messages",
        whyMatters: "Ensures email integrity and prevents tampering in transit",
        category: "email",
        required: true,
        status: "no",
        recommendation: "Enable DKIM signing for your email domain",
        kind: "auto",
        readOnly: true,
        info: {
          whatItMeans: "DKIM (DomainKeys Identified Mail) uses cryptographic signatures to verify that email messages haven't been tampered with during transit.",
          whyItMatters: "Ensures email integrity and helps prevent phishing attacks by verifying message authenticity.",
          lawRefs: ["Art. 15 - Email Security", "NU-49-MDED-2025 §7.3"],
          priority: "should",
          resources: [
            { title: "DKIM Setup Guide", url: "https://example.com/dkim-setup" }
          ]
        }
      },
      {
        id: "dmarc-policy",
        title: "DMARC Policy",
        description: "DMARC policy configured for email protection",
        helpText: "DMARC builds on SPF and DKIM to provide email authentication",
        whyMatters: "Provides comprehensive email authentication and reporting",
        category: "email",
        required: true,
        status: "no",
        recommendation: "Implement DMARC policy with monitoring",
        kind: "auto",
        readOnly: true,
        info: {
          whatItMeans: "DMARC (Domain-based Message Authentication, Reporting and Conformance) builds on SPF and DKIM to provide comprehensive email authentication.",
          whyItMatters: "Provides comprehensive email authentication and reporting, helping prevent domain spoofing and phishing attacks.",
          lawRefs: ["Art. 15 - Email Security", "NU-49-MDED-2025 §7.3"],
          priority: "should",
          resources: [
            { title: "DMARC Implementation Guide", url: "https://example.com/dmarc-guide" }
          ]
        }
      }
    ]
  },
  {
    id: "web-hygiene",
    title: "Web Hygiene",
    description: "Automated web security and configuration checks",
    items: [
      {
        id: "tls-https",
        title: "TLS/HTTPS Implementation",
        description: "All websites use secure HTTPS connections",
        helpText: "This is automatically checked by our scanning tools",
        whyMatters: "Encrypts data in transit and builds user trust",
        category: "web",
        required: true,
        status: "no",
        recommendation: "Enable HTTPS for all web properties",
        kind: "auto",
        readOnly: true,
        info: {
          whatItMeans: "TLS (Transport Layer Security) encryption for all web traffic to protect data in transit between users and servers.",
          whyItMatters: "Encrypts sensitive data in transit, prevents man-in-the-middle attacks, and builds user trust.",
          lawRefs: ["Art. 16 - Data Encryption", "NU-49-MDED-2025 §8.3"],
          priority: "must",
          resources: [
            { title: "HTTPS Implementation Guide", url: "https://example.com/https-guide" }
          ]
        }
      },
      {
        id: "security-headers",
        title: "Security Headers",
        description: "Proper HTTP security headers are configured",
        helpText: "Headers like HSTS, CSP, and X-Frame-Options protect against common attacks",
        whyMatters: "Prevents common web vulnerabilities and attacks",
        category: "web",
        required: true,
        status: "no",
        recommendation: "Configure security headers (HSTS, CSP, X-Frame-Options)",
        kind: "auto",
        readOnly: true,
        info: {
          whatItMeans: "HTTP security headers that provide additional protection against common web vulnerabilities and attacks.",
          whyItMatters: "Prevents common web attacks like clickjacking, XSS, and protocol downgrade attacks.",
          lawRefs: ["Art. 16 - Data Encryption", "NU-49-MDED-2025 §8.3"],
          priority: "should",
          resources: [
            { title: "Security Headers Guide", url: "https://example.com/security-headers" }
          ]
        }
      },
      {
        id: "tls-version",
        title: "TLS Version",
        description: "Modern TLS version (1.2+) in use",
        helpText: "Older TLS versions have known security vulnerabilities",
        whyMatters: "Ensures secure encrypted connections to your website",
        category: "web",
        required: true,
        status: "no",
        recommendation: "Upgrade to TLS 1.2 or higher",
        kind: "auto",
        readOnly: true,
        info: {
          whatItMeans: "Use of modern TLS versions (1.2 or higher) for secure encrypted connections.",
          whyItMatters: "Older TLS versions have known security vulnerabilities that can be exploited by attackers.",
          lawRefs: ["Art. 16 - Data Encryption", "NU-49-MDED-2025 §8.3"],
          priority: "must",
          resources: [
            { title: "TLS Configuration Guide", url: "https://example.com/tls-config" }
          ]
        }
      },
      {
        id: "hsts-header",
        title: "HSTS Header",
        description: "HTTP Strict Transport Security header present",
        helpText: "HSTS forces browsers to use HTTPS connections",
        whyMatters: "Prevents man-in-the-middle attacks and protocol downgrade",
        category: "web",
        required: true,
        status: "no",
        recommendation: "Configure HSTS header with appropriate max-age",
        kind: "auto",
        readOnly: true,
        info: {
          whatItMeans: "HTTP Strict Transport Security (HSTS) header that forces browsers to use HTTPS connections.",
          whyItMatters: "Prevents man-in-the-middle attacks and protocol downgrade attacks by enforcing HTTPS.",
          lawRefs: ["Art. 16 - Data Encryption", "NU-49-MDED-2025 §8.3"],
          priority: "should",
          resources: [
            { title: "HSTS Configuration Guide", url: "https://example.com/hsts-guide" }
          ]
        }
      },
      {
        id: "ssl-certificate",
        title: "SSL Certificate",
        description: "Valid SSL certificate with proper configuration",
        helpText: "Certificate should be valid, not expired, and properly configured",
        whyMatters: "Ensures encrypted communication and builds user trust",
        category: "web",
        required: true,
        status: "no",
        recommendation: "Obtain and properly configure SSL certificate",
        kind: "auto",
        readOnly: true,
        info: {
          whatItMeans: "Valid SSL/TLS certificate that enables encrypted communication between users and your website.",
          whyItMatters: "Ensures encrypted communication, builds user trust, and prevents data interception.",
          lawRefs: ["Art. 16 - Data Encryption", "NU-49-MDED-2025 §8.3"],
          priority: "must",
          resources: [
            { title: "SSL Certificate Guide", url: "https://example.com/ssl-guide" }
          ]
        }
      }
    ]
  },
  {
    id: "exposure-vulnerabilities",
    title: "Exposure & Vulnerabilities",
    description: "Network exposure and vulnerability assessments",
    items: [
      {
        id: "vuln-scanning",
        title: "Regular Vulnerability Scanning",
        description: "Automated scanning for security vulnerabilities",
        helpText: "This is automatically performed by our scanning tools",
        whyMatters: "Identifies security weaknesses before attackers can exploit them",
        category: "vulnerability",
        required: true,
        status: "no",
        recommendation: "Implement regular vulnerability scanning",
        kind: "auto",
        readOnly: true,
        info: {
          whatItMeans: "Automated scanning tools that identify known security vulnerabilities in your systems and applications.",
          whyItMatters: "Proactively identifies security weaknesses before attackers can exploit them, reducing breach risk.",
          lawRefs: ["Art. 17 - Vulnerability Management", "NU-49-MDED-2025 §8.4"],
          priority: "must",
          resources: [
            { title: "Vulnerability Scanning Tools", url: "https://example.com/vuln-scanning" }
          ]
        }
      },
      {
        id: "open-ports",
        title: "Open Ports",
        description: "Unnecessary open ports identified",
        helpText: "Only required ports should be accessible from the internet",
        whyMatters: "Reduces attack surface and potential entry points",
        category: "network",
        required: true,
        status: "no",
        recommendation: "Close unnecessary ports and restrict access",
        kind: "auto",
        readOnly: true,
        info: {
          whatItMeans: "Identification of unnecessary open network ports that could be exploited by attackers.",
          whyItMatters: "Reduces attack surface by closing unnecessary entry points to your systems.",
          lawRefs: ["Art. 17 - Vulnerability Management", "NU-49-MDED-2025 §8.4"],
          priority: "should",
          resources: [
            { title: "Port Security Guide", url: "https://example.com/port-security" }
          ]
        }
      },
      {
        id: "cve-scan",
        title: "CVE Scan",
        description: "Known vulnerabilities detected in services",
        helpText: "Common Vulnerabilities and Exposures database check",
        whyMatters: "Identifies known security flaws that can be exploited",
        category: "vulnerability",
        required: true,
        status: "no",
        recommendation: "Patch or update vulnerable services immediately",
        kind: "auto",
        readOnly: true,
        info: {
          whatItMeans: "Scanning for known vulnerabilities using the Common Vulnerabilities and Exposures (CVE) database.",
          whyItMatters: "Identifies known security flaws that can be exploited by attackers if not patched.",
          lawRefs: ["Art. 17 - Vulnerability Management", "NU-49-MDED-2025 §8.4"],
          priority: "must",
          resources: [
            { title: "CVE Database", url: "https://example.com/cve-database" }
          ]
        }
      },
      {
        id: "service-banner",
        title: "Service Banner",
        description: "Service version information exposed",
        helpText: "Banner grabbing reveals software versions and configurations",
        whyMatters: "Version information helps attackers target specific vulnerabilities",
        category: "network",
        required: true,
        status: "no",
        recommendation: "Disable or modify service banners to hide version info",
        kind: "auto",
        readOnly: true,
        info: {
          whatItMeans: "Service banners that expose version information about running services and software.",
          whyItMatters: "Version information helps attackers identify and target specific vulnerabilities in your systems.",
          lawRefs: ["Art. 17 - Vulnerability Management", "NU-49-MDED-2025 §8.4"],
          priority: "should",
          resources: [
            { title: "Banner Security Guide", url: "https://example.com/banner-security" }
          ]
        }
      },
      {
        id: "directory-listing",
        title: "Directory Listing",
        description: "Web directory listing enabled",
        helpText: "Directory listing exposes file structure and sensitive files",
        whyMatters: "Reveals internal structure and potentially sensitive information",
        category: "web",
        required: true,
        status: "no",
        recommendation: "Disable directory listing on web servers",
        kind: "auto",
        readOnly: true,
        info: {
          whatItMeans: "Web server configuration that allows directory listing, exposing file structure and potentially sensitive files.",
          whyItMatters: "Reveals internal structure and potentially sensitive information that could be exploited by attackers.",
          lawRefs: ["Art. 17 - Vulnerability Management", "NU-49-MDED-2025 §8.4"],
          priority: "should",
          resources: [
            { title: "Web Security Configuration", url: "https://example.com/web-security" }
          ]
        }
      }
    ]
  }
];