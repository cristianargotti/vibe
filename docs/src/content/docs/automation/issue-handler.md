---
title: Issue Handler
sidebar:
  order: 3
---

Automatically handles GitHub issues labeled for Claude or mentioned with `@claude`.

**Workflow**: `.github/workflows/claude-issue-handler.yml`

## Triggers

- Issue labeled with `claude-fix`, `claude-feature`, or `claude-refactor`
- Issue comment containing `@claude` (on issues, not PRs)

## Label behaviors

### `claude-fix`

Claude finds the root cause, implements a minimal fix, adds regression tests, and creates a PR with a `fix:` commit.

### `claude-feature`

Claude plans the feature, implements it following standards, ensures 80% test coverage, and creates a PR with a `feat:` commit.

### `claude-refactor`

Claude preserves existing behavior (verified by tests), refactors the code, and creates a PR with a `refactor:` commit.

### `@claude` mention

Claude reads the comment, understands the request, and either responds with an answer or makes changes following the appropriate flow above.

## Concurrency

Only one Claude instance runs per issue at a time:

```yaml
concurrency:
  group: claude-issue-${{ github.event.issue.number }}
  cancel-in-progress: true
```

If you label an issue while Claude is already working on it, the previous run is cancelled and a new one starts.

## Required secrets

- `CLAUDE_CODE_OAUTH_TOKEN` — Claude Code OAuth token

## Permissions

```yaml
permissions:
  contents: write # create branches and commits
  issues: write # comment on issues
  pull-requests: write # create PRs
  actions: read
  id-token: write
```
