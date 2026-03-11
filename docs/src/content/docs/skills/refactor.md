---
title: "/vibe:refactor"
sidebar:
  order: 5
---

Refactors code while preserving behavior, verified by tests.

## Usage

```
/vibe:refactor <path>
```

## What it does

1. **Read target** — analyzes the file or directory at the given path
2. **Load standards** — reads relevant `docs/standards/*.md` for the affected technology
3. **Identify improvements** — looks for:
   - Duplicated code to extract
   - Complex conditionals to simplify
   - Poor naming to improve
   - Missing design patterns
   - Architecture violations (e.g., controller importing repository directly)
   - Dead code to remove
   - Type safety improvements
4. **Run baseline tests** — executes existing tests to establish a passing baseline
5. **Refactor incrementally** — one change at a time, running tests after each
6. **Verify** — runs the full test suite to confirm nothing broke

## Rules

- **NEVER changes behavior** — refactoring must be transparent to consumers
- **NEVER skips tests** — every change is verified
- **NEVER refactors test files** — tests are the verification layer
- Creates atomic commits for each logical change
- Follows hexagonal architecture patterns

## Model

Runs on **Sonnet** for speed. Uses a fork context to work on an isolated copy.

## Example

```
/vibe:refactor src/orders/orders.service.ts
```
