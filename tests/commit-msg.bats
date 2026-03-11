#!/usr/bin/env bats
# Tests for hooks/git-hooks/commit-msg

HOOK="hooks/git-hooks/commit-msg"

# Helper: write message to temp file and run hook
run_commit_msg() {
  local msg="$1"
  TMPFILE=$(mktemp)
  echo "$msg" > "$TMPFILE"
  run "$HOOK" "$TMPFILE"
  rm -f "$TMPFILE"
}

# --- ALLOW: valid conventional commits ---

@test "allows: feat: description" {
  run_commit_msg "feat: add user authentication"
  [[ "$status" -eq 0 ]]
}

@test "allows: fix: description" {
  run_commit_msg "fix: resolve login bug"
  [[ "$status" -eq 0 ]]
}

@test "allows: refactor: description" {
  run_commit_msg "refactor: extract validation logic"
  [[ "$status" -eq 0 ]]
}

@test "allows: docs: description" {
  run_commit_msg "docs: update API docs"
  [[ "$status" -eq 0 ]]
}

@test "allows: test: description" {
  run_commit_msg "test: add auth unit tests"
  [[ "$status" -eq 0 ]]
}

@test "allows: chore: description" {
  run_commit_msg "chore: update dependencies"
  [[ "$status" -eq 0 ]]
}

@test "allows: style: description" {
  run_commit_msg "style: fix indentation"
  [[ "$status" -eq 0 ]]
}

@test "allows: perf: description" {
  run_commit_msg "perf: optimize query"
  [[ "$status" -eq 0 ]]
}

@test "allows: ci: description" {
  run_commit_msg "ci: update pipeline"
  [[ "$status" -eq 0 ]]
}

@test "allows: build: description" {
  run_commit_msg "build: update webpack config"
  [[ "$status" -eq 0 ]]
}

@test "allows: revert: description" {
  run_commit_msg "revert: undo breaking change"
  [[ "$status" -eq 0 ]]
}

# --- ALLOW: with scope ---

@test "allows: feat(auth): description" {
  run_commit_msg "feat(auth): add JWT validation"
  [[ "$status" -eq 0 ]]
}

@test "allows: fix(api): description" {
  run_commit_msg "fix(api): handle 404 response"
  [[ "$status" -eq 0 ]]
}

# --- ALLOW: breaking change ---

@test "allows: feat!: breaking change" {
  run_commit_msg "feat!: redesign auth flow"
  [[ "$status" -eq 0 ]]
}

@test "allows: refactor(api)!: breaking change" {
  run_commit_msg "refactor(api)!: restructure endpoints"
  [[ "$status" -eq 0 ]]
}

# --- ALLOW: merge commits ---

@test "allows: Merge branch" {
  run_commit_msg "Merge branch 'feat/something' into develop"
  [[ "$status" -eq 0 ]]
}

@test "allows: Merge pull request" {
  run_commit_msg "Merge pull request #42 from org/branch"
  [[ "$status" -eq 0 ]]
}

# --- ALLOW: fixup/squash ---

@test "allows: fixup! commit" {
  run_commit_msg "fixup! feat: add auth"
  [[ "$status" -eq 0 ]]
}

@test "allows: squash! commit" {
  run_commit_msg "squash! fix: resolve bug"
  [[ "$status" -eq 0 ]]
}

# --- DENY: invalid messages ---

@test "blocks: random message" {
  run_commit_msg "added new feature"
  [[ "$status" -eq 1 ]]
}

@test "blocks: missing space after colon" {
  run_commit_msg "feat:no space"
  [[ "$status" -eq 1 ]]
}

@test "blocks: uppercase type" {
  run_commit_msg "FEAT: uppercase"
  [[ "$status" -eq 1 ]]
}

@test "blocks: wip message" {
  run_commit_msg "wip"
  [[ "$status" -eq 1 ]]
}

@test "blocks: empty message" {
  run_commit_msg ""
  [[ "$status" -eq 1 ]]
}

@test "blocks: only whitespace" {
  run_commit_msg "   "
  [[ "$status" -eq 1 ]]
}

@test "blocks: typo in type" {
  run_commit_msg "feta: add cheese"
  [[ "$status" -eq 1 ]]
}

@test "blocks: no colon" {
  run_commit_msg "feat add something"
  [[ "$status" -eq 1 ]]
}

@test "shows error message on invalid" {
  run_commit_msg "bad message"
  [[ "$output" == *"conventional commits"* ]]
}

@test "shows the invalid message in output" {
  run_commit_msg "bad message"
  [[ "$output" == *"bad message"* ]]
}
