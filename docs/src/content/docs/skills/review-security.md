---
title: "/vibe:review-security"
sidebar:
  order: 2
---

OWASP-based security review of your codebase.

## Usage

```
/vibe:review-security
```

## What it does

Scans your project for security vulnerabilities across two categories:

### OWASP Top 10

1. **Injection** — SQL injection, command injection, LDAP injection
2. **Broken Authentication** — weak passwords, missing MFA, session issues
3. **Sensitive Data Exposure** — unencrypted PII, leaked credentials
4. **XML External Entities (XXE)** — unsafe XML parsing
5. **Broken Access Control** — missing auth checks, IDOR
6. **Security Misconfiguration** — default credentials, verbose errors
7. **Cross-Site Scripting (XSS)** — unsanitized output, DOM manipulation
8. **Insecure Deserialization** — untrusted data deserialization
9. **Known Vulnerabilities** — outdated dependencies with CVEs
10. **Insufficient Logging** — missing audit trails, no alerting

### Dafiti-specific checks

- **LGPD compliance** — PII handling, consent management, data encryption at rest
- **PCI DSS** — payment data handling, tokenization
- **API key exposure** — hardcoded secrets, unprotected endpoints

## Output format

Findings are grouped by severity:

- **Critical** — must fix before deploying
- **High** — should fix in current sprint
- **Medium** — fix in next sprint
- **Low** — consider fixing
- **Passing** — checks that passed successfully

## Model

Runs on **Opus** for maximum accuracy. Uses a fork context to avoid modifying your working state.

## Notes

- Read-only — this skill never modifies files
- Uses Glob, Grep, and Read tools to scan the codebase
