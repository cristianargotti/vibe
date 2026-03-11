---
title: Customization
sidebar:
  order: 2
---

How to adapt Vibe to your team's specific needs.

## Adding custom rules

Create or edit files in `.claude/rules/`:

```markdown
# My Team Rules

Always use Portuguese for user-facing error messages.
Always add LGPD consent check before storing PII.
Never use localStorage for sensitive data — use httpOnly cookies.
```

Rules should be imperative ("Always..." or "Never..."), one per line, and specific enough for Claude to follow without ambiguity.

## Modifying hooks

### Disable a hook

Remove it from `.claude/settings.json` under the `hooks` section. For example, to disable post-edit formatting:

```json
{
  "hooks": {
    "PostToolUse": []
  }
}
```

### Add a custom hook

Create a shell script and reference it in `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{ "type": "command", "command": "hooks/my-custom-hook.sh" }]
      }
    ]
  }
}
```

Your hook receives tool input as JSON on stdin. To block an action, output:

```json
{ "decision": "deny", "reason": "Explain why this was blocked" }
```

To allow, exit with code 0 and no output.

## Adding MCP servers

Edit `.mcp.json` to add servers. The format depends on the transport:

### npx-based server

```json
{
  "my-server": {
    "command": "npx",
    "args": ["-y", "@org/my-mcp-server@latest"]
  }
}
```

### Docker-based server

```json
{
  "my-server": {
    "type": "docker",
    "command": "docker",
    "args": ["run", "-i", "--rm", "my-image:latest"]
  }
}
```

After adding, update `versions.json` so the `check-mcp-versions.yml` workflow can track it.

## Adding standards

Create a new file in `docs/standards/` with:

```markdown
<!-- last-reviewed: 2026-03-11 -->

# My Standard Title

Content here...
```

The `last-reviewed` comment is required for the freshness check workflow. Skills load standards by filename, so use a descriptive name like `graphql.md` or `mobile.md`.

## Adjusting permissions

Edit `.claude/settings.json` to change what Claude can and cannot do:

- **allow** — auto-approve without prompting
- **deny** — block entirely
- **ask** — require user confirmation each time
