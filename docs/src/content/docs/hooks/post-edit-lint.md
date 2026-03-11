---
title: Post-Edit Lint
sidebar:
  order: 4
---

Automatically formats files after Claude edits or writes them.

**Trigger**: `PostToolUse/Write`, `PostToolUse/Edit`
**File**: `hooks/post-edit-lint.sh`

## How it works

After every file write or edit, the hook extracts the file path from the tool output and runs the appropriate formatter based on file extension:

| Extensions                                                                     | Formatter | Command                                         |
| ------------------------------------------------------------------------------ | --------- | ----------------------------------------------- |
| `.ts`, `.tsx`, `.js`, `.jsx`, `.json`, `.md`, `.yml`, `.yaml`, `.css`, `.scss` | Prettier  | `npx --yes prettier --write <file>`             |
| `.py`                                                                          | Ruff      | `ruff format <file> && ruff check --fix <file>` |
| `.tf`, `.tfvars`                                                               | Terraform | `terraform fmt <file>`                          |

## Non-blocking

All formatters run with `|| true` — they never block Claude or cause errors. If a formatter is not installed, the hook silently continues.

## Why this matters

Without auto-formatting, Claude might write code that passes lint checks but doesn't match your team's formatting style. This hook ensures every file is formatted immediately, so you never have to think about formatting.
