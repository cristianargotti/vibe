---
title: "/vibe:fix-issue"
sidebar:
  order: 4
---

Reads a GitHub issue, implements a fix with tests, and commits it.

## Usage

```
/vibe:fix-issue <issue-number>
```

## What it does

A 10-step automated workflow:

1. **Read issue** — fetches the issue with `gh issue view`
2. **Understand context** — analyzes the issue description and comments
3. **Analyze codebase** — uses Grep/Glob to find relevant code
4. **Read standards** — loads applicable `docs/standards/*.md` for the affected area
5. **Plan fix** — designs a minimal, focused fix
6. **Implement** — writes the fix following `.claude/rules/`
7. **Add tests** — creates regression tests and edge case tests
8. **Run tests** — executes the test suite to verify
9. **Commit** — creates a conventional commit (`fix:` or `feat:`) with `Fixes #<number>`
10. **Output summary** — reports what was changed and why

## Rules

- Keeps fixes minimal — no unrelated refactoring
- Never introduces `any` types
- Uses structured logging
- Validates inputs at API boundaries
- Creates both regression and edge case tests

## Model

Runs on **Opus** for maximum reasoning capability on complex issues.

## Example

```
/vibe:fix-issue 42
```

Output:

```
Fixed #42: Users API returns 500 on missing email

Changes:
- src/users/users.service.ts — added null check for email field
- src/users/users.service.test.ts — added regression test for missing email

Commit: fix(users): handle missing email in user lookup (Fixes #42)
```
