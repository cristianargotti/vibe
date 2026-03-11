# {{PROJECT_NAME}} — Engineering Standards

## Tech Stack

- **Infra**: Docker, Terraform, AWS (S3, IAM, VPC, ECS), CloudFormation
- **Observability**: CloudWatch, OpenTelemetry

## Critical Commands

```bash
terraform plan        # Preview infra changes
terraform validate    # Validate Terraform config
terraform fmt -check  # Check formatting
docker build .        # Build container
docker compose up     # Run local stack
```

## Architecture

- One Terraform module per service
- Remote state in S3 + DynamoDB lock
- Multi-stage Docker builds with non-root users
- Private subnets for compute, public only for ALB/NLB

## Conventions

- Conventional commits: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`, `style:`, `perf:`, `ci:`, `build:`, `revert:`
- Branch naming: `feat/`, `fix/`, `chore/`, `docs/`, `test/`, `refactor/`
- PRs: under 400 lines, one concern per PR
- All resources tagged: environment, team, service, cost-center

## Git Workflow

- Never commit directly on main, master, or develop — always create a feature branch
- Commit messages must follow conventional commits: `type(scope): description`
- After committing, push and create a PR — never merge locally
- Never use `--no-verify` — fix the underlying issue instead

## For Detailed Standards

- Docker → `docs/standards/docker.md`
- Terraform → `docs/standards/terraform.md`
- AWS → `docs/standards/aws.md`
- Observability → `docs/standards/observability.md`

## Security

- Never hardcode secrets — use env vars or Secrets Manager
- IAM least privilege — never use inline policies
- Encrypt S3 buckets (SSE-S3 or SSE-KMS), block public access
- Mark sensitive Terraform variables with `sensitive = true`

## Plugin Skills

- `/vibe:setup` — Interactive configuration wizard
- `/vibe:review-security` — OWASP-based security review
- `/vibe:deploy-check` — Pre-deployment verification
- `/vibe:create-pr [base]` — Structured PR creation
- `/vibe:health-check` — Validate plugin configuration
- `/vibe:whats-new` — Check Claude Code updates
