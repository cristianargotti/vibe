#!/usr/bin/env bash
# SessionStart hook: lightweight config validation (<100ms)
# Notifies if Vibe configuration has issues — never blocks.

set -euo pipefail

# Consume stdin (hook protocol)
cat > /dev/null

WARNINGS=""

# Check critical files exist
[ -f "CLAUDE.md" ] || WARNINGS="${WARNINGS}CLAUDE.md not found. "
[ -d ".claude/rules" ] || WARNINGS="${WARNINGS}.claude/rules/ not found. "
[ -f ".claude/settings.json" ] || WARNINGS="${WARNINGS}.claude/settings.json not found. "

# Check settings.json is valid JSON
if [ -f ".claude/settings.json" ]; then
  jq empty .claude/settings.json 2>/dev/null || WARNINGS="${WARNINGS}.claude/settings.json is invalid JSON. "
fi

# Check for vibe.config.json (optional)
if [ ! -f "vibe.config.json" ]; then
  WARNINGS="${WARNINGS}No vibe.config.json found — run /vibe:setup to configure. "
fi

# Check versions.json freshness (lightweight)
if [ -f "versions.json" ]; then
  jq empty versions.json 2>/dev/null || WARNINGS="${WARNINGS}versions.json is invalid JSON. "
fi

if [ -n "$WARNINGS" ]; then
  echo "Vibe: $WARNINGS"
fi

exit 0
