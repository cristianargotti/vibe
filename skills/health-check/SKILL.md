---
name: health-check
description: Validate Vibe plugin configuration — checks hooks, skills, settings, and standards integrity.
allowed-tools: Read, Glob, Grep, Bash
---

# Vibe Health Check

Validate the Vibe plugin configuration and report status of all components.

## Instructions

Run the validation script and supplement with manual checks:

1. **Run validation**: Execute `bash skills/health-check/scripts/validate.sh`
2. **Check hooks**:
   - Verify all hook scripts in `hooks/` are executable
   - Verify `hooks/hooks.json` is valid JSON
   - Verify hook scripts referenced in hooks.json exist
3. **Check skills**:
   - Verify all skill directories in `skills/` have a `SKILL.md`
   - Verify SKILL.md files have valid YAML frontmatter
4. **Check agents**:
   - Verify all agent files in `agents/` exist and are non-empty
5. **Check settings**:
   - Verify `.claude/settings.json` is valid JSON
   - Verify `settings.json` (plugin-level) is valid JSON
6. **Check standards**:
   - Verify all 12 standard files exist in `docs/standards/`
7. **Check plugin manifest**:
   - Verify `.claude-plugin/plugin.json` is valid JSON
   - Verify `.claude-plugin/marketplace.json` is valid JSON
8. **Check version**:
   - Compare `.claude-code-version` with installed Claude Code version

## Output Format

```
Vibe Health Check Report
========================

Hooks:        [status] [details]
Skills:       [status] [details]
Agents:       [status] [details]
Settings:     [status] [details]
Standards:    [status] [details]
Plugin:       [status] [details]
Version:      [status] [details]

Overall: HEALTHY / NEEDS ATTENTION / BROKEN
```

Use these status indicators:

- PASS — Component is correctly configured
- WARN — Component works but has issues
- FAIL — Component is broken or missing
