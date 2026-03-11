---
title: Security Review
sidebar:
  order: 2
---

Automated OWASP security scan on every pull request.

**Workflow**: `.github/workflows/claude-security-review.yml`

## Triggers

- Pull request opened or updated (synchronize)

## What it does

A focused security scan that checks changed files against:

### OWASP Top 10

1. **Injection** — SQL, command, and LDAP injection vectors
2. **Broken Authentication** — weak auth, missing MFA, session management
3. **Sensitive Data Exposure** — unencrypted PII, leaked credentials
4. **XSS** — unsanitized user input in HTML output
5. **Insecure Deserialization** — untrusted data deserialization
6. **Missing Validation** — inputs accepted without validation

### Dafiti-specific

- **LGPD** — Brazilian data protection compliance
- **PCI DSS** — payment data handling
- **API Key Exposure** — hardcoded secrets, unprotected endpoints

## Output format

Findings are reported by severity with file path, line number, and recommended fix:

```
## Security Review — 2 findings

### HIGH: SQL Injection Risk
📁 src/users/users.repository.ts:45
String concatenation in SQL query. Use parameterized query instead.

### MEDIUM: Missing Input Validation
📁 src/orders/orders.controller.ts:23
Request body not validated. Add DTO with class-validator decorators.

---
✅ No critical vulnerabilities found
```

If the scan is clean, it confirms with a passing message.

## Required secrets

- `CLAUDE_CODE_OAUTH_TOKEN` — Claude Code OAuth token
