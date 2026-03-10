# Quality Rules

Always write tests. Minimum 80% coverage, 100% on critical paths (auth, payments, checkout).
Always use Arrange/Act/Assert pattern. One assertion per concept.
Always mock external services. Never mock the unit under test.
Always use conventional commits: feat:, fix:, refactor:, docs:, test:, chore:.
Always use branch naming: feat/, fix/, chore/ prefixes.
Always keep PRs under 400 lines changed. One concern per PR.
Always use RESTful conventions: nouns for resources, HTTP verbs for actions.
Always return standard error format: `{"error":{"code":"...","message":"..."}}`.
Always use structured JSON logs. Never log PII or secrets.
Always use OpenTelemetry for distributed tracing across services.
Always validate LLM outputs with Pydantic/Zod schemas before using them.
Always version-control prompts as code. Never hardcode prompts inline.
Always document API endpoints with OpenAPI/Swagger specs.
Never commit directly on main, master, or develop — always use a feature branch and PR.
Never use --no-verify — fix the underlying issue instead of bypassing hooks.
