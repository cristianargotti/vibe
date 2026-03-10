# Vibe — Claude Code Configuration Template

Claude Code configuration template for Dafiti engineering teams. Get best practices, security rules, design patterns, hooks, skills, MCP servers, and GitHub automation from day one.

## Quick Start

### New project (use as template)

1. Click **"Use this template"** on GitHub
2. Clone your new repo
3. Run setup:

```bash
npm install
chmod +x hooks/*.sh
cp .claude/settings.local.json.example .claude/settings.local.json
claude
```

### Existing project (add to your repo)

```bash
git clone https://github.com/dafiti/vibe.git /tmp/vibe
cd /path/to/your/project
bash /tmp/vibe/setup.sh .
rm -rf /tmp/vibe
```

The setup script will:
- Copy `.claude/`, `hooks/`, `docs/standards/`, `.github/`, `CLAUDE.md`, `REVIEW.md`, `.mcp.json`
- Smart-merge your `.gitignore` (append missing entries)
- Add ESLint/Prettier to your `package.json`
- Create `.claude/settings.local.json` from template
- Set `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=90` in your shell profile

## Two-Tier Architecture

Vibe uses a performance-optimized two-tier system to keep Claude's context budget lean:

### Tier 1: Rules (always loaded, ~150 lines)

Files in `.claude/rules/` are loaded **eagerly at startup**. They contain lean "Always/Never" directives — no code examples, no verbose explanations:

| File | Lines | Scope |
|------|-------|-------|
| `security.md` | ~15 | Injection, auth, LGPD, XSS |
| `backend.md` | ~12 | TypeScript, NestJS, Python, DB |
| `frontend.md` | ~11 | React, Next.js, state management |
| `infra.md` | ~11 | Docker, Terraform, AWS |
| `quality.md` | ~13 | Testing, git, API, observability |

**Total startup cost: ~2,600 tokens** — leaves 197,000+ tokens for actual work.

### Tier 2: Standards (on-demand, detailed)

Files in `docs/standards/` contain **full patterns with code examples**. Claude reads them when working on specific tech:

| File | Covers |
|------|--------|
| `typescript.md` | Strict mode, Zod, error classes, discriminated unions |
| `nestjs.md` | Hexagonal arch, Controllers, DTOs, Guards, Interceptors |
| `react-nextjs.md` | Hooks, TanStack Query, Zustand, Server Components |
| `python.md` | Type hints, Pydantic v2, async, structlog, FastAPI |
| `docker.md` | Multi-stage builds, compose, non-root, healthchecks |
| `terraform.md` | Module structure, remote state, tagging, workspaces |
| `aws.md` | IAM, S3, VPC, Secrets Manager, CloudWatch |
| `database.md` | TypeORM, Prisma, SQLAlchemy, Redis cache-aside |
| `llm-ai.md` | Prompts, RAG, embeddings, guardrails, evals |
| `observability.md` | pino, structlog, OpenTelemetry, RED metrics |
| `api-design.md` | REST, pagination, errors, rate limiting, idempotency |
| `testing.md` | Vitest, pytest, mocking, testcontainers, Playwright |

## Available Skills & Commands

### Commands (stable)
| Command | Description |
|---------|-------------|
| `/create-pr [base]` | Analyze diff, generate PR with title/description/test plan |
| `/test <path>` | Generate tests (happy/edge/error), run and report coverage |

### Skills (advanced features)
| Skill | Model | Features | Description |
|-------|-------|----------|-------------|
| `/review-security` | Opus | context:fork | OWASP-based security review |
| `/fix-issue <number>` | Opus | — | Read GitHub issue, implement fix, add tests |
| `/refactor <path>` | Sonnet | context:fork | Refactor preserving behavior, verify with tests |
| `/deploy-check` | Sonnet | — | Pre-deployment verification checklist |

## Specialized Agents

| Agent | Purpose |
|-------|---------|
| `code-reviewer` | Reviews `git diff` against rules and standards |
| `ecommerce-expert` | Dafiti domain expert: catalog, cart, payments (PIX, Boleto), LGPD |
| `infra-reviewer` | Terraform, Docker security, AWS cost optimization |

## Hooks

| Hook | Trigger | Action |
|------|---------|--------|
| `block-dangerous-commands.sh` | Pre-Bash | Blocks `rm -rf /`, `DROP TABLE`, force push to main, `chmod 777`, etc. |
| `post-edit-lint.sh` | Post-Edit/Write | Auto-formats: Prettier (JS/TS), ruff (Python), `terraform fmt` (.tf) |
| Stop prompt | On stop | Verifies tests passed, no security issues, conventions followed |

## MCP Servers

| Server | Purpose | API Key |
|--------|---------|---------|
| GitHub | Repo management, issues, PRs | `GITHUB_TOKEN` |
| Context7 | Up-to-date library documentation | None needed |
| Sequential Thinking | Structured reasoning for complex problems | None needed |

## GitHub Automation

### Workflows
- **claude-pr-review.yml** — Automatic code review on PR open/sync and @claude mentions
- **claude-security-review.yml** — Security scan on every PR
- **claude-issue-handler.yml** — Handles @claude mentions + labels (`claude-fix`, `claude-feature`, `claude-refactor`)

### Setup
Add `ANTHROPIC_API_KEY` to your GitHub repo secrets:
```
Settings → Secrets and variables → Actions → New repository secret
```

## Context Management Tips

- **`/compact`** — Run proactively during long sessions to compress context
- **`/clear`** — Use between unrelated tasks to start fresh
- **`CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=90`** — Set in shell profile to auto-compact at 90% context usage
- **Subdirectory CLAUDE.md** — For monorepos, create a `CLAUDE.md` in each service directory with service-specific instructions

### Built-in Skills Reference
- `/batch` — Process multiple files with the same operation
- `/simplify` — Review changed code for reuse, quality, and efficiency

## Using with Other AI Tools

The `docs/standards/` files are pure markdown, reusable by any AI coding tool:

- **Cursor** — Add `docs/standards/` to your `.cursorrules` or reference in `.cursor/rules/`
- **GitHub Copilot** — Reference standards in `.github/copilot-instructions.md`
- **Windsurf** — Add to `.windsurfrules`
- **Codex** — Reference in `AGENTS.md`
- **Antigravity** — Reference in project configuration

## Tech Stack

| Layer | Technologies |
|-------|-------------|
| Backend | TypeScript, NestJS, Python, FastAPI |
| Frontend | React, Next.js (App Router), TanStack Query, Zustand |
| Data/ML | Python, Pydantic, LangChain |
| Infra | Docker, Terraform, AWS (S3, IAM, VPC, ECS), CloudFormation |
| Testing | Vitest, Jest, pytest, Playwright |
| Observability | pino, structlog, OpenTelemetry |

## License

MIT
