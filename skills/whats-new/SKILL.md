---
name: whats-new
description: Check for Claude Code updates, MCP server versions, and new features relevant to Vibe configuration.
allowed-tools: Read, Bash, WebFetch, WebSearch
---

# What's New in Claude Code

Check for updates to Claude Code and MCP servers that may affect Vibe plugin configuration.

## Instructions

1. **Read current versions**: Read `versions.json` to get tracked versions (falls back to `.claude-code-version` if not found)
2. **Check installed version**: Run `claude --version` to get the current installed version
3. **Compare versions**: If they differ, investigate changes
4. **Search for updates**: Search the web for recent Claude Code changelog, release notes, or blog posts
5. **Check MCP server versions**: For each npm-based MCP server in `versions.json`, run `npm view <package> version` to check latest
6. **Check standards freshness**: Read `docs/standards/*.md` headers for `last-reviewed` dates, flag any older than 6 months
7. **Analyze impact**: Check if any changes affect:
   - Hook system (new events, schema changes)
   - Skill system (new frontmatter options, features)
   - Agent system (new capabilities)
   - Settings schema (new options, deprecations)
   - Plugin system (new features, API changes)
   - Permission model changes
   - MCP protocol changes
8. **Report findings**:

## Output Format

```
## Claude Code
Current tracked version: X.X.X
Installed version: Y.Y.Y

## MCP Servers
- github: ghcr.io/github/github-mcp-server:latest (Docker)
- context7: @upstash/context7-mcp — tracked=X.X.X latest=Y.Y.Y
- sequential-thinking: @modelcontextprotocol/server-sequential-thinking — tracked=X.X.X latest=Y.Y.Y

## Standards Freshness
- [standard]: last reviewed [date] — [OK/STALE]

## New Features
- [feature]: [impact on Vibe]

## Breaking Changes
- [change]: [action required]

## Recommendations
- [suggestion for Vibe updates]
```

9. If changes found, offer to update `versions.json` with new versions
