---
name: whats-new
description: Check for Claude Code updates and new features relevant to Vibe configuration.
allowed-tools: Read, Bash, WebFetch, WebSearch
---

# What's New in Claude Code

Check for updates to Claude Code that may affect Vibe plugin configuration.

## Instructions

1. **Read current version**: Read `.claude-code-version` to get the tracked version
2. **Check installed version**: Run `claude --version` to get the current installed version
3. **Compare versions**: If they differ, investigate changes
4. **Search for updates**: Search the web for recent Claude Code changelog, release notes, or blog posts
5. **Analyze impact**: Check if any changes affect:
   - Hook system (new events, schema changes)
   - Skill system (new frontmatter options, features)
   - Agent system (new capabilities)
   - Settings schema (new options, deprecations)
   - Plugin system (new features, API changes)
   - Permission model changes
6. **Report findings**:

## Output Format

```
Current tracked version: X.X.X
Installed version: Y.Y.Y

## New Features
- [feature]: [impact on Vibe]

## Breaking Changes
- [change]: [action required]

## Recommendations
- [suggestion for Vibe updates]
```

7. If changes found, offer to update `.claude-code-version` to the current installed version
