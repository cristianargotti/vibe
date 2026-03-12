---
name: setup
description: Interactive setup wizard for Vibe — configure tech stack, security level, integrations, and skills for your project.
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Glob, Bash, AskUserQuestion
---

# Vibe Setup Wizard

Interactive wizard that configures Vibe for the current project. Generates all necessary configuration files based on user preferences.

## Instructions

### Step 0: Check for Existing Configuration

Read `vibe.config.json` in the project root. If it exists, show current settings and ask if the user wants to reconfigure.

### Step 1: Tech Stack

Ask the user (use AskUserQuestion with multiSelect: true):

**Question**: "Which technologies does this project use?"
**Options**:

- TypeScript / NestJS (backend)
- React / Next.js (frontend)
- Python / FastAPI
- Terraform / AWS (infra)
- Docker

### Step 2: Security Level

Ask the user (use AskUserQuestion):

**Question**: "What security level do you want?"
**Options**:

- **Basic** — Rules in CLAUDE.md only (no hooks)
- **Standard** — Rules + block dangerous commands + post-edit lint
- **Strict** — Full protection: workflow guard, branch protection, secrets scan, stop verification

### Step 3: Integrations

Ask the user (use AskUserQuestion with multiSelect: true):

**Question**: "Which integrations should be enabled?"
**Options**:

- GitHub MCP (PRs, issues from Claude — via Docker)
- GitHub Actions (PR review, security review, issue handler)
- Context7 MCP (contextual documentation)
- Sequential Thinking MCP
- AWS MCP (S3, IAM, VPC, CloudFormation — requires uvx)
- ESLint MCP (lint diagnostics in Claude)
- Terraform MCP (plan/validate/apply via Docker)

### Step 4: Skills

Ask the user (use AskUserQuestion with multiSelect: true):

**Question**: "Which skills to enable?"
**Options**:

- /vibe:review-security — OWASP security review
- /vibe:deploy-check — Pre-deployment checklist
- /vibe:fix-issue — Fix GitHub issues with tests
- /vibe:create-pr — Structured PR creation
- /vibe:fix-vulnerabilities — Fix Dependabot security vulnerabilities

(Note: /vibe:setup, /vibe:health-check, /vibe:whats-new, /vibe:test, /vibe:refactor are always enabled)

### Step 5: Generate Configuration

Based on responses, generate the following files in the target project:

#### 5a. `vibe.config.json`

Save all preferences for future reconfiguration.

#### 5b. `CLAUDE.md`

Read the appropriate template from the plugin:

- TypeScript + React → read `skills/setup/templates/claude-md/fullstack.md`
- TypeScript only → read `skills/setup/templates/claude-md/typescript.md`
- Python only → read `skills/setup/templates/claude-md/python.md`
- Infra only → read `skills/setup/templates/claude-md/infra.md`
- Mixed → combine relevant sections

Write the template content to `CLAUDE.md` in the project root.

#### 5c. `.claude/rules/`

Copy only the relevant rule files based on tech stack:

- TypeScript/NestJS → `backend.md`, `quality.md`, `security.md`
- React/Next.js → `frontend.md`, `quality.md`, `security.md`
- Python → `backend.md`, `quality.md`, `security.md`
- Infra → `infra.md`, `quality.md`, `security.md`
- Full stack → all rule files

Read templates from `skills/setup/templates/rules/` and write to `.claude/rules/`.

#### 5d. `.claude/settings.json`

Read `skills/setup/templates/settings.json` and customize based on security level:

- **Basic**: permissions only, no hooks
- **Standard**: permissions + block-dangerous + post-edit-lint hooks
- **Strict**: permissions + all hooks (block-dangerous, workflow-guard, branch-guard, post-edit-lint, stop verification)

Add marketplace and plugin configuration:

```json
{
  "extraKnownMarketplaces": {
    "dafiti-tools": {
      "source": {
        "source": "github",
        "repo": "dafiti-group/vibe"
      }
    }
  },
  "enabledPlugins": {
    "vibe@dafiti-tools": true
  }
}
```

#### 5e. `.mcp.json`

Read `skills/setup/templates/mcp.json` and include only selected integrations.

#### 5f. `.github/workflows/`

If GitHub Actions was selected, copy workflow templates from `skills/setup/templates/github-workflows/`.

If the user selected `/vibe:fix-vulnerabilities`, also copy `claude-fix-vulnerabilities.yml`.

#### 5g. `docs/standards/`

Copy relevant standard files based on tech stack from `docs/standards/` in the plugin.

#### 5h. `REVIEW.md`

Copy `REVIEW.md` from the plugin root.

#### 5i. Git hooks (strict mode only)

If strict security level, set up native git hooks:

- Copy `hooks/git-hooks/pre-commit` and `hooks/git-hooks/commit-msg` to the project
- Run `git config core.hooksPath hooks/git-hooks`

### Step 6: Show Summary

Display what was configured:

```
Vibe Setup Complete!

Tech Stack: [selected technologies]
Security:   [level]
Integrations: [selected]
Skills:     [selected]

Files created/updated:
  CLAUDE.md              — Project configuration hub
  .claude/rules/         — [N] rule files
  .claude/settings.json  — Permissions + hooks
  .mcp.json              — MCP servers
  .github/workflows/     — CI/CD pipelines
  docs/standards/        — Detailed coding standards
  REVIEW.md              — Code review guidelines
  vibe.config.json       — Vibe preferences

Next steps:
  1. Set GITHUB_TOKEN for MCP GitHub server
  2. Add CLAUDE_CODE_OAUTH_TOKEN to GitHub repo secrets
  3. Start coding!
```

After showing the summary, ask (use AskUserQuestion):

**Question**: "Do you want Vibe to create a quarterly standards review issue in this repo?"
**Options**:

- **Yes** — Creates a GitHub issue with a checklist to review all standards every 3 months
- **No** — Skip, I'll review standards manually
