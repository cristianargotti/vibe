---
title: Workflow Guard
sidebar:
  order: 2
---

The most comprehensive hook in Vibe. It intercepts Bash commands and enforces 6 workflow rules.

**Trigger**: `PreToolUse/Bash`
**File**: `hooks/workflow-guard.sh`

## Rules

### 1. Block commits on protected branches

Blocks `git commit` when on `main`, `master`, or `develop`. Forces you to create a feature branch first.

### 2. Block --no-verify

Blocks any command using `--no-verify`. If a hook is failing, the right approach is to fix the underlying issue, not bypass the check.

### 3. Enforce branch naming

When creating a new branch (`git checkout -b` or `git switch -c`), validates that the name starts with an allowed prefix:

- `feat/` — new features
- `fix/` — bug fixes
- `chore/` — maintenance tasks
- `docs/` — documentation changes
- `test/` — test additions
- `refactor/` — code refactoring

Also checks that the current branch is not behind its remote tracking branch before creating a new branch.

### 4. Validate conventional commits

On `git commit -m "..."`, extracts the commit message and validates the format:

```
type(scope): description
```

Allowed types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `style`, `perf`, `ci`, `build`, `revert`

Merge commits (`Merge ...`) are allowed through.

### 5. Block PR merge on failing CI

When running `gh pr merge`, checks the PR's CI status with `gh pr checks`. Blocks the merge if any check is pending or failing.

### 6. Secret detection in staged files

Before every `git commit`, scans `git diff --cached` (staged changes) for secret patterns:

- AWS access keys and secret keys
- Anthropic API keys
- Private keys (RSA, EC, etc.)
- GitHub tokens
- GitLab tokens
- Slack tokens

Patterns are loaded from `hooks/secret-patterns.txt` (30+ regex patterns).
