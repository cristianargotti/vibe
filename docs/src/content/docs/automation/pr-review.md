---
title: PR Review
sidebar:
  order: 1
---

Automated code review on every pull request using Claude.

**Workflow**: `.github/workflows/claude-pr-review.yml`

## Triggers

- Pull request opened or updated (synchronize)
- Comment containing `@claude` on a PR

## What it does

When a PR is opened or updated, Claude reviews all changed files against:

1. **REVIEW.md** — the PR review checklist (security, correctness, architecture, performance, maintainability)
2. **`.claude/rules/`** — backend, frontend, infra, quality, and security rules

## Review priorities

Reviews follow a strict priority order:

1. **Security** — vulnerabilities, secrets, injection risks
2. **Correctness** — bugs, logic errors, edge cases
3. **Architecture** — pattern violations, coupling issues
4. **Quality** — naming, readability, test coverage

## Output format

Findings are grouped by severity:

- **Must Fix** — blocks merge, requires changes
- **Should Fix** — important improvements, should address before merge
- **Consider** — suggestions for improvement
- **Praise** — things done well

Each finding includes the file path, line number, and a clear explanation of the issue and how to fix it.

## Interacting with the review

Comment `@claude` on the PR to ask follow-up questions or request specific analysis. Claude will respond in the PR comments with `track_progress: true` for real-time updates.

## Required secrets

- `CLAUDE_CODE_OAUTH_TOKEN` — Claude Code OAuth token (from `claude setup-token`)

## Permissions

```yaml
permissions:
  contents: read
  pull-requests: write
  issues: write
  actions: read
  id-token: write
```
