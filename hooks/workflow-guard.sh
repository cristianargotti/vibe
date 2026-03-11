#!/usr/bin/env bash
# PreToolUse hook for Bash: workflow safety guard
# Enforces branch protection, conventional commits, hook integrity, and secret detection.
# Reads tool input JSON from stdin, returns JSON decision.

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

deny() {
  local reason
  reason=$(echo "$1" | sed 's/\\/\\\\/g; s/"/\\"/g')
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"${reason}\"}}"
  exit 0
}

# --- 1. Block git commit on protected branches (main/master/develop) ---
if echo "$COMMAND" | grep -qE 'git[[:space:]]+commit\b'; then
  BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
  if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then
    deny "Blocked: cannot commit on '${BRANCH}'. Create a feature branch first: git checkout -b feat/your-feature"
  fi
fi

# --- 2. Block --no-verify flag ---
if echo "$COMMAND" | grep -qE -- '--no-verify'; then
  deny "Blocked: --no-verify bypasses safety hooks. Remove it and fix the underlying issue."
fi

# --- 3. Enforce branch naming + base freshness on git checkout -b / git switch -c ---
if echo "$COMMAND" | grep -qE 'git[[:space:]]+(checkout[[:space:]]+-b|switch[[:space:]]+-c)[[:space:]]+'; then
  BRANCH_NAME=$(echo "$COMMAND" | grep -oE '(checkout[[:space:]]+-b|switch[[:space:]]+-c)[[:space:]]+[^[:space:]]+' | awk '{print $NF}')
  if [ -n "$BRANCH_NAME" ] && ! echo "$BRANCH_NAME" | grep -qE '^(feat|fix|chore|docs|test|refactor)/'; then
    deny "Blocked: branch '${BRANCH_NAME}' must start with feat/, fix/, chore/, docs/, test/, or refactor/"
  fi
  # Check if current branch is behind its remote (no network, uses last fetch)
  CURRENT=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
  if [ -n "$CURRENT" ]; then
    BEHIND=$(git rev-list HEAD..@{u} --count 2>/dev/null || echo "0")
    if [ "$BEHIND" -gt 0 ]; then
      deny "Blocked: '${CURRENT}' is ${BEHIND} commit(s) behind remote. Run 'git pull' before creating a new branch."
    fi
  fi
fi

# --- 4. Validate conventional commit message ---
if echo "$COMMAND" | grep -qE 'git[[:space:]]+commit\b'; then
  # Extract message from -m "..." or -m '...' (handles simple and HEREDOC-expanded)
  COMMIT_MSG=""
  # Try double-quoted: -m "message"
  COMMIT_MSG=$(echo "$COMMAND" | sed -n 's/.*-m[[:space:]]*"\([^"]*\)".*/\1/p' 2>/dev/null || true)
  # If empty, try single-quoted: -m 'message'
  if [ -z "$COMMIT_MSG" ]; then
    COMMIT_MSG=$(echo "$COMMAND" | sed -n "s/.*-m[[:space:]]*'\\([^']*\\)'.*/\\1/p" 2>/dev/null || true)
  fi
  # Extract first line only (for multiline messages)
  if [ -n "$COMMIT_MSG" ]; then
    COMMIT_MSG=$(echo "$COMMIT_MSG" | head -n 1)
  fi
  if [ -n "$COMMIT_MSG" ]; then
    if ! echo "$COMMIT_MSG" | grep -qE '^(feat|fix|refactor|docs|test|chore|style|perf|ci|build|revert)(\(.+\))?!?:[[:space:]]'; then
      if ! echo "$COMMIT_MSG" | grep -qiE '^Merge[[:space:]]'; then
        deny "Blocked: commit message must follow conventional commits format: type(scope): description. Valid types: feat, fix, refactor, docs, test, chore, style, perf, ci, build, revert"
      fi
    fi
  fi
fi

# --- 5. Block PR merge if CI checks haven't passed ---
if echo "$COMMAND" | grep -qE 'gh[[:space:]]+pr[[:space:]]+merge'; then
  # Extract PR number from command
  PR_NUM=$(echo "$COMMAND" | grep -oE 'gh[[:space:]]+pr[[:space:]]+merge[[:space:]]+[0-9]+' | awk '{print $NF}')
  if [ -n "$PR_NUM" ]; then
    # Query check status via gh (requires gh to be available)
    if command -v gh &>/dev/null; then
      CHECKS_OUTPUT=$(gh pr checks "$PR_NUM" 2>/dev/null || true)
      if [ -n "$CHECKS_OUTPUT" ]; then
        # If any check is still pending or in_progress, block merge
        if echo "$CHECKS_OUTPUT" | grep -qiE '(pending|in_progress)'; then
          deny "Blocked: PR #${PR_NUM} has pending CI checks. Wait for all checks to complete before merging."
        fi
        # If any check failed, block merge
        if echo "$CHECKS_OUTPUT" | grep -qiE 'fail'; then
          deny "Blocked: PR #${PR_NUM} has failing CI checks. Fix the failures before merging."
        fi
      fi
    fi
  fi
fi

# --- 6. Secret detection in staged diff before commit ---
if echo "$COMMAND" | grep -qE 'git[[:space:]]+commit\b'; then
  STAGED=$(git diff --cached --name-only 2>/dev/null || true)
  if [ -n "$STAGED" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PATTERN_FILE="${SCRIPT_DIR}/secret-patterns.txt"
    if [ -f "$PATTERN_FILE" ]; then
      PATTERNS=$(grep -v '^#' "$PATTERN_FILE" | grep -v '^$' | paste -sd'|' -)
    else
      PATTERNS='AKIA[0-9A-Z]{16}|sk-[a-zA-Z0-9]{20,}|sk-ant-[a-zA-Z0-9_-]{20,}|-----BEGIN (RSA |EC |DSA )?PRIVATE KEY-----|ghp_[a-zA-Z0-9]{36}|gho_[a-zA-Z0-9]{36}|glpat-[a-zA-Z0-9_-]{20,}|xoxb-[a-zA-Z0-9-]+'
    fi
    SECRETS_FOUND=""
    while IFS= read -r file; do
      [ -f "$file" ] || continue
      # Scan only the staged diff, not the entire file
      if git diff --cached -- "$file" 2>/dev/null | grep -qE "^\+.*($PATTERNS)"; then
        SECRETS_FOUND="${SECRETS_FOUND}${file} "
      fi
    done <<< "$STAGED"
    if [ -n "$SECRETS_FOUND" ]; then
      deny "Blocked: potential secrets detected in staged files: ${SECRETS_FOUND}. Remove secrets and use environment variables or Secrets Manager."
    fi
  fi
fi

exit 0
