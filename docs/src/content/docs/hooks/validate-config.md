---
title: Validate Config
sidebar:
  order: 5
---

Checks your Vibe configuration when Claude Code starts.

**Trigger**: `SessionStart` (timeout: 5 seconds)
**File**: `hooks/validate-config.sh`

## What it checks

| Check                                            | Severity                                 |
| ------------------------------------------------ | ---------------------------------------- |
| `CLAUDE.md` exists                               | Warning                                  |
| `.claude/rules/` directory exists                | Warning                                  |
| `.claude/settings.json` exists and is valid JSON | Warning                                  |
| `vibe.config.json` exists                        | Warning (suggests running `/vibe:setup`) |
| `versions.json` is valid JSON (if present)       | Warning                                  |

## Non-blocking

This hook **never blocks** Claude from starting. It only outputs warnings that appear at the beginning of the session. It's designed to be lightweight (< 100ms) so it doesn't slow down startup.

## Example output

If configuration is missing:

```
Vibe: No vibe.config.json found — run /vibe:setup to configure.
```

If everything is configured:

```
(no output — silent when healthy)
```
