---
title: Quickstart
sidebar:
  order: 3
---

This 5-minute tour walks through a typical Vibe workflow: create a branch, write code, commit, create a PR, and get it reviewed.

## 1. Create a feature branch

Vibe blocks commits on `main`, so start by creating a branch with the correct naming convention:

```bash
git checkout -b feat/add-user-endpoint
```

Branch names must use one of these prefixes: `feat/`, `fix/`, `chore/`, `docs/`, `test/`, `refactor/`.

## 2. Write code

Ask Claude to implement your feature. Vibe's rules are automatically loaded, so Claude follows your team's conventions:

```
Add a GET /users/:id endpoint following our NestJS standards
```

Claude will:

- Follow hexagonal architecture (Controller > Service > Repository)
- Use DTOs with class-validator for input validation
- Add structured logging with pino
- Use custom error classes instead of generic `Error`

## 3. Commit your changes

Vibe validates your commit message follows conventional commits:

```bash
git add src/users/
git commit -m "feat(users): add get user by id endpoint"
```

The hook checks:

- You're not committing on a protected branch
- The message follows `type(scope): description` format
- No secrets are present in staged files

## 4. Create a PR

Use the Vibe skill for structured PRs:

```
/vibe:create-pr
```

This analyzes your changes and creates a PR with:

- A descriptive title (< 70 chars, conventional commit style)
- Summary of changes
- Test plan checklist
- Review checklist from `REVIEW.md`

## 5. Automated review

Once the PR is created, two GitHub Actions fire automatically:

1. **Claude PR Review** — reviews your code against `.claude/rules/` and `REVIEW.md`, grouping findings by severity: Must Fix / Should Fix / Consider / Praise.
2. **Claude Security Review** — scans for OWASP Top 10 vulnerabilities plus Dafiti-specific checks (LGPD, PCI DSS, API key exposure).

## 6. Fix issues and merge

Address any "Must Fix" items, push updates, and merge when CI passes.

## What's next?

- Explore all [Skills](/vibe/skills/setup/) available to you
- Understand how [Hooks](/vibe/hooks/overview/) protect your workflow
- Review the [Configuration](/vibe/configuration/settings/) options
