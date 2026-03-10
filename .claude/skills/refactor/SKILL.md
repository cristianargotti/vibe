---
description: ALWAYS invoke when user types /refactor. Refactors code while preserving behavior, verified by tests.
model: sonnet
context: fork
allowed-tools: Read, Grep, Glob, Edit, Write, Bash
---

# Refactor Code

Refactor the specified path while preserving existing behavior, verified by tests.

## Arguments
- Target path (required): `$ARGUMENTS`

## Instructions

1. **Read the target**: Analyze the code at the specified path
2. **Read standards**: Load relevant `docs/standards/*.md` for the tech stack
3. **Identify improvements**:
   - Extract duplicated code into shared functions
   - Simplify complex conditionals
   - Improve naming for clarity
   - Apply design patterns where appropriate
   - Fix architecture violations (e.g., Controller importing Repository)
   - Remove dead code
   - Improve type safety (eliminate `any`)
4. **Run existing tests first**: Establish baseline — all tests must pass
5. **Refactor incrementally**:
   - Make one logical change at a time
   - Run tests after each change to verify behavior preservation
   - If tests fail, revert the last change and try a different approach
6. **Verify**: Run full test suite one final time
7. **Summary**: Output what was refactored and why

## Rules
- NEVER change behavior — only improve structure
- NEVER skip running tests between changes
- NEVER refactor test files (unless explicitly asked)
- Keep commits atomic: one logical refactor per commit
- Follow hexagonal architecture: Controller → Service → Repository
- Use dependency injection, not manual instantiation
