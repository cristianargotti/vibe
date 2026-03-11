---
title: Block Dangerous Commands
sidebar:
  order: 3
---

Prevents destructive operations from being executed by Claude.

**Trigger**: `PreToolUse/Bash`
**File**: `hooks/block-dangerous-commands.sh`

## Blocked patterns

The hook checks every Bash command against these patterns and blocks matches with a deny decision:

### File system

| Pattern               | Risk                       |
| --------------------- | -------------------------- |
| `rm -rf /`            | System wipe                |
| `rm -rf` / `rm -r -f` | Force recursive delete     |
| `chmod 777`           | World-writable permissions |
| `chown -R root`       | Recursive ownership change |

### Database

| Pattern                                        | Risk          |
| ---------------------------------------------- | ------------- |
| `DROP TABLE` / `DROP DATABASE` / `DROP SCHEMA` | Data loss     |
| `TRUNCATE TABLE`                               | Data loss     |
| `DELETE FROM` (without WHERE)                  | Mass deletion |

### Git

| Pattern                                       | Risk                    |
| --------------------------------------------- | ----------------------- |
| `git push --force` / `git push -f`            | History rewrite         |
| `git branch -D main` / `git branch -D master` | Delete protected branch |

### Infrastructure

| Pattern                           | Risk                       |
| --------------------------------- | -------------------------- |
| `terraform destroy -auto-approve` | Infrastructure destruction |

### Secrets exposure

| Pattern                                 | Risk                  |
| --------------------------------------- | --------------------- |
| `printenv` / `env` / `set`              | Environment dump      |
| `cat *.pem` / `cat *.key` / `cat *.env` | Secret file read      |
| `curl ... \| bash` / `wget ... \| sh`   | Remote code execution |

## How it works

The hook reads tool input JSON from stdin, extracts the `command` field, and runs pattern matching with `grep -qiE`. If any pattern matches, it outputs a JSON deny decision with the reason and exits. Otherwise, it exits `0` to allow the command.
