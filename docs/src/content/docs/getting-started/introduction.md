---
title: Introduction
sidebar:
  order: 1
---

Vibe is a Claude Code plugin that brings Dafiti engineering standards directly into your AI-assisted development workflow. Instead of relying on tribal knowledge or manually checking style guides, Vibe enforces conventions automatically — from the moment you create a branch to the moment your PR is merged.

## What Vibe does

- **Enforces conventions in real-time** — hooks block commits on `main`, validate branch naming, check conventional commits, and detect secrets before they reach the repo.
- **Provides 9 skills** — interactive commands for security reviews, PR creation, issue fixing, refactoring, testing, deployment checks, and more.
- **Brings 12 standards docs** — covering TypeScript, NestJS, React/Next.js, Python, Docker, Terraform, AWS, databases, LLM/AI, observability, API design, and testing.
- **Automates GitHub workflows** — Claude reviews every PR against your rules, scans for OWASP vulnerabilities, and can fix labeled issues automatically.
- **Validates your setup** — a health-check system ensures your configuration stays correct and up-to-date.

## Who it's for

Vibe is designed for engineering teams at Dafiti who use Claude Code as their AI coding assistant. It works with any project in the Dafiti tech stack: TypeScript/NestJS backends, React/Next.js frontends, Python/FastAPI services, and Terraform/AWS infrastructure.

## How it works

Vibe uses a two-tier architecture:

1. **Tier 1 — Rules** (~150 lines, ~2600 tokens): Always loaded in context via `.claude/rules/`. These are the critical conventions Claude must follow on every interaction.
2. **Tier 2 — Standards** (12 detailed docs, loaded on-demand): Deep reference material that skills load only when needed, keeping context usage efficient.

Hooks enforce workflow guardrails (branch protection, commit format, secret scanning), while skills provide interactive commands for common tasks. GitHub Actions automate PR reviews and security scans.

## Next steps

- [Install Vibe](/vibe/getting-started/installation/) in your project
- Follow the [Quickstart guide](/vibe/getting-started/quickstart/) for a 5-minute tour
