---
title: Installation
sidebar:
  order: 2
---

Vibe installs as a Claude Code plugin from the Dafiti marketplace. The entire setup takes under 2 minutes.

## Prerequisites

- [Claude Code](https://claude.ai/code) installed and authenticated
- A GitHub repository for your project
- Node.js 18+

## Install the plugin

Run these three commands in your project directory:

```bash
# 1. Add the Dafiti marketplace
/plugin marketplace add dafiti-group/vibe

# 2. Install the Vibe plugin
/plugin install vibe

# 3. Run the interactive setup wizard
/vibe:setup
```

## Setup wizard

The `/vibe:setup` wizard walks you through 6 steps:

1. **Check existing config** — detects if you already have Vibe files and asks before overwriting.
2. **Tech stack** — select your technologies: TypeScript/NestJS, React/Next.js, Python/FastAPI, Terraform/AWS, Docker.
3. **Security level** — choose Basic, Standard, or Strict:

| Feature          | Basic     | Standard               | Strict                                    |
| ---------------- | --------- | ---------------------- | ----------------------------------------- |
| `.claude/rules/` | Core only | All relevant           | All relevant                              |
| Hooks            | None      | Branch + commit guards | All guards + secret detection             |
| GitHub Actions   | None      | PR review              | PR review + security scan + issue handler |
| Native git hooks | No        | No                     | Yes (pre-commit + commit-msg)             |

4. **Integrations** — select MCP servers: GitHub (recommended), Context7, Sequential Thinking, AWS, ESLint, Terraform.
5. **Skills** — choose which skills to enable (all 9 available).
6. **Generate files** — creates `CLAUDE.md`, `.claude/rules/`, `.claude/settings.json`, `.mcp.json`, workflows, standards docs, and optionally native git hooks.

## Generated files

After setup, your project will have:

```
.claude/
├── rules/
│   ├── backend.md
│   ├── frontend.md
│   ├── infra.md
│   ├── quality.md
│   └── security.md
├── settings.json
CLAUDE.md
.mcp.json
docs/standards/          # 12 standards files
.github/workflows/       # CI workflows (if enabled)
vibe.config.json         # Your Vibe configuration
```

## Verify installation

Run the health check to confirm everything is configured correctly:

```
/vibe:health-check
```

This validates all components: plugin manifest, hooks, skills, agents, settings, standards, and version compatibility.

## GitHub setup

If you enabled GitHub Actions (Standard or Strict security level), add the Claude Code OAuth token to your repository secrets:

1. Generate a token: `claude setup-token`
2. Go to **Settings > Secrets and variables > Actions** in your GitHub repository
3. Add a new secret named `CLAUDE_CODE_OAUTH_TOKEN` with the token value
