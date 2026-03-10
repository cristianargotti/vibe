---
description: ALWAYS invoke when user types /review-security. Performs OWASP-based security review of the codebase.
model: opus
context: fork
allowed-tools: Read, Grep, Glob
---

# Security Review

Perform a comprehensive OWASP-based security review of the codebase.

## Instructions

1. Read `.claude/rules/security.md` for security directives
2. Read `docs/standards/typescript.md` and `docs/standards/api-design.md` for secure patterns
3. Scan the codebase for vulnerabilities:

### OWASP Top 10 Checks
- **Injection**: Search for string concatenation in SQL/NoSQL queries, unsanitized user input
- **Broken Auth**: Check JWT implementation, session management, password storage
- **Sensitive Data Exposure**: Search for hardcoded secrets, PII in logs, unencrypted data
- **XXE**: Check XML parser configurations
- **Broken Access Control**: Verify auth middleware on all protected routes
- **Security Misconfiguration**: Check CORS, CSP headers, debug mode, default credentials
- **XSS**: Search for unsanitized HTML rendering, `dangerouslySetInnerHTML`
- **Insecure Deserialization**: Check JSON.parse on untrusted data without validation
- **Known Vulnerabilities**: Check `package.json` / `requirements.txt` for outdated deps
- **Insufficient Logging**: Verify security events are logged

### Dafiti-Specific Checks
- LGPD compliance: PII encryption, data access logging, consent management
- Payment data: PCI DSS considerations for card data, PIX, Boleto
- API keys and credentials in code or config files

## Output Format

Report findings grouped by severity:

### 🔴 Critical
[Findings that need immediate fix]

### 🟠 High
[Findings that should be fixed before next release]

### 🟡 Medium
[Findings to address in upcoming sprints]

### 🔵 Low
[Recommendations for improvement]

### ✅ Passing
[Security practices correctly implemented]

Include file path, line number, and recommended fix for each finding.
