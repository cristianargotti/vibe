---
title: Manual Testing Overview
sidebar:
  order: 1
---

This guide provides step-by-step scenarios to manually validate every Vibe feature before a release, during onboarding, or after an update. Each scenario includes the exact prompt or command to run, the expected result, and what to do if it fails.

## When to run manual tests

- **Pre-release** — validate all features before rolling out to the team
- **Onboarding** — new team members verify their setup works end-to-end
- **Post-update** — after upgrading Vibe, confirm nothing broke

## Prepare a test repository

Create a temporary repository to run tests without affecting real projects:

```bash
mkdir /tmp/vibe-test && cd /tmp/vibe-test
git init
echo '{"name":"vibe-test","version":"1.0.0"}' > package.json
cat > app.ts << 'EOF'
export function greet(name: string): string {
  return `Hello, ${name}!`;
}
EOF
git add -A && git commit -m "chore: initial commit"
```

## Install Vibe

Inside the test repository, open Claude Code and run:

```
/plugin marketplace add cristianargotti/vibe
/plugin install vibe
/vibe:setup
```

Select **Strict** security level during setup to enable all hooks and git hooks.

## Checklist

Use this table to track progress. Each scenario links to its detailed page.

| #   | Category   | Scenario                              | Page                                           | Pass |
| --- | ---------- | ------------------------------------- | ---------------------------------------------- | ---- |
| 1   | Hooks      | Branch protection (pre-commit)        | [Hooks](/vibe/manual-testing/hooks/)           |      |
| 2   | Hooks      | Branch protection (workflow-guard)    | [Hooks](/vibe/manual-testing/hooks/)           |      |
| 3   | Hooks      | Branch protection (branch-guard)      | [Hooks](/vibe/manual-testing/hooks/)           |      |
| 4   | Hooks      | Branch naming validation              | [Hooks](/vibe/manual-testing/hooks/)           |      |
| 5   | Hooks      | Conventional commits (git hook)       | [Hooks](/vibe/manual-testing/hooks/)           |      |
| 6   | Hooks      | Conventional commits (workflow-guard) | [Hooks](/vibe/manual-testing/hooks/)           |      |
| 7   | Hooks      | Secret detection (pre-commit)         | [Hooks](/vibe/manual-testing/hooks/)           |      |
| 8   | Hooks      | Secret detection (workflow-guard)     | [Hooks](/vibe/manual-testing/hooks/)           |      |
| 9   | Hooks      | --no-verify blocking                  | [Hooks](/vibe/manual-testing/hooks/)           |      |
| 10  | Hooks      | Dangerous commands                    | [Hooks](/vibe/manual-testing/hooks/)           |      |
| 11  | Skills     | /vibe:setup                           | [Skills](/vibe/manual-testing/skills/)         |      |
| 12  | Skills     | /vibe:health-check                    | [Skills](/vibe/manual-testing/skills/)         |      |
| 13  | Skills     | /vibe:review-security                 | [Skills](/vibe/manual-testing/skills/)         |      |
| 14  | Skills     | /vibe:deploy-check                    | [Skills](/vibe/manual-testing/skills/)         |      |
| 15  | Skills     | /vibe:test                            | [Skills](/vibe/manual-testing/skills/)         |      |
| 16  | Skills     | /vibe:refactor                        | [Skills](/vibe/manual-testing/skills/)         |      |
| 17  | Skills     | /vibe:create-pr                       | [Skills](/vibe/manual-testing/skills/)         |      |
| 18  | Skills     | /vibe:fix-issue                       | [Skills](/vibe/manual-testing/skills/)         |      |
| 19  | Skills     | /vibe:whats-new                       | [Skills](/vibe/manual-testing/skills/)         |      |
| 20  | Automation | SessionStart hook                     | [Automation](/vibe/manual-testing/automation/) |      |
| 21  | Automation | Stop hook                             | [Automation](/vibe/manual-testing/automation/) |      |
| 22  | Automation | Post-edit auto-format                 | [Automation](/vibe/manual-testing/automation/) |      |
| 23  | Automation | Agents                                | [Automation](/vibe/manual-testing/automation/) |      |
