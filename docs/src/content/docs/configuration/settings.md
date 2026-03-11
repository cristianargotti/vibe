---
title: Settings
sidebar:
  order: 1
---

The `.claude/settings.json` file controls Claude Code permissions and hooks for your project.

## Structure

```json
{
  "permissions": {
    "allow": [...],
    "deny": [...],
    "ask": [...]
  },
  "hooks": {
    "PreToolUse": [...],
    "PostToolUse": [...],
    "SessionStart": [...],
    "Stop": [...]
  }
}
```

## Permissions

### Allow

Pre-approved tool uses that don't require user confirmation. Vibe allows 50+ patterns including:

- **File operations**: `Read`, `Edit`, `Write`, `Glob`, `Grep`
- **Bash commands**: `ls`, `node`, `npm`, `git`, `gh`, `pytest`, `terraform plan`, `docker build`, etc.
- **Skills**: All 9 Vibe skills + `/simplify`

### Deny

Tool uses that are blocked entirely:

| Pattern               | Purpose                                  |
| --------------------- | ---------------------------------------- |
| `Read(.env*)`         | Prevent reading environment files        |
| `Read(secrets/**)`    | Prevent reading secrets directory        |
| `Read(*credentials*)` | Prevent reading credential files         |
| `Read(*.pem)`         | Prevent reading private keys             |
| `Read(*.key)`         | Prevent reading key files                |
| `Read(*.tfvars)`      | Prevent reading Terraform variable files |
| `Bash(curl *)`        | Prevent arbitrary HTTP requests          |
| `Bash(wget *)`        | Prevent arbitrary downloads              |

### Ask

Tool uses that require user confirmation each time:

| Pattern                     | Purpose                                        |
| --------------------------- | ---------------------------------------------- |
| `Bash(terraform apply *)`   | Confirm before applying infrastructure changes |
| `Bash(terraform destroy *)` | Confirm before destroying infrastructure       |

## Hooks

See the [Hooks overview](/vibe/hooks/overview/) for how hooks work. The settings file references hook scripts by path:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "hooks/block-dangerous-commands.sh" },
          { "type": "command", "command": "hooks/workflow-guard.sh" }
        ]
      }
    ]
  }
}
```

## Security levels

The `/vibe:setup` wizard generates different settings based on your chosen security level. See [Installation](/vibe/getting-started/installation/) for the comparison table.
