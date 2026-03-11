#!/usr/bin/env bats
# Tests for hooks/branch-guard.sh

HOOK="hooks/branch-guard.sh"

# --- Tests that depend on current branch ---
# We're on feat/workflow-safety-v2, so edits should be allowed

@test "allows: file edit on feature branch" {
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then
    skip "currently on protected branch"
  fi
  result=$(echo '{"tool_input":{"file_path":"test.ts","new_string":"hello"}}' | "$HOOK")
  [[ "$result" == '{"decision":"allow"}' ]]
}

@test "allows: any stdin content on feature branch" {
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then
    skip "currently on protected branch"
  fi
  result=$(echo '{}' | "$HOOK")
  [[ "$result" == '{"decision":"allow"}' ]]
}

# Note: Testing "deny on main" requires actually being on main,
# which we don't want to do in automated tests. These are covered
# by the integration test (test-on-protected-branch.bats).
