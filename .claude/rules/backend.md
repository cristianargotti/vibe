# Backend Rules

Always use strict TypeScript with explicit return types. Never use `any`.
Always use async/await. Never use raw Promises or callbacks.
Always follow hexagonal architecture: Controller → Service → Repository. Controller never imports Repository directly.
Always validate inputs with DTOs (class-validator in NestJS) or Zod schemas.
Always use dependency injection. Never manually instantiate services.
Always use type hints in Python. Always use Pydantic for external data validation.
Always use parameterized queries. Always prevent N+1 queries with eager loading or DataLoader.
Always use migrations for schema changes. Never run manual DDL in production.
Always index foreign keys and columns used in WHERE/ORDER BY clauses.
Always use structured logging (pino for Node.js, structlog for Python). Never use console.log in production.
Always handle errors with custom error classes. Never throw generic Error.
Always use connection pooling for databases. Never open connections per request.
