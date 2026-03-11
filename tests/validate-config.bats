#!/usr/bin/env bats
# Tests for hooks/validate-config.sh

# Get absolute path to hook
setup() {
  HOOK_ABS="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/hooks/validate-config.sh"
}

@test "exits 0 always (never blocks)" {
  run bash -c 'echo "" | '"$HOOK_ABS"
  [[ "$status" -eq 0 ]]
}

@test "detects missing CLAUDE.md" {
  TMPDIR=$(mktemp -d)
  run bash -c "cd '$TMPDIR' && echo '' | '$HOOK_ABS'"
  rm -rf "$TMPDIR"
  [[ "$output" == *"CLAUDE.md"* ]]
}

@test "detects missing .claude/rules" {
  TMPDIR=$(mktemp -d)
  touch "$TMPDIR/CLAUDE.md"
  run bash -c "cd '$TMPDIR' && echo '' | '$HOOK_ABS'"
  rm -rf "$TMPDIR"
  [[ "$output" == *".claude/rules"* ]]
}

@test "detects missing .claude/settings.json" {
  TMPDIR=$(mktemp -d)
  touch "$TMPDIR/CLAUDE.md"
  mkdir -p "$TMPDIR/.claude/rules"
  run bash -c "cd '$TMPDIR' && echo '' | '$HOOK_ABS'"
  rm -rf "$TMPDIR"
  [[ "$output" == *".claude/settings.json"* ]]
}

@test "detects invalid settings.json" {
  TMPDIR=$(mktemp -d)
  touch "$TMPDIR/CLAUDE.md"
  mkdir -p "$TMPDIR/.claude/rules"
  echo "invalid json{{{" > "$TMPDIR/.claude/settings.json"
  run bash -c "cd '$TMPDIR' && echo '' | '$HOOK_ABS'"
  rm -rf "$TMPDIR"
  [[ "$output" == *"invalid JSON"* ]]
}

@test "detects missing vibe.config.json" {
  TMPDIR=$(mktemp -d)
  touch "$TMPDIR/CLAUDE.md"
  mkdir -p "$TMPDIR/.claude/rules"
  echo '{}' > "$TMPDIR/.claude/settings.json"
  run bash -c "cd '$TMPDIR' && echo '' | '$HOOK_ABS'"
  rm -rf "$TMPDIR"
  [[ "$output" == *"vibe.config.json"* ]]
}

@test "no warnings when all files present" {
  TMPDIR=$(mktemp -d)
  touch "$TMPDIR/CLAUDE.md"
  mkdir -p "$TMPDIR/.claude/rules"
  echo '{}' > "$TMPDIR/.claude/settings.json"
  echo '{}' > "$TMPDIR/vibe.config.json"
  run bash -c "cd '$TMPDIR' && echo '' | '$HOOK_ABS'"
  rm -rf "$TMPDIR"
  [[ "$output" == "" ]]
}
