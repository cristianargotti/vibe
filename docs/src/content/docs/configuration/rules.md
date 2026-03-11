---
title: Rules
sidebar:
  order: 3
---

The `.claude/rules/` directory contains convention files that Claude loads into context on every interaction. These are Tier 1 — always-on rules.

## Rule files

| File          | Scope                                                                                                                                           |
| ------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| `backend.md`  | TypeScript strictness, async/await, hexagonal architecture, DTOs, dependency injection, structured logging, error handling, connection pooling  |
| `frontend.md` | Functional components, TanStack Query, Zustand, error boundaries, skeleton loaders, Server Components, accessibility                            |
| `infra.md`    | Multi-stage Docker builds, Terraform modules, IAM least privilege, S3 encryption, private subnets, resource limits                              |
| `quality.md`  | 80% test coverage, AAA pattern, conventional commits, branch naming, PR limits (400 lines), RESTful conventions, structured logging             |
| `security.md` | Parameterized queries, input validation, no hardcoded secrets, HTTPS, JWT + refresh tokens, LGPD encryption, XSS/CSRF protection, rate limiting |

## Format

Each rule file is a list of imperative statements starting with "Always" or "Never":

```markdown
# Backend Rules

Always use strict TypeScript with explicit return types. Never use `any`.
Always use async/await. Never use raw Promises or callbacks.
Always follow hexagonal architecture: Controller → Service → Repository.
...
```

## How Claude uses them

Rules are loaded automatically via Claude Code's rules system. You don't need to reference them — Claude reads them at the start of every session and follows them throughout.

## Tier 2: Standards

For deeper reference, Claude loads [Standards](/vibe/standards/typescript/) on demand — only when working on code that needs specific guidance. This keeps context usage efficient.

| Tier          | Content                  | Context usage | Loaded when              |
| ------------- | ------------------------ | ------------- | ------------------------ |
| 1 — Rules     | ~150 lines, ~2600 tokens | Always        | Every session            |
| 2 — Standards | 12 detailed docs         | On-demand     | When relevant skill runs |

## Customizing rules

Edit any file in `.claude/rules/` to add or modify conventions. Rules should be:

- **Imperative** — "Always..." or "Never..."
- **Specific** — one convention per line
- **Actionable** — Claude can follow them without ambiguity
