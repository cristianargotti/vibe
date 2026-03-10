# Security Rules

Always use parameterized queries. Never concatenate SQL strings.
Always validate all inputs at API boundaries with Zod (TS) or Pydantic (Python).
Never hardcode secrets. Always use environment variables or AWS Secrets Manager.
Always use HTTPS for all endpoints. Always set HSTS headers.
Always use JWT with short expiry (15min) + refresh tokens for authentication.
Always encrypt PII at rest (LGPD compliance). Always log data access for audit.
Always run `npm audit` / `pip audit` before deploying.
Never use `any` type — it bypasses TypeScript's safety guarantees.
Always sanitize user input rendered in HTML to prevent XSS.
Always use CSRF tokens on all state-changing endpoints.
Always set Content-Security-Policy headers.
Always use bcrypt or argon2 for password hashing. Never use MD5 or SHA for passwords.
Never log sensitive data (tokens, passwords, PII, credit cards).
Always validate file upload types and sizes server-side. Never trust client-side validation alone.
Always use rate limiting on authentication endpoints.
