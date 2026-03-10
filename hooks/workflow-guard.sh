#!/usr/bin/env bash
# PreToolUse hook for Bash: workflow safety guard
# Enforces branch protection, conventional commits, hook integrity, and secret detection.
# Reads tool input JSON from stdin, returns JSON decision.

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  echo '{"decision":"allow"}'
  exit 0
fi

deny() {
  echo "{\"decision\":\"deny\",\"reason\":\"$1\"}"
  exit 0
}

# --- 1. Block git commit on protected branches (main/master/develop) ---
if echo "$COMMAND" | grep -qE 'git\s+commit\b'; then
  BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
  if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then
    deny "Blocked: cannot commit on '$BRANCH'. Create a feature branch first: git checkout -b feat/your-feature"
  fi
fi

# --- 2. Block --no-verify flag ---
if echo "$COMMAND" | grep -qE '\-\-no-verify'; then
  deny "Blocked: --no-verify bypasses safety hooks. Remove it and fix the underlying issue."
fi

# --- 3. Enforce branch naming on git checkout -b / git switch -c ---
if echo "$COMMAND" | grep -qE 'git\s+(checkout\s+-b|switch\s+-c)\s+'; then
  BRANCH_NAME=$(echo "$COMMAND" | grep -oE '(checkout\s+-b|switch\s+-c)\s+\S+' | awk '{print $NF}')
  if [ -n "$BRANCH_NAME" ] && ! echo "$BRANCH_NAME" | grep -qE '^(feat|fix|chore|docs|test|refactor)/'; then
    deny "Blocked: branch '$BRANCH_NAME' must start with feat/, fix/, chore/, docs/, test/, or refactor/"
  fi
fi

# --- 4. Validate conventional commit message ---
if echo "$COMMAND" | grep -qE 'git\s+commit\b'; then
  COMMIT_MSG=$(echo "$COMMAND" | sed -n "s/.*-m[[:space:]]*['\"]\\(.*\\)['\"].*/\\1/p" 2>/dev/null || true)
  if [ -n "$COMMIT_MSG" ]; then
    if ! echo "$COMMIT_MSG" | grep -qE '^(feat|fix|refactor|docs|test|chore|style|perf|ci|build|revert)(\(.+\))?!?:\s'; then
      if ! echo "$COMMIT_MSG" | grep -qiE '^Merge\s'; then
        deny "Blocked: commit message must follow conventional commits format: type(scope): description. Valid types: feat, fix, refactor, docs, test, chore, style, perf, ci, build, revert"
      fi
    fi
  fi
fi

# --- 5. Secret detection in staged files before commit ---
if echo "$COMMAND" | grep -qE 'git\s+commit\b'; then
  STAGED=$(git diff --cached --name-only 2>/dev/null || true)
  if [ -n "$STAGED" ]; then
    SECRETS_FOUND=""
    while IFS= read -r file; do
      [ -f "$file" ] || continue
      if grep -qE '(AKIA[0-9A-Z]{16}|sk-[a-zA-Z0-9]{20,}|sk-ant-[a-zA-Z0-9-]{20,}|-----BEGIN (RSA |EC |DSA )?PRIVATE KEY-----|ghp_[a-zA-Z0-9]{36}|password\s*=\s*["\x27][^\s"'\'']{8,}["\x27])' "$file" 2>/dev/null; then
        SECRETS_FOUND="${SECRETS_FOUND}${file} "
      fi
    done <<< "$STAGED"
    if [ -n "$SECRETS_FOUND" ]; then
      deny "Blocked: potential secrets detected in staged files: ${SECRETS_FOUND}. Remove secrets and use environment variables or Secrets Manager."
    fi
  fi
fi

echo '{"decision":"allow"}'
