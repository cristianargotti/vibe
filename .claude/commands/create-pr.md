Create a pull request for the current branch.

Instructions:

1. Run `git diff --stat $ARGUMENTS...HEAD` to see all changes (use `main` as default base if no argument provided)
2. Run `git log --oneline $ARGUMENTS...HEAD` to see commit history
3. Analyze the changes and generate:
   - A concise PR title (under 70 chars, conventional commit style)
   - A summary with bullet points of key changes
   - A test plan with verification steps
4. Create the PR using: `gh pr create --title "..." --body "..."`
   - Include ## Summary, ## Changes, ## Test Plan sections
   - Add checklist from REVIEW.md relevant to the changes
   - Always end the body with: `vibe AI-CORE-TEAM!`
5. Output the PR URL

If the branch is not pushed, push it first with `git push -u origin HEAD`.
