---
title: Changelog
sidebar:
  order: 2
---

## v2.2.0

- Added Starlight documentation site (42 pages) at `docs/`
- Prebuild script copies standards with Starlight frontmatter (no content duplication)
- GitHub Pages deploy workflow (`deploy-docs.yml`)
- Dependabot tracking for docs dependencies
- Documentation: getting-started, skills, hooks, automation, configuration, guides, admin sections
- Full-text search via Pagefind

## v2.1.0

- Added secret detection in workflow guard (30+ patterns from `secret-patterns.txt`)
- Added native git hooks: `pre-commit` (branch protection + secret scanning) and `commit-msg` (conventional commit validation)
- Added `branch-guard.sh` hook — blocks file edits on protected branches
- Added `workflow-guard.sh` hook — comprehensive workflow enforcement (6 rules)
- Added base branch freshness check before creating new branches
- Added CI check requirement before PR merge
- Hardened hook permissions from security audit

## v2.0.0

- Migrated to Claude Code plugin system (`/plugin install`)
- Added interactive setup wizard (`/vibe:setup`)
- Added 9 skills: setup, review-security, deploy-check, fix-issue, refactor, create-pr, test, health-check, whats-new
- Added 3 specialized agents: code-reviewer, ecommerce-expert, infra-reviewer
- Added 6 MCP server integrations
- Added 5 GitHub Actions workflows
- Added plugin validation CI
- Added weekly MCP version check workflow
- Added health-check with 3-layer validation script

## v1.0.0

- Initial release with 12 engineering standards
- 5 convention rule files (`.claude/rules/`)
- CLAUDE.md project instructions template
- REVIEW.md PR review checklist
- Basic settings.json with permission controls
