---
title: "/vibe:setup"
sidebar:
  order: 1
---

Interactive configuration wizard that sets up Vibe for your project.

## Usage

```
/vibe:setup
```

## What it does

The setup wizard runs a 6-step interactive flow:

1. **Check existing config** — detects existing Vibe files and asks before overwriting
2. **Tech stack selection** — choose your technologies:
   - TypeScript / NestJS
   - React / Next.js
   - Python / FastAPI
   - Terraform / AWS
   - Docker
3. **Security level** — Basic, Standard, or Strict (see [Installation](/vibe/getting-started/installation/) for comparison)
4. **Integrations** — select MCP servers (GitHub, Context7, Sequential Thinking, AWS, ESLint, Terraform)
5. **Skills** — choose which of the 9 skills to enable
6. **Generate** — creates all configuration files

## Generated files

| File                    | Purpose                                                        |
| ----------------------- | -------------------------------------------------------------- |
| `vibe.config.json`      | Your Vibe configuration                                        |
| `CLAUDE.md`             | Project instructions for Claude                                |
| `.claude/rules/*.md`    | Convention rules (backend, frontend, infra, quality, security) |
| `.claude/settings.json` | Permissions, hooks, denied paths                               |
| `.mcp.json`             | MCP server configuration                                       |
| `.github/workflows/`    | CI workflows (Standard/Strict only)                            |
| `docs/standards/*.md`   | 12 engineering standards documents                             |
| `REVIEW.md`             | PR review checklist                                            |
| `hooks/git-hooks/`      | Native git hooks (Strict only)                                 |

## Model

Uses your default model (no model override — runs locally with `disable-model-invocation: true`).

## Notes

- Re-running setup on an existing project asks before overwriting files
- At the end, offers to create a quarterly standards review GitHub issue
