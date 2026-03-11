---
title: Daily Workflow
sidebar:
  order: 1
---

A day-in-the-life walkthrough of developing with Vibe.

## Morning: Pick up an issue

1. Find an issue in GitHub, or ask Claude to check what's assigned to you
2. If the issue is labeled `claude-fix`, `claude-feature`, or `claude-refactor`, Claude may already be working on it via the [Issue Handler](/vibe/automation/issue-handler/)

## Start work: Create a branch

```bash
git checkout -b feat/order-status-endpoint
```

Vibe's [Workflow Guard](/vibe/hooks/workflow-guard/) validates the branch name and checks that your base branch is up to date.

## Code: Let Claude follow the rules

Ask Claude to implement your feature. Vibe's rules are automatically in context:

```
Implement a GET /orders/:id/status endpoint that returns the current
order status with tracking information
```

Claude will:

- Follow hexagonal architecture from `backend.md` rules
- Use DTOs and input validation from `security.md` rules
- Add structured logging from `backend.md` rules
- Create tests following `quality.md` rules

If Claude needs deeper guidance, skills like `/vibe:fix-issue` or `/vibe:refactor` load the relevant standards automatically.

## Test: Verify coverage

```
/vibe:test src/orders/order-status.service.ts
```

This generates and runs tests, ensuring 80% minimum coverage.

## Commit: Conventional format

```bash
git add src/orders/
git commit -m "feat(orders): add order status endpoint with tracking"
```

Vibe validates:

- Not committing on a protected branch
- Conventional commit format
- No secrets in staged files

## PR: Structured creation

```
/vibe:create-pr
```

Creates a PR with summary, changes list, test plan, and review checklist.

## Review: Automated feedback

Two workflows fire automatically:

1. **PR Review** — code review against rules and REVIEW.md
2. **Security Review** — OWASP vulnerability scan

Fix any "Must Fix" items, push updates, and merge when CI passes.

## Before deploy: Final check

```
/vibe:deploy-check
```

Verifies lint, tests, security audits, build, infrastructure, and dependencies.
