---
name: fix-issue
description: ALWAYS invoke when user types /fix-issue. Reads a GitHub issue and implements the fix with tests.
argument-hint: "<issue-number>"
model: opus
---

# Fix GitHub Issue

Read a GitHub issue, analyze the codebase, implement the fix, and create a commit.

## Arguments

- Issue number (required): `$ARGUMENTS`

## Instructions

1. **Read the issue**: Run `gh issue view $ARGUMENTS` to get full details
2. **Understand context**: Read linked files, error messages, and reproduction steps
3. **Analyze the codebase**: Find relevant files using Grep and Glob
4. **Read standards**: Load the relevant `docs/standards/*.md` files for the tech being modified
5. **Plan the fix**: Identify root cause and design the minimal fix
6. **Implement the fix**:
   - Follow patterns in `.claude/rules/`
   - Use proper error handling with custom error classes
   - Validate inputs at boundaries
7. **Add tests**:
   - Cover the bug scenario (regression test)
   - Cover edge cases around the fix
   - Follow patterns from `docs/standards/testing.md`
8. **Run tests**: Execute the full test suite to verify no regressions
9. **Create commit**: Use conventional commit format
   - `fix: <description>` for bug fixes
   - `feat: <description>` for feature requests
   - Reference the issue: `Fixes #<number>`
10. **Summary**: Output what was changed and why

## Rules

- Never introduce new `any` types
- Always add structured logging for the fix
- Always validate inputs if the fix involves user data
- Keep the fix minimal — don't refactor unrelated code
