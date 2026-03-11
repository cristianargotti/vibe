#!/usr/bin/env bats
# Tests for hooks/workflow-guard.sh

HOOK="hooks/workflow-guard.sh"

# Helper: send a command through the hook and capture output
# Uses printf to properly escape JSON
run_hook() {
  local cmd="$1"
  # Escape backslashes and double quotes for JSON
  local escaped
  escaped=$(printf '%s' "$cmd" | sed 's/\\/\\\\/g; s/"/\\"/g')
  printf '{"tool_input":{"command":"%s"}}' "$escaped" | "$HOOK"
}

# --- ALLOW: safe workflow operations ---

@test "allows: empty command" {
  result=$(echo '{"tool_input":{}}' | "$HOOK")
  [[ "$result" == '{"decision":"allow"}' ]]
}

@test "allows: git status" {
  result=$(run_hook "git status")
  [[ "$result" == '{"decision":"allow"}' ]]
}

@test "allows: git diff" {
  result=$(run_hook "git diff HEAD~1")
  [[ "$result" == '{"decision":"allow"}' ]]
}

@test "allows: git log" {
  result=$(run_hook "git log --oneline -5")
  [[ "$result" == '{"decision":"allow"}' ]]
}

@test "allows: npm test" {
  result=$(run_hook "npm test")
  [[ "$result" == '{"decision":"allow"}' ]]
}

# --- Branch Protection (commit on protected branches) ---

@test "allows: git commit on current branch (feature branch)" {
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then
    skip "currently on protected branch"
  fi
  result=$(run_hook 'git commit -m "feat: test commit"')
  [[ "$result" == '{"decision":"allow"}' ]]
}

# --- --no-verify blocking ---

@test "blocks: git commit --no-verify" {
  result=$(run_hook 'git commit --no-verify -m "bad commit"')
  [[ "$result" == *'"decision":"deny"'* ]]
  [[ "$result" == *"--no-verify"* ]]
}

@test "blocks: git push --no-verify" {
  result=$(run_hook "git push --no-verify")
  [[ "$result" == *'"decision":"deny"'* ]]
}

@test "blocks: npm run test --no-verify" {
  result=$(run_hook "npm run test --no-verify")
  [[ "$result" == *'"decision":"deny"'* ]]
}

# --- Branch Naming ---

@test "allows: git checkout -b feat/new-feature" {
  result=$(run_hook "git checkout -b feat/new-feature")
  [[ "$result" == '{"decision":"allow"}' ]]
}

@test "allows: git checkout -b fix/bug-123" {
  result=$(run_hook "git checkout -b fix/bug-123")
  [[ "$result" == '{"decision":"allow"}' ]]
}

@test "allows: git checkout -b chore/update-deps" {
  result=$(run_hook "git checkout -b chore/update-deps")
  [[ "$result" == '{"decision":"allow"}' ]]
}

@test "allows: git checkout -b docs/api-docs" {
  result=$(run_hook "git checkout -b docs/api-docs")
  [[ "$result" == '{"decision":"allow"}' ]]
}

@test "allows: git checkout -b test/add-unit-tests" {
  result=$(run_hook "git checkout -b test/add-unit-tests")
  [[ "$result" == '{"decision":"allow"}' ]]
}

@test "allows: git checkout -b refactor/auth-module" {
  result=$(run_hook "git checkout -b refactor/auth-module")
  [[ "$result" == '{"decision":"allow"}' ]]
}

@test "allows: git switch -c feat/new-feature" {
  result=$(run_hook "git switch -c feat/new-feature")
  [[ "$result" == '{"decision":"allow"}' ]]
}

@test "blocks: git checkout -b bad-branch-name" {
  result=$(run_hook "git checkout -b bad-branch-name")
  [[ "$result" == *'"decision":"deny"'* ]]
  [[ "$result" == *"must start with"* ]]
}

@test "blocks: git checkout -b my-feature" {
  result=$(run_hook "git checkout -b my-feature")
  [[ "$result" == *'"decision":"deny"'* ]]
}

@test "blocks: git switch -c random-name" {
  result=$(run_hook "git switch -c random-name")
  [[ "$result" == *'"decision":"deny"'* ]]
}

@test "blocks: git checkout -b FEAT/uppercase" {
  result=$(run_hook "git checkout -b FEAT/uppercase")
  [[ "$result" == *'"decision":"deny"'* ]]
}

# --- Conventional Commits ---

@test "allows: feat: description" {
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then skip; fi
  result=$(run_hook 'git commit -m "feat: add user authentication"')
  [[ "$result" == '{"decision":"allow"}' ]]
}

@test "allows: fix(scope): description" {
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then skip; fi
  result=$(run_hook 'git commit -m "fix(auth): resolve token expiration"')
  [[ "$result" == '{"decision":"allow"}' ]]
}

@test "allows: refactor!: breaking change" {
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then skip; fi
  result=$(run_hook 'git commit -m "refactor!: restructure API endpoints"')
  [[ "$result" == '{"decision":"allow"}' ]]
}

@test "allows: docs: update readme" {
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then skip; fi
  result=$(run_hook 'git commit -m "docs: update readme"')
  [[ "$result" == '{"decision":"allow"}' ]]
}

@test "allows: test: add unit tests" {
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then skip; fi
  result=$(run_hook 'git commit -m "test: add unit tests"')
  [[ "$result" == '{"decision":"allow"}' ]]
}

@test "allows: chore: update deps" {
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then skip; fi
  result=$(run_hook 'git commit -m "chore: update dependencies"')
  [[ "$result" == '{"decision":"allow"}' ]]
}

@test "allows: style: format code" {
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then skip; fi
  result=$(run_hook 'git commit -m "style: format code"')
  [[ "$result" == '{"decision":"allow"}' ]]
}

@test "allows: perf: optimize query" {
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then skip; fi
  result=$(run_hook 'git commit -m "perf: optimize database query"')
  [[ "$result" == '{"decision":"allow"}' ]]
}

@test "allows: ci: update workflow" {
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then skip; fi
  result=$(run_hook 'git commit -m "ci: update workflow"')
  [[ "$result" == '{"decision":"allow"}' ]]
}

@test "allows: build: update config" {
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then skip; fi
  result=$(run_hook 'git commit -m "build: update config"')
  [[ "$result" == '{"decision":"allow"}' ]]
}

@test "allows: revert: undo change" {
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then skip; fi
  result=$(run_hook 'git commit -m "revert: undo change"')
  [[ "$result" == '{"decision":"allow"}' ]]
}

@test "allows: Merge commit" {
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then skip; fi
  result=$(run_hook "git commit -m 'Merge branch feat/something into develop'")
  [[ "$result" == '{"decision":"allow"}' ]]
}

@test "blocks: non-conventional commit" {
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then skip; fi
  result=$(run_hook 'git commit -m "added new feature"')
  [[ "$result" == *'"decision":"deny"'* ]]
  [[ "$result" == *"conventional commits"* ]]
}

@test "blocks: missing space after colon" {
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then skip; fi
  result=$(run_hook 'git commit -m "feat:no space"')
  [[ "$result" == *'"decision":"deny"'* ]]
}

@test "blocks: uppercase type" {
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then skip; fi
  result=$(run_hook 'git commit -m "FEAT: uppercase"')
  [[ "$result" == *'"decision":"deny"'* ]]
}

@test "blocks: random commit message" {
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then skip; fi
  result=$(run_hook 'git commit -m "wip stuff"')
  [[ "$result" == *'"decision":"deny"'* ]]
}

@test "allows: single-quoted commit message" {
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then skip; fi
  result=$(run_hook "git commit -m 'feat: single quoted'")
  [[ "$result" == '{"decision":"allow"}' ]]
}
