---
description: ALWAYS invoke when user types /deploy-check. Runs pre-deployment verification checklist.
model: sonnet
---

# Pre-Deployment Check

Run a comprehensive pre-deployment verification checklist.

## Instructions

Execute each check and report pass/fail status:

### 1. Code Quality
- [ ] Run linter: `npm run lint` (or equivalent)
- [ ] Run type check: `npx tsc --noEmit` (if TypeScript)
- [ ] Run formatter check: `npm run format:check`

### 2. Tests
- [ ] Run unit tests: `npm test` or `pytest`
- [ ] Check coverage meets 80% minimum
- [ ] Run E2E tests if available: `npx playwright test`

### 3. Security
- [ ] Run `npm audit --production` (Node.js)
- [ ] Run `pip audit` (Python)
- [ ] Search for hardcoded secrets: grep for API keys, passwords, tokens
- [ ] Verify no `.env` files are staged

### 4. Build
- [ ] Run production build: `npm run build`
- [ ] Check bundle size for regressions
- [ ] Verify Docker build: `docker build .` (if Dockerfile exists)

### 5. Infrastructure
- [ ] Run `terraform validate` (if Terraform files exist)
- [ ] Run `terraform plan` and review changes
- [ ] Verify environment variables are documented

### 6. Dependencies
- [ ] Check for outdated dependencies: `npm outdated`
- [ ] Verify no conflicting peer dependencies
- [ ] Check lock file is committed

## Output Format

```
✅ Linting          — passed
✅ Type checking     — passed
❌ Test coverage     — 72% (minimum: 80%)
✅ Security audit    — no vulnerabilities
⚠️  Outdated deps    — 3 packages outdated
...

DEPLOY STATUS: READY / NOT READY
Blockers: [list any ❌ items]
Warnings: [list any ⚠️ items]
```

## Rules
- Report ALL results even if some checks fail
- Never skip a check — mark as N/A if not applicable
- Blockers (❌) prevent deployment
- Warnings (⚠️) should be acknowledged but don't block
