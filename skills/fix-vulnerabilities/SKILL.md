---
name: fix-vulnerabilities
description: ALWAYS invoke when user types /fix-vulnerabilities. Reads Dependabot alerts and fixes security vulnerabilities.
allowed-tools: Read, Grep, Glob, Edit, Write, Bash
---

# Fix Security Vulnerabilities

Read Dependabot alerts from the current repository, fix what can be auto-fixed, and report what needs manual attention.

## Instructions

1. **Detect repo**: Run `gh api repos/{owner}/{repo}` using `gh repo view --json owner,name -q '.owner.login + "/" + .name'` to get owner/repo
2. **Fetch alerts**: Run `gh api repos/{owner}/{repo}/dependabot/alerts?state=open --paginate` to list all open alerts
3. **If no alerts**: Report "No open Dependabot alerts found" and stop
4. **Group alerts**: Group by package name and sort groups by severity (critical → high → moderate → low)
5. **Detect ecosystem**: Check for `package.json` (npm), `requirements.txt` / `pyproject.toml` (pip), or both
6. **For each group, attempt fix**:

   ### npm (JavaScript/TypeScript)
   - **Direct dependency**: Update version in `package.json` to the patched version from the alert
   - **Transitive dependency**: Run `npm audit fix`. If that doesn't resolve it, add an `overrides` entry in `package.json`
   - **No fix available**: Log as "requires manual attention" and suggest alternative packages if possible

   ### pip (Python)
   - **Direct dependency**: Update version in `requirements.txt` or `pyproject.toml` to the patched version
   - **Transitive dependency**: Pin the transitive dep to the fixed version in constraints
   - **No fix available**: Log as "requires manual attention"

7. **Regenerate lock files**:
   - npm: Run `npm install` to update `package-lock.json`
   - pip: Run `pip compile` or equivalent if using pip-tools
8. **Run tests**: Execute `npm test` or `pytest` (whichever applies). Report results but don't block on failures
9. **Create branch and commit**:
   - Branch: `fix/dependabot-vulnerabilities`
   - Commit: `fix(deps): resolve N security vulnerabilities`
   - Include list of CVEs in commit body
10. **Output summary table**:

```
| Package | CVE | Severity | Status |
|---------|-----|----------|--------|
| lodash  | CVE-2024-1234 | critical | fixed (4.17.20 → 4.17.21) |
| express | CVE-2024-5678 | high     | fixed (4.18.1 → 4.19.2) |
| foo-lib | CVE-2024-9999 | moderate | manual — no fix available |
```

## Rules

- Never downgrade a dependency — only upgrade to patched versions
- Never remove a dependency — only update versions
- Always preserve existing version range operators (^, ~, >=)
- If `npm audit fix --force` would be needed, skip and mark as manual — force can introduce breaking changes
- Always run tests after making changes
- Group all vulnerability fixes in a single commit for clean git history
