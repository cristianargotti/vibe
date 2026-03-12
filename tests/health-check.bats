#!/usr/bin/env bats
# Tests for skills/health-check/scripts/validate.sh

SCRIPT="skills/health-check/scripts/validate.sh"

@test "health-check: script exists and is executable" {
  [[ -f "$SCRIPT" ]]
  [[ -x "$SCRIPT" ]]
}

@test "health-check: returns exit 0 on well-configured project (this repo)" {
  run bash "$SCRIPT"
  [[ "$status" -eq 0 ]]
}

@test "health-check: output includes PASS for hooks" {
  run bash "$SCRIPT"
  [[ "$output" == *"PASS"* ]]
  [[ "$output" == *"hooks.json"* ]]
}

@test "health-check: output includes PASS for skills with frontmatter" {
  run bash "$SCRIPT"
  [[ "$output" == *"PASS: /vibe:setup has valid SKILL.md with frontmatter"* ]]
}

@test "health-check: output includes PASS for agents" {
  run bash "$SCRIPT"
  [[ "$output" == *"PASS: code-reviewer.md exists and is non-empty"* ]]
}

@test "health-check: output includes status summary" {
  run bash "$SCRIPT"
  # Should contain either HEALTHY or NEEDS ATTENTION (WARN for version mismatch is OK)
  [[ "$output" == *"HEALTHY"* ]] || [[ "$output" == *"NEEDS ATTENTION"* ]]
}

@test "health-check: output does not contain secrets or PII" {
  run bash "$SCRIPT"
  # Should not contain API keys, tokens, or passwords
  [[ "$output" != *"sk-ant-"* ]]
  [[ "$output" != *"sk-"*"api"* ]]
  [[ "$output" != *"ghp_"* ]]
  [[ "$output" != *"AKIA"* ]]
  [[ "$output" != *"password"* ]]
}

@test "health-check: output includes results count" {
  run bash "$SCRIPT"
  [[ "$output" == *"passed"* ]]
  [[ "$output" == *"warnings"* ]]
  [[ "$output" == *"failures"* ]]
}

# --- Tests with simulated broken environments ---

@test "health-check: detects plugin.json missing" {
  TMPDIR=$(mktemp -d)
  mkdir -p "$TMPDIR/skills/health-check/scripts"
  cp "$SCRIPT" "$TMPDIR/skills/health-check/scripts/validate.sh"
  # Create minimal structure without plugin.json
  mkdir -p "$TMPDIR/hooks" "$TMPDIR/skills" "$TMPDIR/agents" "$TMPDIR/docs/standards"
  run bash "$TMPDIR/skills/health-check/scripts/validate.sh"
  rm -rf "$TMPDIR"
  [[ "$output" == *"FAIL: plugin.json not found"* ]]
}

@test "health-check: detects hooks.json missing" {
  TMPDIR=$(mktemp -d)
  mkdir -p "$TMPDIR/skills/health-check/scripts"
  cp "$SCRIPT" "$TMPDIR/skills/health-check/scripts/validate.sh"
  mkdir -p "$TMPDIR/.claude-plugin" "$TMPDIR/skills" "$TMPDIR/agents" "$TMPDIR/docs/standards"
  echo '{}' > "$TMPDIR/.claude-plugin/plugin.json"
  echo '{}' > "$TMPDIR/.claude-plugin/marketplace.json"
  run bash "$TMPDIR/skills/health-check/scripts/validate.sh"
  rm -rf "$TMPDIR"
  [[ "$output" == *"FAIL: hooks.json not found"* ]]
}

@test "health-check: detects missing skill SKILL.md" {
  TMPDIR=$(mktemp -d)
  mkdir -p "$TMPDIR/skills/health-check/scripts"
  cp "$SCRIPT" "$TMPDIR/skills/health-check/scripts/validate.sh"
  mkdir -p "$TMPDIR/.claude-plugin" "$TMPDIR/hooks" "$TMPDIR/agents" "$TMPDIR/docs/standards"
  echo '{}' > "$TMPDIR/.claude-plugin/plugin.json"
  echo '{}' > "$TMPDIR/.claude-plugin/marketplace.json"
  echo '{}' > "$TMPDIR/hooks/hooks.json"
  # Create skill dirs without SKILL.md
  mkdir -p "$TMPDIR/skills/setup"
  run bash "$TMPDIR/skills/health-check/scripts/validate.sh"
  rm -rf "$TMPDIR"
  [[ "$output" == *"FAIL"* ]]
  [[ "$output" == *"SKILL.md not found"* ]]
}

@test "health-check: detects missing agent files" {
  TMPDIR=$(mktemp -d)
  mkdir -p "$TMPDIR/skills/health-check/scripts"
  cp "$SCRIPT" "$TMPDIR/skills/health-check/scripts/validate.sh"
  mkdir -p "$TMPDIR/.claude-plugin" "$TMPDIR/hooks" "$TMPDIR/skills" "$TMPDIR/agents" "$TMPDIR/docs/standards"
  echo '{}' > "$TMPDIR/.claude-plugin/plugin.json"
  echo '{}' > "$TMPDIR/.claude-plugin/marketplace.json"
  echo '{}' > "$TMPDIR/hooks/hooks.json"
  run bash "$TMPDIR/skills/health-check/scripts/validate.sh"
  rm -rf "$TMPDIR"
  [[ "$output" == *"FAIL"* ]]
  [[ "$output" == *"not found"* ]]
}

@test "health-check: returns exit 1 when critical files missing (BROKEN)" {
  TMPDIR=$(mktemp -d)
  mkdir -p "$TMPDIR/skills/health-check/scripts"
  cp "$SCRIPT" "$TMPDIR/skills/health-check/scripts/validate.sh"
  # Bare minimum — missing everything
  run bash "$TMPDIR/skills/health-check/scripts/validate.sh"
  rm -rf "$TMPDIR"
  [[ "$status" -eq 1 ]]
  [[ "$output" == *"BROKEN"* ]]
}

@test "health-check: reports PASS for hook scripts when they exist and are executable" {
  run bash "$SCRIPT"
  [[ "$output" == *"PASS: block-dangerous-commands.sh exists and is executable"* ]]
  [[ "$output" == *"PASS: workflow-guard.sh exists and is executable"* ]]
  [[ "$output" == *"PASS: branch-guard.sh exists and is executable"* ]]
}

@test "health-check: checks secret-patterns.txt pattern count" {
  run bash "$SCRIPT"
  [[ "$output" == *"secret-patterns.txt"* ]]
  [[ "$output" == *"patterns"* ]]
}
