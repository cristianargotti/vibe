---
title: Troubleshooting
sidebar:
  order: 3
---

Common issues and how to fix them.

## "Blocked: cannot modify files on 'main'"

**Cause**: The branch guard hook prevents edits on protected branches.

**Fix**: Create a feature branch:

```bash
git checkout -b feat/my-feature
```

## "Invalid commit message format"

**Cause**: The workflow guard validates conventional commit format.

**Fix**: Use the correct format:

```bash
git commit -m "feat(scope): description"
```

Allowed types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `style`, `perf`, `ci`, `build`, `revert`.

## "Dangerous command blocked"

**Cause**: The block-dangerous-commands hook prevented a destructive operation.

**Fix**: This is intentional. If you genuinely need to run the command, do it in a regular terminal (outside Claude Code). The hook only runs inside Claude Code sessions.

## "No vibe.config.json found"

**Cause**: The validate-config hook warns on session start when Vibe hasn't been configured.

**Fix**: Run the setup wizard:

```
/vibe:setup
```

## Hook is blocking something it shouldn't

1. Check which hook is blocking by reading the error message
2. Find the hook script in `hooks/`
3. Review the patterns — they use `grep -qiE` regex matching
4. Edit the pattern if it's too broad, or add an exception

## Health check shows warnings

Run the full health check to see all issues:

```
/vibe:health-check
```

Common warnings:

- **Standards missing** — run `/vibe:setup` to regenerate
- **Version mismatch** — run `/vibe:whats-new` to check for updates
- **Scripts not executable** — run `chmod +x hooks/*.sh`

## MCP server not connecting

1. Check `.mcp.json` is valid JSON
2. For Docker-based servers: ensure Docker is running (`docker ps`)
3. For npx-based servers: ensure the package exists (`npx -y @package/name --help`)
4. Check environment variables are set (e.g., `GITHUB_TOKEN` for the GitHub MCP)

## GitHub Actions not triggering

1. Verify the `CLAUDE_CODE_OAUTH_TOKEN` secret is set in your repo
2. Check the workflow YAML is in `.github/workflows/`
3. Verify the trigger conditions match (e.g., PR labels, branch names)
4. Check the Actions tab in GitHub for error logs

## Debug mode

Use the built-in debug skill to troubleshoot Claude Code session issues:

```
/debug
```
