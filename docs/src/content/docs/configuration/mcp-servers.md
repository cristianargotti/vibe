---
title: MCP Servers
sidebar:
  order: 2
---

The `.mcp.json` file configures Model Context Protocol servers that extend Claude's capabilities.

## Default servers

Vibe configures 3 servers by default:

### GitHub MCP

Gives Claude access to GitHub APIs — reading issues, PRs, commits, and repository data.

```json
{
  "github": {
    "type": "docker",
    "command": "docker",
    "args": [
      "run",
      "-i",
      "--rm",
      "-e",
      "GITHUB_PERSONAL_ACCESS_TOKEN",
      "ghcr.io/github/github-mcp-server:latest"
    ],
    "env": {
      "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
    }
  }
}
```

Requires the `GITHUB_TOKEN` environment variable.

### Context7

Provides up-to-date documentation for any library or framework. Claude can query docs for the exact version you're using.

```json
{
  "context7": {
    "command": "npx",
    "args": ["-y", "@upstash/context7-mcp@latest"]
  }
}
```

### Sequential Thinking

Enables structured reasoning for complex problems — Claude can break down problems step by step, revise previous thinking, and branch into alternative approaches.

```json
{
  "sequential-thinking": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-sequential-thinking@latest"]
  }
}
```

## Optional servers

The setup wizard offers 3 additional servers:

### AWS MCP

Access to AWS documentation and service APIs.

```json
{
  "aws": {
    "command": "uvx",
    "args": ["awslabs.core-mcp-server@latest"]
  }
}
```

### ESLint MCP

Integrates ESLint directly with Claude for real-time linting feedback.

```json
{
  "eslint": {
    "command": "npx",
    "args": ["-y", "@eslint/mcp@latest"]
  }
}
```

### Terraform MCP

Terraform documentation and validation.

```json
{
  "terraform": {
    "type": "docker",
    "command": "docker",
    "args": [
      "run",
      "-i",
      "--rm",
      "-v",
      "${PWD}:/workspace",
      "ghcr.io/hashicorp/terraform-mcp-server:latest"
    ]
  }
}
```

## Version tracking

MCP server versions are tracked in `versions.json`. The `check-mcp-versions.yml` weekly workflow compares your versions against the latest and creates an update issue if drift is detected.
