# Vibe — Dafiti Engineering Standards Plugin

Claude Code plugin for Dafiti engineering teams. Security, architecture, and quality standards — configured interactively, enforced automatically.

**[Documentation](https://cristianargotti.github.io/vibe/)** | **[Getting Started](https://cristianargotti.github.io/vibe/getting-started/introduction/)**

## What is Vibe

Vibe is a **Claude Code plugin** that brings Dafiti's engineering standards into every coding session:

- **Interactive setup** — `/vibe:setup` wizard configures your project in seconds
- **Automated guards** — Hooks that prevent dangerous commands, enforce branch protection, scan for secrets
- **Specialized skills** — Security reviews, deployment checks, PR creation, issue fixing
- **Domain expertise** — Agents that understand e-commerce, LGPD compliance, and Latin American payments
- **Living standards** — 12 detailed coding standards covering TypeScript, Python, React, Terraform, AWS, and more

## Installation

```
/plugin marketplace add dafiti-group/vibe
/plugin install vibe
/vibe:setup
```

That's it. The wizard handles everything else.

## Usage Examples

### Configure a new project

```
> /vibe:setup

Which technologies does this project use?
  [x] TypeScript / NestJS (backend)
  [x] React / Next.js (frontend)

What security level?
  ( ) Basic
  (x) Standard
  ( ) Strict

Vibe Setup Complete!
  CLAUDE.md              — Project configuration hub
  .claude/rules/         — 5 rule files (backend, frontend, security, quality, infra)
  .claude/settings.json  — Permissions + hooks
  .mcp.json              — GitHub + Context7 MCP servers
  docs/standards/        — 12 detailed coding standards
```

### Review security before a release

```
> /vibe:review-security

Security Review — OWASP Top 10

Critical:
  src/auth/login.controller.ts:42 — SQL concatenation in user lookup
  Recommendation: Use parameterized query with repository pattern

High:
  src/payments/pix.service.ts:18 — PII (CPF) logged in plain text
  Recommendation: Redact PII before logging (LGPD requirement)

Passing:
  JWT implementation uses short-lived tokens (15min) with refresh
  All API endpoints have input validation via DTOs
```

### Fix a GitHub issue

```
> /vibe:fix-issue 42

Reading issue #42: "Cart total doesn't account for PIX discount"
Analyzing src/cart/cart.service.ts...
Root cause: discount applied after tax instead of before

Fix applied:
  src/cart/cart.service.ts — Reorder discount/tax calculation
  src/cart/cart.service.test.ts — Added 3 regression tests

Commit: fix: apply PIX discount before tax calculation (Fixes #42)
```

### Create a PR with standards

```
> /vibe:create-pr

Analyzing changes: 4 files, 127 lines
Pushing branch feat/fix-cart-discount...

Created PR #15: fix: apply PIX discount before tax calculation
  https://github.com/dafiti-group/my-service/pull/15

  following AI-CORE-STANDARDS
```

### Pre-deployment check

```
> /vibe:deploy-check

Linting          — PASS
Type checking    — PASS
Test coverage    — PASS (87%)
Security audit   — PASS (0 vulnerabilities)
Docker build     — PASS
Outdated deps    — WARN (3 packages outdated)

DEPLOY STATUS: READY
Warnings: 3 outdated packages (non-blocking)
```

### Validate plugin health

```
> /vibe:health-check

Plugin:    PASS  plugin.json + marketplace.json valid
Hooks:     PASS  5/5 scripts executable
Skills:    PASS  9/9 SKILL.md with valid frontmatter
Agents:    PASS  3/3 non-empty
Settings:  PASS  Valid JSON
Standards: PASS  12/12 files present
Version:   PASS  2.1.72

Status: HEALTHY (34/34 checks passed)
```

## How It Works

### When Vibe is installed as a plugin:

1. **Skills** (`skills/*/SKILL.md`) become available as `/vibe:*` slash commands
2. **Hooks** (`hooks/hooks.json`) activate automatically — blocking dangerous commands, enforcing branch protection, auto-formatting
3. **Agents** (`agents/*.md`) are available for specialized code review, e-commerce domain knowledge, and infra review
4. **Permissions** (`settings.json`) provide sensible defaults for tool access

### When `/vibe:setup` runs in a target project:

1. Generates `CLAUDE.md` tailored to the selected tech stack
2. Copies relevant `.claude/rules/` (lean directives, always loaded)
3. Copies `docs/standards/` (detailed patterns, loaded on-demand)
4. Configures `.claude/settings.json` with permissions + hooks based on security level
5. Sets up `.mcp.json` with selected integrations
6. Optionally copies GitHub Actions workflows and native git hooks
7. Saves preferences to `vibe.config.json` for reconfiguration

## Configuration

### `/vibe:setup` Wizard

The interactive wizard configures everything in 4 steps:

**Step 1 — Tech Stack**: TypeScript/NestJS, React/Next.js, Python/FastAPI, Terraform/AWS, Docker

**Step 2 — Security Level**: Basic (rules only), Standard (+ hooks), Strict (+ full protection)

**Step 3 — Integrations**: GitHub MCP, GitHub Actions, Context7 MCP, Sequential Thinking MCP, AWS MCP, ESLint MCP, Terraform MCP

**Step 4 — Skills**: Choose which `/vibe:*` skills to enable

Configuration is saved to `vibe.config.json` (gitignored, per-project). Run `/vibe:setup` again to reconfigure.

## Security Levels

| Feature                        | Basic | Standard | Strict |
| ------------------------------ | :---: | :------: | :----: |
| Rules in `.claude/rules/`      |  Yes  |   Yes    |  Yes   |
| Block dangerous commands       |   —   |   Yes    |  Yes   |
| Post-edit auto-format          |   —   |   Yes    |  Yes   |
| Workflow guard (branch/commit) |   —   |    —     |  Yes   |
| Branch protection (Edit/Write) |   —   |    —     |  Yes   |
| Secret scanning on commit      |   —   |    —     |  Yes   |
| Stop verification prompt       |   —   |    —     |  Yes   |
| Native git hooks               |   —   |    —     |  Yes   |
| Session startup validation     |   —   |    —     |  Yes   |

## Plugin Skills

| Skill                      | Description                           | Model  |
| -------------------------- | ------------------------------------- | ------ |
| `/vibe:setup`              | Interactive configuration wizard      | —      |
| `/vibe:review-security`    | OWASP-based security review           | Opus   |
| `/vibe:deploy-check`       | Pre-deployment verification checklist | Sonnet |
| `/vibe:fix-issue <number>` | Fix GitHub issue with tests           | Opus   |
| `/vibe:refactor <path>`    | Refactor preserving behavior          | Sonnet |
| `/vibe:create-pr [base]`   | Structured PR creation                | —      |
| `/vibe:test <path>`        | Generate and run tests                | —      |
| `/vibe:health-check`       | Validate plugin configuration         | —      |
| `/vibe:whats-new`          | Check Claude Code updates             | —      |

### Bundled Skills (built into Claude Code)

| Skill                       | Description                                  |
| --------------------------- | -------------------------------------------- |
| `/simplify`                 | Review changed code for reuse and efficiency |
| `/batch <instruction>`      | Orchestrate parallel changes across codebase |
| `/loop [interval] <prompt>` | Run recurring prompts on schedule            |
| `/debug [description]`      | Troubleshoot Claude Code session             |
| `/claude-api`               | Claude API reference for building apps       |

## Hooks

| Hook                          | Trigger         | What it blocks                                                                                                   |
| ----------------------------- | --------------- | ---------------------------------------------------------------------------------------------------------------- |
| `block-dangerous-commands.sh` | Pre-Bash        | `rm -rf /`, `DROP TABLE`, force push, `chmod 777`, `terraform destroy -auto-approve`, `curl\|bash`               |
| `workflow-guard.sh`           | Pre-Bash        | Commit on main/master/develop, `--no-verify`, bad branch names, non-conventional commits, secrets in staged diff |
| `branch-guard.sh`             | Pre-Edit/Write  | File modifications on main/master/develop                                                                        |
| `post-edit-lint.sh`           | Post-Edit/Write | _(formats)_ Prettier (JS/TS/JSON/MD), ruff (Python), `terraform fmt` (.tf)                                       |
| `validate-config.sh`          | SessionStart    | _(validates)_ CLAUDE.md, rules, settings, vibe.config.json                                                       |
| Stop prompt                   | On stop         | _(verifies)_ Tests passed, no security issues, conventions followed                                              |
| `git-hooks/pre-commit`        | Native git      | Branch protection + secret detection (works outside Claude)                                                      |
| `git-hooks/commit-msg`        | Native git      | Conventional commit validation (works outside Claude)                                                            |

## Specialized Agents

| Agent              | Purpose                                                                                    |
| ------------------ | ------------------------------------------------------------------------------------------ |
| `code-reviewer`    | Reviews `git diff` against rules — security, correctness, architecture, quality            |
| `ecommerce-expert` | Dafiti domain: catalog, cart/checkout, payments (PIX, Boleto, credit card), shipping, LGPD |
| `infra-reviewer`   | Terraform modules, Docker security, AWS IAM/S3/VPC, cost optimization                      |

## MCP Servers

| Server              | Purpose                                   | Auth           | Transport |
| ------------------- | ----------------------------------------- | -------------- | --------- |
| GitHub              | Repo management, issues, PRs from Claude  | `GITHUB_TOKEN` | Docker    |
| Context7            | Up-to-date library documentation          | None           | npx       |
| Sequential Thinking | Structured reasoning for complex problems | None           | npx       |
| AWS _(optional)_    | S3, IAM, VPC, CloudFormation management   | `AWS_PROFILE`  | uvx       |
| ESLint _(optional)_ | Lint diagnostics integrated in Claude     | None           | npx       |
| Terraform _(opt.)_  | Plan/validate/apply via Docker            | None           | Docker    |

## Two-Tier Architecture

### Tier 1: Rules (always loaded, ~150 lines)

Files in `.claude/rules/` — lean "Always/Never" directives. Loaded eagerly at startup.

| File          | Scope                                             |
| ------------- | ------------------------------------------------- |
| `security.md` | Injection, auth, LGPD, XSS, CSRF, secrets         |
| `backend.md`  | TypeScript strict, hexagonal arch, DI, logging    |
| `frontend.md` | React hooks, Server Components, accessibility     |
| `infra.md`    | Docker multi-stage, Terraform modules, IAM        |
| `quality.md`  | Testing 80%, conventional commits, PRs <400 lines |

**Total startup cost: ~2,600 tokens** — leaves 197,000+ for actual work.

### Tier 2: Standards (on-demand, detailed)

Files in `docs/standards/` — full patterns with code examples. Claude reads them when working on specific tech:

`typescript.md` `nestjs.md` `react-nextjs.md` `python.md` `docker.md` `terraform.md` `aws.md` `database.md` `llm-ai.md` `observability.md` `api-design.md` `testing.md`

## Health Check — 3 Layers of Resilience

| Layer     | What                  | When                     | Behavior                                                                             |
| --------- | --------------------- | ------------------------ | ------------------------------------------------------------------------------------ |
| CI/CD     | `validate-plugin.yml` | Every push + weekly cron | Validates JSON, frontmatter, scripts. Creates `claude-update` issue on version drift |
| On-demand | `/vibe:health-check`  | Manual                   | Full 34-component validation with PASS/WARN/FAIL report                              |
| Session   | `validate-config.sh`  | Every session start      | Lightweight (<100ms), non-blocking. Notifies if config is missing                    |

## Auto-updates

Vibe has 6 layers of auto-updating to stay current without manual intervention:

| Layer          | Component                | Mechanism                      | Frequency |
| -------------- | ------------------------ | ------------------------------ | --------- |
| npm deps       | eslint, prettier         | Dependabot PRs                 | Weekly    |
| GitHub Actions | checkout, claude-code    | Dependabot PRs                 | Weekly    |
| MCP servers    | github, context7, aws... | `check-mcp-versions.yml`       | Weekly    |
| Claude Code    | CLI version              | `validate-plugin.yml`          | Weekly    |
| Secrets        | Detection patterns       | Manual + issue tracker         | As-needed |
| Plugin         | Vibe itself              | Plugin marketplace auto-update | On push   |

Version tracking is centralized in `versions.json` (replaces `.claude-code-version`).

- **Weekly CI**: compares tracked vs latest versions, creates issue on drift
- **On-demand**: `/vibe:whats-new` checks Claude Code changelog, MCP versions, and standards freshness
- **Plugin update**: `/plugin marketplace update` pulls latest Vibe
- **Standards review**: `check-mcp-versions.yml` flags standards not reviewed in 6+ months

## GitHub Automation

| Workflow                     | Trigger                      | Action                                  |
| ---------------------------- | ---------------------------- | --------------------------------------- |
| `claude-pr-review.yml`       | PR open/sync, @claude        | Code review against rules and REVIEW.md |
| `claude-security-review.yml` | PR open/sync                 | OWASP security scan + LGPD checks       |
| `claude-issue-handler.yml`   | Labels, @claude              | Auto-fix/feature/refactor from issues   |
| `validate-plugin.yml`        | Push to plugin files, weekly | Plugin structure + version validation   |
| `check-mcp-versions.yml`     | Weekly                       | MCP version drift + standards freshness |

### Setup

```
GitHub repo → Settings → Secrets → Actions → New repository secret
Name: CLAUDE_CODE_OAUTH_TOKEN
Value: (run `claude setup-token` to generate)
```

## For Admins

### Enterprise Lockdown

Deploy `managed-settings.json` to restrict to Dafiti-approved plugins only:

**macOS**: `/Library/Application Support/ClaudeCode/managed-settings.json`
**Linux**: `/etc/claude-code/managed-settings.json`

```json
{
  "strictKnownMarketplaces": [
    { "source": "github", "repo": "dafiti-group/vibe" },
    { "source": "hostPattern", "hostPattern": "^github\\.com/dafiti-group/" }
  ],
  "pluginTrustMessage": "Solo plugins aprobados por AI Core Team — Dafiti."
}
```

Blocks any marketplace not from `dafiti-group`. Cannot be overridden.

### Auto-discovery

`/vibe:setup` adds marketplace config to each project's `.claude/settings.json`. New team members get prompted to install Vibe automatically when they open a configured project.

### Auth Requirement

Each developer needs `GITHUB_TOKEN` or `gh auth login` for the private marketplace.

## Contributing

### Adding a skill

1. Create `skills/my-skill/SKILL.md` with YAML frontmatter
2. Add path to `.claude-plugin/plugin.json` → `skills` array
3. Run `/vibe:health-check` to validate
4. Submit PR

### Adding a hook

1. Create `hooks/my-hook.sh` (stdin → JSON `{"decision":"allow"|"deny"}`)
2. Add to `hooks/hooks.json` under the appropriate event
3. `chmod +x hooks/my-hook.sh`
4. Submit PR

### Adding an agent

1. Create `agents/my-agent.md` with role, behavior, output format
2. Add path to `.claude-plugin/plugin.json` → `agents` array
3. Submit PR

## Plugin Architecture

```
vibe/
├── .claude-plugin/              # Plugin manifest + marketplace
│   ├── plugin.json
│   └── marketplace.json
├── skills/                      # 9 plugin skills (/vibe:*)
│   ├── setup/                   # Interactive wizard
│   │   ├── SKILL.md
│   │   └── templates/           # CLAUDE.md, rules, mcp, settings, workflows
│   ├── review-security/         # OWASP security review
│   ├── deploy-check/            # Pre-deployment checklist
│   ├── fix-issue/               # GitHub issue fixer
│   ├── refactor/                # Behavior-preserving refactor
│   ├── create-pr/               # Structured PR creation
│   ├── test/                    # Test generation + execution
│   ├── health-check/            # Plugin validation
│   │   └── scripts/validate.sh
│   └── whats-new/               # Claude Code update checker
├── agents/                      # 3 specialized agents
│   ├── code-reviewer.md
│   ├── ecommerce-expert.md
│   └── infra-reviewer.md
├── hooks/                       # Safety hooks
│   ├── hooks.json               # Hook definitions (plugin-level)
│   ├── block-dangerous-commands.sh
│   ├── workflow-guard.sh
│   ├── branch-guard.sh
│   ├── post-edit-lint.sh
│   ├── validate-config.sh
│   ├── secret-patterns.txt      # 30+ secret detection patterns
│   └── git-hooks/               # Native git hooks (all clients)
│       ├── pre-commit
│       └── commit-msg
├── docs/standards/              # 12 detailed coding standards
├── .claude/rules/               # 5 lean rule files (always loaded)
├── .github/workflows/           # 5 CI/CD workflows
├── settings.json                # Plugin-level default permissions
├── versions.json                # Centralized version tracking
├── CLAUDE.md                    # Configuration hub
├── REVIEW.md                    # Code review guidelines
└── LICENSE
```

## Using Standards with Other AI Tools

The `docs/standards/` files are pure markdown, reusable by any AI coding tool:

- **Cursor** — Add to `.cursorrules` or `.cursor/rules/`
- **GitHub Copilot** — Reference in `.github/copilot-instructions.md`
- **Windsurf** — Add to `.windsurfrules`
- **Codex** — Reference in `AGENTS.md`

## License

MIT
