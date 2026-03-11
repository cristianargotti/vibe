# Vibe — Dafiti Engineering Standards

## Project Overview

Claude Code configuration template for Dafiti teams. Enforces security, architecture, and quality standards across TypeScript/Node.js, React/Next.js, Python, Terraform, Docker, and AWS.

## Tech Stack

- **Backend**: TypeScript, NestJS, Python, FastAPI
- **Frontend**: React, Next.js (App Router), TanStack Query, Zustand
- **Data/ML**: Python, Pydantic, LangChain
- **Infra**: Docker, Terraform, AWS (S3, IAM, VPC, ECS), CloudFormation
- **Testing**: Vitest, Jest, pytest, Playwright
- **Observability**: pino, structlog, OpenTelemetry

## Critical Commands

```bash
npm run lint          # ESLint check
npm run lint:fix      # ESLint auto-fix
npm run format        # Prettier format
npm run format:check  # Prettier check
npm test              # Run tests
npx vitest            # Run Vitest
pytest                # Run Python tests
terraform plan        # Preview infra changes
terraform validate    # Validate Terraform config
```

## Architecture

- **Hexagonal architecture**: Controller → Service → Repository
- **API format**: RESTful, standard error `{"error":{"code":"...","message":"..."}}`
- **Auth**: JWT (15min) + refresh tokens
- **State**: TanStack Query (server), Zustand (client)

## Conventions

- Conventional commits: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`, `style:`, `perf:`, `ci:`, `build:`, `revert:`
- Branch naming: `feat/`, `fix/`, `chore/`, `docs/`, `test/`, `refactor/`
- PRs: under 400 lines, one concern per PR
- Testing: 80% coverage minimum, 100% on critical paths

## Git Workflow

- Never commit directly on main, master, or develop — always create a feature branch
- Branch naming: `feat/`, `fix/`, `chore/`, `docs/`, `test/`, `refactor/` prefixes required
- Commit messages must follow conventional commits: `type(scope): description`
- After committing, push and create a PR — never merge locally
- Never use `--no-verify` — fix the underlying issue instead

## For Detailed Standards

When working on a specific technology, read the relevant file in `docs/standards/`:

- TypeScript patterns → `docs/standards/typescript.md`
- NestJS architecture → `docs/standards/nestjs.md`
- React/Next.js → `docs/standards/react-nextjs.md`
- Python patterns → `docs/standards/python.md`
- Docker → `docs/standards/docker.md`
- Terraform → `docs/standards/terraform.md`
- AWS → `docs/standards/aws.md`
- Database/ORM → `docs/standards/database.md`
- LLM/AI → `docs/standards/llm-ai.md`
- Observability → `docs/standards/observability.md`
- API Design → `docs/standards/api-design.md`
- Testing → `docs/standards/testing.md`

## Security

- Never hardcode secrets — use env vars or Secrets Manager
- Always validate inputs at API boundaries
- Always use parameterized queries
- Encrypt PII at rest (LGPD compliance)
- Run `npm audit` / `pip audit` before deploying

## Commands

- `/create-pr [base]` — Create structured PR
- `/test <path>` — Generate and run tests

## Skills

- `/review-security` — OWASP-based security review
- `/fix-issue <number>` — Analyze and fix GitHub issue
- `/refactor <path>` — Refactor with behavior preservation
- `/deploy-check` — Pre-deployment verification checklist
- `/simplify` — Review changed code for reuse and efficiency (built-in)

## GitHub Automation

- PR Review: automatic on every PR (Claude reviews against `.claude/rules/`)
- Security Review: automatic OWASP scan on every PR
- Issue Handler: label issues with `claude-fix`, `claude-feature`, or `claude-refactor`
