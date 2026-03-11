---
title: "/vibe:deploy-check"
sidebar:
  order: 3
---

Pre-deployment verification that checks everything before you ship.

## Usage

```
/vibe:deploy-check
```

## What it does

Runs 6 categories of checks and outputs a `DEPLOY STATUS: READY` or `DEPLOY STATUS: NOT READY` verdict.

### Check categories

| Category           | Checks                                                                      |
| ------------------ | --------------------------------------------------------------------------- |
| **Code Quality**   | Lint passes, typecheck passes, formatting correct                           |
| **Tests**          | Unit tests pass, coverage >= 80%, E2E tests pass                            |
| **Security**       | `npm audit` / `pip audit` clean, no secrets in code, no staged `.env` files |
| **Build**          | Production build succeeds, bundle size within limits, Docker build works    |
| **Infrastructure** | `terraform validate` + `terraform plan` clean, env vars documented          |
| **Dependencies**   | No outdated critical deps, lock file committed                              |

### Output

```
DEPLOY STATUS: READY
✓ Code Quality — all checks passed
✓ Tests — 94% coverage (threshold: 80%)
✓ Security — no vulnerabilities found
✓ Build — production build successful
✓ Infrastructure — terraform plan clean
✓ Dependencies — all up to date
```

Or if something fails:

```
DEPLOY STATUS: NOT READY

Blockers:
- Tests: coverage at 72% (minimum: 80%)
- Security: 2 high-severity npm audit findings

Warnings:
- Dependencies: 3 packages outdated (non-critical)
```

## Model

Runs on **Sonnet** for speed — deploy checks should be fast.
