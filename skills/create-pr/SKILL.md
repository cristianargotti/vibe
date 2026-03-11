---
name: create-pr
description: ALWAYS invoke when user types /create-pr. Creates a structured pull request for the current branch.
argument-hint: "[base-branch]"
allowed-tools: Read, Grep, Glob, Bash
---

# Create Pull Request

Create a pull request for the current branch.

## Arguments

- Base branch (optional): `$ARGUMENTS` (defaults to `main`)

## Instructions

1. Run `git diff --stat $ARGUMENTS...HEAD` to see all changes (use `main` as default base if no argument provided)
2. Run `git log --oneline $ARGUMENTS...HEAD` to see commit history
3. Analyze the changes and generate:
   - A concise PR title (under 70 chars, conventional commit style)
   - A summary with bullet points of key changes
   - A test plan with verification steps
4. Create the PR using: `gh pr create --title "..." --body "..."`
   - Include ## Summary, ## Changes, ## Test Plan sections
   - Add checklist from REVIEW.md relevant to the changes
   - Always end the body with: `following AI-CORE-STANDARDS`
5. Output the PR URL

If the branch is not pushed, push it first with `git push -u origin HEAD`.
