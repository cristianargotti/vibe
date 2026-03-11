---
title: Contributing
sidebar:
  order: 1
---

How to contribute to the Vibe plugin.

## Adding a skill

1. Create a directory under `skills/`:

   ```
   skills/my-skill/SKILL.md
   ```

2. Add YAML frontmatter with required fields:

   ```yaml
   ---
   name: my-skill
   model: sonnet # or opus, or omit for default
   allowed-tools: Read, Grep, Glob, Bash
   ---
   ```

3. Write the skill prompt below the frontmatter

4. Register it in `.claude-plugin/plugin.json`

5. Run `/vibe:health-check` to validate

## Adding a hook

1. Create a shell script in `hooks/`:

   ```
   hooks/my-hook.sh
   ```

2. Make it executable: `chmod +x hooks/my-hook.sh`

3. Add the hook definition to `hooks/hooks.json`

4. For PreToolUse hooks: read stdin JSON, output deny decision JSON to block, or exit 0 to allow

5. For PostToolUse hooks: read stdin JSON, perform side effects, exit 0

## Adding a standard

1. Create a markdown file in `docs/standards/`:

   ```
   docs/standards/my-standard.md
   ```

2. Add the `last-reviewed` comment on the first line:

   ```html
   <!-- last-reviewed: 2026-03-11 -->
   ```

3. Update the health check's expected file list in `skills/health-check/scripts/validate.sh`

## Adding an agent

1. Create a markdown file in `agents/`:

   ```
   agents/my-agent.md
   ```

2. Register it in `.claude-plugin/plugin.json`

## Running tests

```bash
# All tests
npm test

# Specific test suites
npm run test:hooks
npm run test:git-hooks
npm run test:structure
npm run test:secrets
```

Tests use [BATS](https://github.com/bats-core/bats-core) (Bash Automated Testing System).

## Code style

- Shell scripts: POSIX-compatible when possible
- Conventional commits for all changes
- Keep PRs under 400 lines
