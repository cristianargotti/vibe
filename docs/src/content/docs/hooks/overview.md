---
title: Hooks Overview
sidebar:
  order: 1
---

Hooks are shell scripts that run automatically at specific points in the Claude Code lifecycle. They enforce workflow guardrails without requiring manual checks.

## How hooks work

Hooks are defined in two places:

1. **`.claude/settings.json`** — project-level hooks for your repository
2. **`hooks/hooks.json`** — plugin-level hooks bundled with Vibe

Each hook has a **trigger** (when it runs) and a **behavior** (what it does):

| Trigger             | When it fires                     | Can block?        |
| ------------------- | --------------------------------- | ----------------- |
| `PreToolUse/Bash`   | Before any Bash command executes  | Yes               |
| `PreToolUse/Edit`   | Before any file edit              | Yes               |
| `PreToolUse/Write`  | Before any file write             | Yes               |
| `PostToolUse/Write` | After a file is written           | No                |
| `PostToolUse/Edit`  | After a file is edited            | No                |
| `SessionStart`      | When Claude Code starts           | No (warning only) |
| `Stop`              | Before Claude finishes a response | No (prompt only)  |

## Hook lifecycle

1. Claude decides to use a tool (e.g., Bash, Edit)
2. **PreToolUse** hooks run — they receive the tool input as JSON on stdin
3. If any PreToolUse hook returns a `deny` decision, the action is **blocked** with an error message
4. If all hooks allow, the tool executes
5. **PostToolUse** hooks run — they receive the tool output and can perform side effects (like formatting)

## Vibe's hooks

| Hook                                                              | Trigger                 | Purpose                                                              |
| ----------------------------------------------------------------- | ----------------------- | -------------------------------------------------------------------- |
| [Workflow Guard](/vibe/hooks/workflow-guard/)                     | PreToolUse/Bash         | Branch protection, commit validation, merge guards, secret detection |
| [Block Dangerous Commands](/vibe/hooks/block-dangerous-commands/) | PreToolUse/Bash         | Prevents destructive operations                                      |
| [Branch Guard](/vibe/hooks/branch-guard/)                         | PreToolUse/Edit, Write  | Blocks file modifications on protected branches                      |
| [Post-Edit Lint](/vibe/hooks/post-edit-lint/)                     | PostToolUse/Write, Edit | Auto-formats files after changes                                     |
| [Validate Config](/vibe/hooks/validate-config/)                   | SessionStart            | Checks configuration on startup                                      |

## Native git hooks

On **Strict** security level, Vibe also installs native git hooks in `hooks/git-hooks/`:

- **pre-commit** — blocks commits on protected branches, scans for secrets
- **commit-msg** — validates conventional commit format

These work outside Claude Code (in any terminal or IDE), providing protection even when not using Claude.
