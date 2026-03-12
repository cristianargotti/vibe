---
title: "/vibe:health-check"
sidebar:
  order: 8
---

Validates your Vibe plugin configuration and reports any issues.

## Usage

```
/vibe:health-check
```

## What it does

Runs a 3-layer validation across 9 components:

| Component           | What it checks                                                                   |
| ------------------- | -------------------------------------------------------------------------------- |
| **Plugin manifest** | `plugin.json` and `marketplace.json` are valid JSON                              |
| **Hooks**           | `hooks.json` valid, all 5 shell scripts are executable, referenced scripts exist |
| **Skills**          | All 10 `SKILL.md` files have valid YAML frontmatter                              |
| **Agents**          | All 3 agent `.md` files are non-empty                                            |
| **Settings**        | `settings.json` is valid JSON                                                    |
| **Standards**       | All 12 expected standards files present in `docs/standards/`                     |
| **Version**         | `versions.json` matches installed Claude Code version                            |
| **Secret patterns** | `secret-patterns.txt` has 25+ patterns                                           |
| **Auto-updates**    | `dependabot.yml` present, MCP config uses non-deprecated servers                 |

## Output

Each component gets a status: **PASS**, **WARN**, or **FAIL**.

```
Plugin Manifest  PASS  plugin.json and marketplace.json valid
Hooks            PASS  5/5 scripts executable
Skills           PASS  10/10 SKILL.md files valid
Agents           PASS  3/3 agents non-empty
Settings         PASS  settings.json valid JSON
Standards        WARN  11/12 present (missing: llm-ai.md)
Version          PASS  Claude Code 2.1.72
Secret Patterns  PASS  30 patterns loaded
Auto-updates     PASS  dependabot.yml configured

Overall: NEEDS ATTENTION (1 warning)
```

Final verdict: **HEALTHY** / **NEEDS ATTENTION** / **BROKEN**
