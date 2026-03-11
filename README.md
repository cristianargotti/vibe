# Vibe — Dafiti Engineering Standards Plugin

Claude Code plugin for Dafiti engineering teams. Security, architecture, and quality standards — configured interactively, enforced automatically.

## What is Vibe

Vibe is a **Claude Code plugin** that brings Dafiti's engineering standards into every coding session. It provides:

- **Interactive setup** — `/vibe:setup` wizard configures your project in seconds
- **Automated guards** — Hooks that prevent dangerous commands, enforce branch protection, scan for secrets
- **Specialized skills** — Security reviews, deployment checks, PR creation, issue fixing
- **Domain expertise** — Agents that understand e-commerce, LGPD compliance, and Latin American payments
- **Living standards** — 12 detailed coding standards covering TypeScript, Python, React, Terraform, AWS, and more

## Installation

### As a Claude Code Plugin (recommended)

```
/plugin marketplace add dafiti-group/vibe
/plugin install vibe
/vibe:setup
```

### Manual Setup (legacy)

```bash
git clone https://github.com/dafiti-group/vibe.git /tmp/vibe
cd /path/to/your/project
bash /tmp/vibe/setup.sh .
rm -rf /tmp/vibe
```

## Configuration

Run `/vibe:setup` to launch the interactive wizard. It configures everything in 4 steps:

### 1. Tech Stack

```
Which technologies does this project use?

[ ] TypeScript / NestJS (backend)
[ ] React / Next.js (frontend)
[ ] Python / FastAPI
[ ] Terraform / AWS (infra)
[ ] Docker
```

### 2. Security Level

```
What security level do you want?

( ) Basic    — Rules only (no hooks)
( ) Standard — Rules + block dangerous commands + post-edit lint
( ) Strict   — Full protection: workflow guard, branch protection, secrets scan
```

### 3. Integrations

```
Which integrations to enable?

[ ] GitHub MCP (PRs, issues from Claude)
[ ] GitHub Actions (PR review, security review, issue handler)
[ ] Context7 MCP (contextual documentation)
[ ] Sequential Thinking MCP
```

### 4. Skills Selection

Choose which `/vibe:*` skills to activate.

Configuration is saved to `vibe.config.json` (gitignored, per-project).

## Security Levels

| Feature | Basic | Standard | Strict |
| --- | :---: | :---: | :---: |
| Rules in `.claude/rules/` | Yes | Yes | Yes |
| Block dangerous commands | — | Yes | Yes |
| Post-edit auto-format | — | Yes | Yes |
| Workflow guard (branch/commit) | — | — | Yes |
| Branch protection (Edit/Write) | — | — | Yes |
| Secret scanning on commit | — | — | Yes |
| Stop verification prompt | — | — | Yes |
| Native git hooks | — | — | Yes |
| Session startup validation | — | — | Yes |

## Plugin Skills

| Skill | Description | Model |
| --- | --- | --- |
| `/vibe:setup` | Interactive configuration wizard | — |
| `/vibe:review-security` | OWASP-based security review | Opus |
| `/vibe:deploy-check` | Pre-deployment verification checklist | Sonnet |
| `/vibe:fix-issue <number>` | Fix GitHub issue with tests | Opus |
| `/vibe:refactor <path>` | Refactor preserving behavior | Sonnet |
| `/vibe:create-pr [base]` | Structured PR creation | — |
| `/vibe:test <path>` | Generate and run tests | — |
| `/vibe:health-check` | Validate plugin configuration | — |
| `/vibe:whats-new` | Check Claude Code updates | — |

### Bundled Skills (built into Claude Code)

| Skill | Description |
| --- | --- |
| `/simplify` | Review changed code for reuse and efficiency |
| `/batch <instruction>` | Orchestrate parallel changes across codebase |
| `/loop [interval] <prompt>` | Run recurring prompts on schedule |
| `/debug [description]` | Troubleshoot Claude Code session |
| `/claude-api` | Claude API reference for building apps |

## Hooks

| Hook | Trigger | Action |
| --- | --- | --- |
| `block-dangerous-commands.sh` | Pre-Bash | Blocks `rm -rf /`, `DROP TABLE`, force push to main, `chmod 777`, `terraform destroy -auto-approve`, `curl\|bash` |
| `workflow-guard.sh` | Pre-Bash | Blocks commit on main/master/develop, `--no-verify`, bad branch names, non-conventional commits, secrets in staged diff |
| `branch-guard.sh` | Pre-Edit/Write | Blocks file modifications on main/master/develop |
| `post-edit-lint.sh` | Post-Edit/Write | Auto-formats: Prettier (JS/TS/JSON/MD), ruff (Python), `terraform fmt` (.tf) |
| `validate-config.sh` | SessionStart | Lightweight config validation (<100ms, non-blocking) |
| Stop prompt | On stop | Verifies tests passed, no security issues, conventions followed |
| `git-hooks/pre-commit` | Native git | Branch protection + secret detection (works outside Claude too) |
| `git-hooks/commit-msg` | Native git | Conventional commit validation (works outside Claude too) |

## Specialized Agents

| Agent | Purpose |
| --- | --- |
| `code-reviewer` | Reviews `git diff` against rules — security → correctness → architecture → quality |
| `ecommerce-expert` | Dafiti domain: catalog, cart/checkout, payments (PIX, Boleto, credit card), shipping, LGPD |
| `infra-reviewer` | Terraform modules, Docker security, AWS IAM/S3/VPC, cost optimization |

## MCP Servers

| Server | Purpose | Auth |
| --- | --- | --- |
| GitHub | Repo management, issues, PRs from Claude | `GITHUB_TOKEN` |
| Context7 | Up-to-date library documentation | None |
| Sequential Thinking | Structured reasoning for complex problems | None |

## Two-Tier Architecture

### Tier 1: Rules (always loaded, ~150 lines)

Files in `.claude/rules/` are loaded eagerly at startup. Lean "Always/Never" directives:

| File | Lines | Scope |
| --- | --- | --- |
| `security.md` | ~15 | Injection, auth, LGPD, XSS |
| `backend.md` | ~12 | TypeScript, NestJS, Python, DB |
| `frontend.md` | ~11 | React, Next.js, state management |
| `infra.md` | ~11 | Docker, Terraform, AWS |
| `quality.md` | ~13 | Testing, git, API, observability |

**Total startup cost: ~2,600 tokens** — leaves 197,000+ tokens for actual work.

### Tier 2: Standards (on-demand, detailed)

Files in `docs/standards/` contain full patterns with code examples. Claude reads them when working on specific tech:

| File | Covers |
| --- | --- |
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

## Health Check (3 layers of resilience)

### Layer 1: CI/CD — `validate-plugin.yml`

- Runs on every push to `skills/`, `hooks/`, `agents/`, `.claude-plugin/`
- Validates: JSON files, YAML frontmatter, script permissions, agent files
- Weekly cron: checks for new Claude Code versions, creates issue with `claude-update` label

### Layer 2: On-demand — `/vibe:health-check`

- Full validation of all 34+ components
- Reports PASS/WARN/FAIL per component
- Overall status: HEALTHY / NEEDS ATTENTION / BROKEN

### Layer 3: Session startup — `validate-config.sh`

- Runs at every session start via `SessionStart` hook
- Lightweight (<100ms), non-blocking
- Checks: CLAUDE.md, rules, settings.json, vibe.config.json

## Auto-updates

Vibe tracks the installed Claude Code version in `.claude-code-version`.

- **Weekly CI check**: `validate-plugin.yml` compares tracked vs latest npm version
- **On-demand**: `/vibe:whats-new` searches for changelog and analyzes impact on Vibe config
- **Manual update**: `/plugin marketplace update` pulls latest Vibe from marketplace

When a new Claude Code version is detected with potential breaking changes, an issue is auto-created with the `claude-update` label.

## GitHub Automation

| Workflow | Trigger | Action |
| --- | --- | --- |
| `claude-pr-review.yml` | PR open/sync, @claude | Code review against rules and REVIEW.md |
| `claude-security-review.yml` | PR open/sync | OWASP security scan + LGPD checks |
| `claude-issue-handler.yml` | Labels, @claude | Auto-fix/feature/refactor from issues |
| `validate-plugin.yml` | Push to plugin files, weekly | Plugin structure validation + version tracking |

### Setup

Add `CLAUDE_CODE_OAUTH_TOKEN` to your GitHub repo secrets:

```
Settings → Secrets and variables → Actions → New repository secret
Name: CLAUDE_CODE_OAUTH_TOKEN
Value: (from `claude setup-token`)
```

## For Admins

### Enterprise Lockdown

Deploy `managed-settings.json` to restrict to Dafiti-approved plugins only:

**macOS**: `/Library/Application Support/ClaudeCode/managed-settings.json`
**Linux**: `/etc/claude-code/managed-settings.json`

```json
{
  "strictKnownMarketplaces": [
    {
      "source": "github",
      "repo": "dafiti-group/vibe"
    },
    {
      "source": "hostPattern",
      "hostPattern": "^github\\.com/dafiti-group/"
    }
  ],
  "pluginTrustMessage": "Solo plugins aprobados por AI Core Team — Dafiti."
}
```

This blocks any marketplace not from `dafiti-group`. Cannot be overridden by users.

### Auth Requirement

Each developer needs `GITHUB_TOKEN` or `gh auth login` for the private marketplace.

### Auto-discovery

When `/vibe:setup` runs, it adds to the project's `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "dafiti-tools": {
      "source": { "source": "github", "repo": "dafiti-group/vibe" }
    }
  },
  "enabledPlugins": {
    "vibe@dafiti-tools": true
  }
}
```

New team members opening the project get prompted to install Vibe automatically.

## Contributing

### Adding a new skill

1. Create `skills/my-skill/SKILL.md` with YAML frontmatter:

```yaml
---
name: my-skill
description: What this skill does
argument-hint: "<arg>"
allowed-tools: Read, Grep, Glob, Bash
---
```

2. Add the skill path to `.claude-plugin/plugin.json` → `skills` array
3. Run `/vibe:health-check` to validate
4. Submit PR

### Adding a new hook

1. Create `hooks/my-hook.sh` (must read stdin, output JSON `{"decision":"allow"}` or `{"decision":"deny","reason":"..."}`)
2. Add to `hooks/hooks.json` under the appropriate event
3. Make executable: `chmod +x hooks/my-hook.sh`
4. Submit PR

### Adding a new agent

1. Create `agents/my-agent.md` with role description, behavior, and output format
2. Add the agent path to `.claude-plugin/plugin.json` → `agents` array
3. Submit PR

## Plugin Architecture

```
vibe/
├── .claude-plugin/              # Plugin manifest + marketplace catalog
│   ├── plugin.json
│   └── marketplace.json
├── skills/                      # 9 plugin skills
│   ├── setup/                   # Interactive wizard + templates
│   │   ├── SKILL.md
│   │   └── templates/           # CLAUDE.md, rules, mcp, settings, workflows
│   ├── review-security/
│   ├── deploy-check/
│   ├── fix-issue/
│   ├── refactor/
│   ├── create-pr/
│   ├── test/
│   ├── health-check/            # + scripts/validate.sh
│   └── whats-new/
├── agents/                      # 3 specialized agents
│   ├── code-reviewer.md
│   ├── ecommerce-expert.md
│   └── infra-reviewer.md
├── hooks/                       # Hook scripts + config
│   ├── hooks.json               # Centralized hook definitions
│   ├── block-dangerous-commands.sh
│   ├── workflow-guard.sh
│   ├── branch-guard.sh
│   ├── post-edit-lint.sh
│   ├── validate-config.sh
│   └── git-hooks/               # Native git hooks
│       ├── pre-commit
│       └── commit-msg
├── docs/standards/              # 12 detailed standard files
├── .claude/rules/               # 5 lean rule files (always loaded)
├── .github/workflows/           # 4 CI/CD workflows
├── settings.json                # Plugin-level default permissions
├── CLAUDE.md                    # Main configuration hub
├── REVIEW.md                    # Code review guidelines
├── .claude-code-version         # Version tracker
└── LICENSE                      # MIT
```

## Context Management Tips

- **`/compact`** — Run proactively during long sessions to compress context
- **`/clear`** — Use between unrelated tasks to start fresh
- **`CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=90`** — Auto-compact at 90% context usage
- **Subdirectory CLAUDE.md** — For monorepos, create per-service CLAUDE.md files

## Using with Other AI Tools

The `docs/standards/` files are pure markdown, reusable by any AI coding tool:

- **Cursor** — Add `docs/standards/` to `.cursorrules` or `.cursor/rules/`
- **GitHub Copilot** — Reference in `.github/copilot-instructions.md`
- **Windsurf** — Add to `.windsurfrules`
- **Codex** — Reference in `AGENTS.md`

## Tech Stack

| Layer | Technologies |
| --- | --- |
| Backend | TypeScript, NestJS, Python, FastAPI |
| Frontend | React, Next.js (App Router), TanStack Query, Zustand |
| Data/ML | Python, Pydantic, LangChain |
| Infra | Docker, Terraform, AWS (S3, IAM, VPC, ECS), CloudFormation |
| Testing | Vitest, Jest, pytest, Playwright |
| Observability | pino, structlog, OpenTelemetry |

## License

MIT
