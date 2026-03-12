# {{PROJECT_NAME}} — Engineering Standards

## Tech Stack

- **Backend**: TypeScript, NestJS
- **Frontend**: React, Next.js (App Router), TanStack Query, Zustand
- **Testing**: Vitest, Jest, Playwright
- **Observability**: pino, OpenTelemetry

## Critical Commands

```bash
npm run lint          # ESLint check
npm run lint:fix      # ESLint auto-fix
npm run format        # Prettier format
npm run format:check  # Prettier check
npm test              # Run tests
npx vitest            # Run Vitest
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
- Commit messages must follow conventional commits: `type(scope): description`
- After committing, push and create a PR — never merge locally
- Never use `--no-verify` — fix the underlying issue instead

## For Detailed Standards

- TypeScript patterns → `docs/standards/typescript.md`
- NestJS architecture → `docs/standards/nestjs.md`
- React/Next.js → `docs/standards/react-nextjs.md`
- Database/ORM → `docs/standards/database.md`
- API Design → `docs/standards/api-design.md`
- Testing → `docs/standards/testing.md`
- Observability → `docs/standards/observability.md`

## Security

- Never hardcode secrets — use env vars or Secrets Manager
- Always validate inputs at API boundaries
- Always use parameterized queries
- Encrypt PII at rest (LGPD compliance)
- Run `npm audit` before deploying

## Plugin Skills

- `/vibe:setup` — Interactive configuration wizard
- `/vibe:review-security` — OWASP-based security review
- `/vibe:deploy-check` — Pre-deployment verification
- `/vibe:fix-issue <number>` — Fix GitHub issue with tests
- `/vibe:refactor <path>` — Refactor preserving behavior
- `/vibe:create-pr [base]` — Structured PR creation
- `/vibe:test <path>` — Generate and run tests
- `/vibe:health-check` — Validate plugin configuration
- `/vibe:whats-new` — Check Claude Code updates
- `/vibe:fix-vulnerabilities` — Fix Dependabot security vulnerabilities
