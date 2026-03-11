# {{PROJECT_NAME}} — Engineering Standards

## Tech Stack

- **Backend**: Python, FastAPI
- **Data/ML**: Pydantic, LangChain
- **Testing**: pytest
- **Observability**: structlog, OpenTelemetry

## Critical Commands

```bash
pytest                # Run tests
ruff check .          # Lint check
ruff format .         # Format code
pip audit             # Security audit
```

## Architecture

- **Layered architecture**: Router → Service → Repository
- **API format**: RESTful, standard error `{"error":{"code":"...","message":"..."}}`
- **Auth**: JWT (15min) + refresh tokens
- **Validation**: Pydantic for all external data

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

- Python patterns → `docs/standards/python.md`
- Database/ORM → `docs/standards/database.md`
- API Design → `docs/standards/api-design.md`
- Testing → `docs/standards/testing.md`
- LLM/AI → `docs/standards/llm-ai.md`
- Observability → `docs/standards/observability.md`

## Security

- Never hardcode secrets — use env vars or Secrets Manager
- Always validate inputs at API boundaries with Pydantic
- Always use parameterized queries
- Encrypt PII at rest (LGPD compliance)
- Run `pip audit` before deploying

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
