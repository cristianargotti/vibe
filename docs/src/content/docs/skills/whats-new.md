---
title: "/vibe:whats-new"
sidebar:
  order: 9
---

Checks for Claude Code updates, MCP server versions, and standards freshness.

## Usage

```
/vibe:whats-new
```

## What it does

Checks 4 areas and reports what's changed:

### 1. Claude Code version

Compares the version in `versions.json` against `claude --version` and searches the web for recent changelog entries.

### 2. MCP server versions

Checks each MCP server configured in `.mcp.json` against the latest version on npm:

- `@upstash/context7-mcp`
- `@modelcontextprotocol/server-sequential-thinking`
- `@eslint/mcp`
- And any others in your config

### 3. Standards freshness

Reads the `last-reviewed` date from each `docs/standards/*.md` header. Flags any standard not reviewed in the last 6 months.

### 4. Impact analysis

Analyzes how updates affect Vibe's systems: hooks, skills, agents, settings, plugins, permissions, and MCP servers. Identifies breaking changes and new features.

## Output sections

- **Claude Code** — version diff and notable changes
- **MCP Servers** — version status per server
- **Standards Freshness** — review dates and staleness warnings
- **New Features** — capabilities you can adopt
- **Breaking Changes** — things that might break your setup
- **Recommendations** — suggested actions

After reporting, offers to update `versions.json` with current versions.
