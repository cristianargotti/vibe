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
  [[ -z "$result" ]]
}

@test "allows: any stdin content on feature branch" {
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then
    skip "currently on protected branch"
  fi
  result=$(echo '{}' | "$HOOK")
  [[ -z "$result" ]]
}

# --- Protected branch tests (mock git rev-parse) ---

@test "blocks: file edit on main branch (mocked)" {
  MOCKDIR=$(mktemp -d)
  cat > "$MOCKDIR/git" << 'MOCKEOF'
#!/usr/bin/env bash
if [[ "$1" == "rev-parse" && "$2" == "--abbrev-ref" ]]; then
  echo "main"
  exit 0
fi
exec /usr/bin/git "$@"
MOCKEOF
  chmod +x "$MOCKDIR/git"
  result=$(echo '{"tool_input":{"file_path":"test.ts","new_string":"hello"}}' | PATH="$MOCKDIR:$PATH" bash "$HOOK")
  rm -f "$MOCKDIR/git" && rmdir "$MOCKDIR"
  [[ "$result" == *'"permissionDecision":"deny"'* ]]
  [[ "$result" == *"cannot modify files"* ]]
}

@test "blocks: file edit on develop branch (mocked)" {
  MOCKDIR=$(mktemp -d)
  cat > "$MOCKDIR/git" << 'MOCKEOF'
#!/usr/bin/env bash
if [[ "$1" == "rev-parse" && "$2" == "--abbrev-ref" ]]; then
  echo "develop"
  exit 0
fi
exec /usr/bin/git "$@"
MOCKEOF
  chmod +x "$MOCKDIR/git"
  result=$(echo '{"tool_input":{"file_path":"test.ts","new_string":"hello"}}' | PATH="$MOCKDIR:$PATH" bash "$HOOK")
  rm -f "$MOCKDIR/git" && rmdir "$MOCKDIR"
  [[ "$result" == *'"permissionDecision":"deny"'* ]]
}
