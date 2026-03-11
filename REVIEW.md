# Code Review Guidelines

Use `/vibe:review-security` for automated OWASP-based security reviews.

## Review Priorities (ordered by importance)

1. **Security** — Injection, auth, secrets exposure, input validation, LGPD compliance
2. **Correctness** — Logic errors, edge cases, error handling, race conditions
3. **Architecture** — Hexagonal arch adherence, separation of concerns, dependency direction
4. **Performance** — N+1 queries, missing indexes, unnecessary re-renders, memory leaks
5. **Maintainability** — Naming, complexity, test coverage, documentation

## Review Checklist

### Security
- [ ] No hardcoded secrets or credentials
- [ ] All inputs validated at API boundaries (Zod/Pydantic)
- [ ] Parameterized queries (no SQL concatenation)
- [ ] No PII logged or exposed
- [ ] Auth/authz checks on all protected endpoints
- [ ] CSRF protection on state-changing endpoints
- [ ] File uploads validated server-side

### Code Quality
- [ ] No `any` types in TypeScript
- [ ] Explicit return types on public functions
- [ ] Custom error classes (not generic Error)
- [ ] Structured logging (no console.log)
- [ ] Async/await (no raw Promises/callbacks)

### Architecture
- [ ] Controller → Service → Repository (no skipping layers)
- [ ] Dependencies injected (not manually instantiated)
- [ ] Business logic in Service layer (not Controller/Repository)
- [ ] DTOs for API input/output validation

### Testing
- [ ] Tests added for new functionality
- [ ] Edge cases and error paths covered
- [ ] External services mocked (not real calls)
- [ ] Arrange/Act/Assert pattern followed

### Frontend
- [ ] Server Components by default ("use client" only when needed)
- [ ] TanStack Query for data fetching (not useEffect+fetch)
- [ ] Skeleton loaders (not spinners)
- [ ] Error boundaries on route segments
- [ ] Accessible (aria labels, keyboard nav)

### Infrastructure
- [ ] Multi-stage Docker builds
- [ ] Non-root container user
- [ ] HEALTHCHECK in Dockerfile
- [ ] Terraform resources tagged
- [ ] IAM least privilege
- [ ] No public S3 buckets
- [ ] Secrets in Secrets Manager (not env vars in code)

### PR Standards
- [ ] Under 400 lines changed
- [ ] Single concern per PR
- [ ] Conventional commit messages
- [ ] Description explains "why" not just "what"
- [ ] Test plan documented
