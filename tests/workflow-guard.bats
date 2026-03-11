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
  [[ -z "$result" ]]
}

@test "allows: git status" {
  result=$(run_hook "git status")
  [[ -z "$result" ]]
}

@test "allows: git diff" {
  result=$(run_hook "git diff HEAD~1")
  [[ -z "$result" ]]
}

@test "allows: git log" {
  result=$(run_hook "git log --oneline -5")
  [[ -z "$result" ]]
}

@test "allows: npm test" {
  result=$(run_hook "npm test")
  [[ -z "$result" ]]
}

# --- Branch Protection (commit on protected branches) ---

@test "allows: git commit on current branch (feature branch)" {
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then
    skip "currently on protected branch"
  fi
  result=$(run_hook 'git commit -m "feat: test commit"')
  [[ -z "$result" ]]
}

# --- --no-verify blocking ---

@test "blocks: git commit --no-verify" {
  result=$(run_hook 'git commit --no-verify -m "bad commit"')
  [[ "$result" == *'"permissionDecision":"deny"'* ]]
  [[ "$result" == *"--no-verify"* ]]
}

@test "blocks: git push --no-verify" {
  result=$(run_hook "git push --no-verify")
  [[ "$result" == *'"permissionDecision":"deny"'* ]]
}

@test "blocks: npm run test --no-verify" {
  result=$(run_hook "npm run test --no-verify")
  [[ "$result" == *'"permissionDecision":"deny"'* ]]
}

# --- Branch Naming ---

@test "allows: git checkout -b feat/new-feature" {
  result=$(run_hook "git checkout -b feat/new-feature")
  [[ -z "$result" ]]
}

@test "allows: git checkout -b fix/bug-123" {
  result=$(run_hook "git checkout -b fix/bug-123")
  [[ -z "$result" ]]
}

@test "allows: git checkout -b chore/update-deps" {
  result=$(run_hook "git checkout -b chore/update-deps")
  [[ -z "$result" ]]
}

@test "allows: git checkout -b docs/api-docs" {
  result=$(run_hook "git checkout -b docs/api-docs")
  [[ -z "$result" ]]
}

@test "allows: git checkout -b test/add-unit-tests" {
  result=$(run_hook "git checkout -b test/add-unit-tests")
  [[ -z "$result" ]]
}

@test "allows: git checkout -b refactor/auth-module" {
  result=$(run_hook "git checkout -b refactor/auth-module")
  [[ -z "$result" ]]
}

@test "allows: git switch -c feat/new-feature" {
  result=$(run_hook "git switch -c feat/new-feature")
  [[ -z "$result" ]]
}

@test "blocks: git checkout -b bad-branch-name" {
  result=$(run_hook "git checkout -b bad-branch-name")
  [[ "$result" == *'"permissionDecision":"deny"'* ]]
  [[ "$result" == *"must start with"* ]]
}

@test "blocks: git checkout -b my-feature" {
  result=$(run_hook "git checkout -b my-feature")
  [[ "$result" == *'"permissionDecision":"deny"'* ]]
}

@test "blocks: git switch -c random-name" {
  result=$(run_hook "git switch -c random-name")
  [[ "$result" == *'"permissionDecision":"deny"'* ]]
}

@test "blocks: git checkout -b FEAT/uppercase" {
  result=$(run_hook "git checkout -b FEAT/uppercase")
  [[ "$result" == *'"permissionDecision":"deny"'* ]]
}

# --- Conventional Commits ---

@test "allows: feat: description" {
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then skip; fi
  result=$(run_hook 'git commit -m "feat: add user authentication"')
  [[ -z "$result" ]]
}

@test "allows: fix(scope): description" {
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then skip; fi
  result=$(run_hook 'git commit -m "fix(auth): resolve token expiration"')
  [[ -z "$result" ]]
}

@test "allows: refactor!: breaking change" {
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then skip; fi
  result=$(run_hook 'git commit -m "refactor!: restructure API endpoints"')
  [[ -z "$result" ]]
}

@test "allows: docs: update readme" {
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then skip; fi
  result=$(run_hook 'git commit -m "docs: update readme"')
  [[ -z "$result" ]]
}

@test "allows: test: add unit tests" {
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then skip; fi
  result=$(run_hook 'git commit -m "test: add unit tests"')
  [[ -z "$result" ]]
}

@test "allows: chore: update deps" {
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then skip; fi
  result=$(run_hook 'git commit -m "chore: update dependencies"')
  [[ -z "$result" ]]
}

@test "allows: style: format code" {
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then skip; fi
  result=$(run_hook 'git commit -m "style: format code"')
  [[ -z "$result" ]]
}

@test "allows: perf: optimize query" {
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then skip; fi
  result=$(run_hook 'git commit -m "perf: optimize database query"')
  [[ -z "$result" ]]
}

@test "allows: ci: update workflow" {
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then skip; fi
  result=$(run_hook 'git commit -m "ci: update workflow"')
  [[ -z "$result" ]]
}

@test "allows: build: update config" {
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then skip; fi
  result=$(run_hook 'git commit -m "build: update config"')
  [[ -z "$result" ]]
}

@test "allows: revert: undo change" {
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then skip; fi
  result=$(run_hook 'git commit -m "revert: undo change"')
  [[ -z "$result" ]]
}

@test "allows: Merge commit" {
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then skip; fi
  result=$(run_hook "git commit -m 'Merge branch feat/something into develop'")
  [[ -z "$result" ]]
}

@test "blocks: non-conventional commit" {
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then skip; fi
  result=$(run_hook 'git commit -m "added new feature"')
  [[ "$result" == *'"permissionDecision":"deny"'* ]]
  [[ "$result" == *"conventional commits"* ]]
}

@test "blocks: missing space after colon" {
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then skip; fi
  result=$(run_hook 'git commit -m "feat:no space"')
  [[ "$result" == *'"permissionDecision":"deny"'* ]]
}

@test "blocks: uppercase type" {
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then skip; fi
  result=$(run_hook 'git commit -m "FEAT: uppercase"')
  [[ "$result" == *'"permissionDecision":"deny"'* ]]
}

@test "blocks: random commit message" {
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then skip; fi
  result=$(run_hook 'git commit -m "wip stuff"')
  [[ "$result" == *'"permissionDecision":"deny"'* ]]
}

@test "allows: single-quoted commit message" {
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then skip; fi
  result=$(run_hook "git commit -m 'feat: single quoted'")
  [[ -z "$result" ]]
}

# --- PR Merge Guard ---

@test "workflow-guard checks CI status before gh pr merge" {
  grep -q 'pr.*merge' "$HOOK"
  grep -q 'pr checks' "$HOOK"
}

@test "allows: non-merge gh pr commands" {
  result=$(run_hook "gh pr list")
  [[ -z "$result" ]]
}

# --- Secret Detection: verify patterns load from external file ---

@test "secret-patterns.txt is used by workflow-guard" {
  grep -q "secret-patterns.txt" "$HOOK"
}

# --- Branch freshness check ---

@test "workflow-guard checks upstream freshness on branch creation" {
  grep -q '@{u}' "$HOOK"
}
