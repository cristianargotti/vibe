---
title: "/vibe:fix-vulnerabilities"
sidebar:
  order: 10
---

Reads Dependabot alerts and fixes security vulnerabilities automatically.

## Usage

```
/vibe:fix-vulnerabilities
```

No arguments required — auto-discovers alerts from the current repository via GitHub API.

## What it does

A 10-step automated workflow:

1. **Detect repo** — identifies `owner/repo` from the current git remote
2. **Fetch alerts** — calls `gh api repos/{owner}/{repo}/dependabot/alerts?state=open`
3. **Group & sort** — groups alerts by package, sorts by severity (critical → high → moderate → low)
4. **Detect ecosystem** — checks for `package.json` (npm) or `requirements.txt`/`pyproject.toml` (pip)
5. **Fix direct deps** — bumps version in manifest to the patched version
6. **Fix transitive deps** — runs `npm audit fix` or adds `overrides`/constraints
7. **Regenerate lock files** — runs `npm install` or equivalent
8. **Run tests** — executes `npm test` or `pytest` to verify nothing broke
9. **Commit** — creates branch `fix/dependabot-vulnerabilities` with `fix(deps): resolve N security vulnerabilities`
10. **Output summary** — table with each CVE, severity, and resolution status

## Output format

```
| Package | CVE            | Severity | Status                           |
|---------|----------------|----------|----------------------------------|
| lodash  | CVE-2024-1234  | critical | fixed (4.17.20 → 4.17.21)       |
| express | CVE-2024-5678  | high     | fixed (4.18.1 → 4.19.2)         |
| foo-lib | CVE-2024-9999  | moderate | manual — no fix available        |
```

## Rules

- Never downgrades dependencies — only upgrades to patched versions
- Never removes dependencies — only updates versions
- Preserves version range operators (`^`, `~`, `>=`)
- Skips `npm audit fix --force` (can introduce breaking changes)
- Groups all fixes in a single commit

## GitHub Actions

This skill also ships as a GitHub Actions workflow (`claude-fix-vulnerabilities.yml`) that can be triggered:

- **Manually** from the Actions tab with severity filter and dry-run option
- **Automatically** when an issue is labeled `claude-security-fix`

The workflow uses `anthropics/claude-code-action@v1` to run the same logic in CI.

## Prerequisites

- `gh` CLI authenticated (for API access to Dependabot alerts)
- Repository must have Dependabot alerts enabled (GitHub Settings → Security → Dependabot)
