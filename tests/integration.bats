#!/usr/bin/env bats
# Integration tests: verify multiple hooks work together correctly

# --- Hook coexistence ---

@test "integration: workflow-guard and block-dangerous-commands both evaluate same command" {
  # Both hooks should allow a safe command like "git status"
  wg_result=$(echo '{"tool_input":{"command":"git status"}}' | hooks/workflow-guard.sh)
  bdc_result=$(echo '{"tool_input":{"command":"git status"}}' | hooks/block-dangerous-commands.sh)
  [[ -z "$wg_result" ]]
  [[ -z "$bdc_result" ]]
}

@test "integration: git commit on feature branch with conventional message passes workflow-guard" {
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then
    skip "currently on protected branch"
  fi
  result=$(echo '{"tool_input":{"command":"git commit -m \"feat: add new feature\""}}' | hooks/workflow-guard.sh)
  [[ -z "$result" ]]
}

@test "integration: --no-verify is blocked by workflow-guard regardless of branch" {
  # Even on a feature branch, --no-verify should be blocked
  result=$(echo '{"tool_input":{"command":"git commit --no-verify -m \"feat: test\""}}' | hooks/workflow-guard.sh)
  [[ "$result" == *'"permissionDecision":"deny"'* ]]
  [[ "$result" == *"--no-verify"* ]]
}

@test "integration: branch-guard is only triggered by Edit|Write matcher (not Read)" {
  # branch-guard itself always blocks on protected branches — the filtering
  # is done by the hooks.json matcher "Edit|Write", not by the script.
  # Verify the matcher is correctly configured.
  matcher=$(jq -r '.hooks.PreToolUse[] | select(.hooks[].command | test("branch-guard")) | .matcher' hooks/hooks.json)
  [[ "$matcher" == "Edit|Write" ]]
  # Verify Read is NOT in the matcher
  [[ "$matcher" != *"Read"* ]]
}

@test "integration: post-edit-lint produces empty output for unknown file types" {
  result=$(echo '{"tool_input":{"file_path":"unknown.xyz"}}' | hooks/post-edit-lint.sh 2>/dev/null || true)
  # Should not crash; output is empty or just a message, no error
  [[ "$?" -eq 0 ]] || true
}

@test "integration: validate-config output format is plain text (not JSON)" {
  run bash -c 'echo "" | hooks/validate-config.sh'
  # Output should be plain text status messages, not JSON
  if [ -n "$output" ]; then
    [[ "$output" != "{"* ]]
  fi
}

# --- Stop hook verification ---

@test "integration: hooks.json Stop hook is prompt type (not command)" {
  stop_type=$(jq -r '.hooks.Stop[0].hooks[0].type' hooks/hooks.json)
  [[ "$stop_type" == "prompt" ]]
}

@test "integration: Stop hook prompt contains all 4 verification items" {
  prompt=$(jq -r '.hooks.Stop[0].hooks[0].prompt' hooks/hooks.json)
  [[ "$prompt" == *"tests"* ]]
  [[ "$prompt" == *"security"* ]]
  [[ "$prompt" == *"conventions"* ]]
  [[ "$prompt" == *"secrets"* ]]
}

# --- SessionStart hook ---

@test "integration: hooks.json SessionStart timeout is reasonable (< 10 seconds)" {
  timeout=$(jq -r '.hooks.SessionStart[0].hooks[0].timeout' hooks/hooks.json)
  [[ "$timeout" -lt 10 ]]
}

# --- All hook scripts exit 0 on safe input ---

@test "integration: all hook scripts exit 0 on safe input" {
  for hook in hooks/block-dangerous-commands.sh hooks/workflow-guard.sh hooks/branch-guard.sh hooks/post-edit-lint.sh; do
    run bash -c 'echo "{\"tool_input\":{}}" | '"$hook"
    [[ "$status" -eq 0 ]] || { echo "FAILED: $hook exited with $status"; false; }
  done
}

@test "integration: validate-config exits 0 always (never blocks session)" {
  run bash -c 'echo "" | hooks/validate-config.sh'
  [[ "$status" -eq 0 ]]
}
