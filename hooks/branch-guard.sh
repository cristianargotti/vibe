#!/usr/bin/env bash
# PreToolUse hook for Edit|Write: blocks file modifications on protected branches.
# Read operations are still allowed — this only gates Edit and Write tools.
# Reads tool input JSON from stdin, returns JSON decision.

set -euo pipefail

# Fast check: get current branch
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then
  echo "{\"decision\":\"deny\",\"reason\":\"Blocked: cannot modify files on '$BRANCH'. Create a feature branch first: git checkout -b feat/your-feature\"}"
  exit 0
fi

echo '{"decision":"allow"}'
