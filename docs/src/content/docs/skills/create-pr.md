---
title: "/vibe:create-pr"
sidebar:
  order: 6
---

Creates a structured PR with summary, test plan, and review checklist.

## Usage

```
/vibe:create-pr [base-branch]
```

The base branch defaults to `main` if not specified.

## What it does

1. **Analyze changes** — runs `git diff --stat` and `git log --oneline` to understand what changed
2. **Generate PR title** — creates a title under 70 characters using conventional commit style
3. **Write summary** — bullet-point summary of the key changes
4. **Create test plan** — checklist of what to test
5. **Push branch** — pushes the branch to remote if needed
6. **Create PR** — uses `gh pr create` with structured sections

## PR format

```markdown
## Summary

- Added user profile endpoint with validation
- Integrated with existing auth middleware

## Changes

- src/users/profile.controller.ts — new endpoint
- src/users/profile.service.ts — business logic
- src/users/profile.test.ts — unit tests

## Test Plan

- [ ] GET /users/:id returns user profile
- [ ] Returns 404 for non-existent user
- [ ] Returns 401 without auth token

following AI-CORE-STANDARDS
```

## Notes

- Includes the review checklist from `REVIEW.md`
- PR body always ends with `following AI-CORE-STANDARDS`
- Read-only analysis — uses Glob, Grep, Read, and Bash (for git/gh commands)
