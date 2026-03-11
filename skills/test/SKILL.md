---
name: test
description: ALWAYS invoke when user types /test. Generates and runs tests for the specified path.
argument-hint: "<path>"
allowed-tools: Read, Grep, Glob, Edit, Write, Bash
---

# Generate and Run Tests

Generate and run tests for the specified path.

## Arguments

- Target path (required): `$ARGUMENTS`

## Instructions

1. Read `docs/standards/testing.md` for testing patterns
2. Analyze the target file/directory to understand the code
3. Generate tests covering:
   - Happy path scenarios
   - Edge cases (empty inputs, boundaries, nulls)
   - Error handling paths
4. Follow these patterns:
   - Use Arrange/Act/Assert structure
   - Use descriptive test names: "should [expected behavior] when [condition]"
   - Mock external dependencies (HTTP, DB, file system)
   - One assertion per concept
5. For TypeScript: use Vitest (`*.test.ts`), place tests next to source files
6. For Python: use pytest (`test_*.py`), place in `tests/` directory
7. Run the tests and report results with coverage
8. Fix any failing tests before finishing
