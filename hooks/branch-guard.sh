#!/usr/bin/env bash
# PreToolUse hook for Edit|Write: blocks file modifications on protected branches.
# Read operations are still allowed — this only gates Edit and Write tools.
# Reads tool input JSON from stdin, returns JSON decision.

set -euo pipefail

# Consume stdin (required by hook protocol)
cat > /dev/null

# Fast check: get current branch
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then
  REASON=$(echo "Blocked: cannot modify files on '${BRANCH}'. Create a feature branch first: git checkout -b feat/your-feature" | sed 's/"/\\"/g')
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"${REASON}\"}}"
  exit 0
fi

exit 0
