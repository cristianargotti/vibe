# Vibe — Dafiti Engineering Standards Plugin

Claude Code plugin for Dafiti engineering teams. Enforces security, architecture, and quality standards with interactive configuration, automated hooks, and specialized skills.

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

Run `/vibe:setup` to launch the interactive wizard. It guides you through:

1. **Tech Stack** — TypeScript/NestJS, React/Next.js, Python/FastAPI, Terraform/AWS, Docker
2. **Security Level** — Basic, Standard, or Strict
3. **Integrations** — GitHub MCP, GitHub Actions, Context7, Sequential Thinking
4. **Skills** — Choose which skills to enable

Configuration is saved to `vibe.config.json` (gitignored, project-specific).

## Security Levels

| Feature | Basic | Standard | Strict |
| --- | --- | --- | --- |
| Rules in `.claude/rules/` | Yes | Yes | Yes |
| Block dangerous commands | No | Yes | Yes |
| Post-edit auto-format | No | Yes | Yes |
| Workflow guard (branch/commit) | No | No | Yes |
| Branch protection (Edit/Write) | No | No | Yes |
| Secret scanning on commit | No | No | Yes |
| Stop verification prompt | No | No | Yes |
| Native git hooks | No | No | Yes |
| Session startup validation | No | No | Yes |

## Plugin Skills

| Skill | Description |
| --- | --- |
| `/vibe:setup` | Interactive configuration wizard |
| `/vibe:review-security` | OWASP-based security review |
| `/vibe:deploy-check` | Pre-deployment verification checklist |
| `/vibe:fix-issue <number>` | Fix GitHub issue with tests |
| `/vibe:refactor <path>` | Refactor preserving behavior |
| `/vibe:create-pr [base]` | Structured PR creation |
| `/vibe:test <path>` | Generate and run tests |
| `/vibe:health-check` | Validate plugin configuration |
| `/vibe:whats-new` | Check Claude Code updates |

## Hooks

| Hook | Trigger | Action |
| --- | --- | --- |
| `block-dangerous-commands.sh` | Pre-Bash | Blocks `rm -rf /`, `DROP TABLE`, force push, `chmod 777` |
| `workflow-guard.sh` | Pre-Bash | Blocks commit on main, `--no-verify`, bad branches, secrets |
| `branch-guard.sh` | Pre-Edit/Write | Blocks file modifications on protected branches |
| `post-edit-lint.sh` | Post-Edit/Write | Auto-formats: Prettier (JS/TS), ruff (Python), `terraform fmt` |
| `validate-config.sh` | SessionStart | Lightweight config validation at session start |
| Stop prompt | On stop | Verifies tests, security, conventions |
| `git-hooks/pre-commit` | Native git | Branch protection + secret detection |
| `git-hooks/commit-msg` | Native git | Conventional commit validation |

## Specialized Agents

| Agent | Purpose |
| --- | --- |
| `code-reviewer` | Reviews `git diff` against rules and standards |
| `ecommerce-expert` | Dafiti domain: catalog, cart, payments (PIX, Boleto), LGPD |
| `infra-reviewer` | Terraform, Docker security, AWS cost optimization |

## Two-Tier Architecture

### Tier 1: Rules (always loaded, ~150 lines)

Files in `.claude/rules/` — lean "Always/Never" directives. Total startup cost: ~2,600 tokens.

### Tier 2: Standards (on-demand, detailed)

Files in `docs/standards/` — full patterns with code examples. Claude reads them when working on specific tech.

## Health Check (3 layers of resilience)

1. **CI/CD** — `validate-plugin.yml` validates JSON, frontmatter, scripts on every push + weekly version check
2. **On-demand** — `/vibe:health-check` validates all components with detailed report
3. **Session startup** — `validate-config.sh` runs at session start (<100ms, non-blocking)

## GitHub Automation

- **claude-pr-review.yml** — Automatic code review on PR open/sync
- **claude-security-review.yml** — Security scan on every PR
- **claude-issue-handler.yml** — Handles labels (`claude-fix`, `claude-feature`, `claude-refactor`)
- **validate-plugin.yml** — Plugin structure validation + version tracking

Add `CLAUDE_CODE_OAUTH_TOKEN` to repo secrets (from `claude setup-token`).

## For Admins

### Enterprise Lockdown

Deploy `managed-settings.json` to restrict to Dafiti marketplace only:

**macOS**: `/Library/Application Support/ClaudeCode/managed-settings.json`
**Linux**: `/etc/claude-code/managed-settings.json`

```json
{
  "strictKnownMarketplaces": [
    {
      "source": "github",
      "repo": "dafiti-group/vibe"
    }
  ]
}
```

### Auth Requirement

Each developer needs `GITHUB_TOKEN` or `gh auth login` for the private marketplace.

## Plugin Architecture

```
vibe/
├── .claude-plugin/          # Plugin manifest + marketplace
├── skills/                  # 9 skills (setup, review-security, etc.)
├── agents/                  # 3 specialized agents
├── hooks/                   # Hook scripts + hooks.json config
├── docs/standards/          # 12 detailed standard files
├── .claude/rules/           # 5 lean rule files
├── .github/workflows/       # 4 CI/CD workflows
├── settings.json            # Plugin-level default permissions
├── CLAUDE.md                # Main configuration hub
├── REVIEW.md                # Code review guidelines
└── .claude-code-version     # Version tracker
```

## License

MIT
