#!/usr/bin/env bats
# Tests for hooks/git-hooks/pre-commit

HOOK="hooks/git-hooks/pre-commit"

# Fake secret fragments — split so they don't trigger the secret detector
# on this test file itself. Expanded heredocs reassemble them at runtime.
_AKIA="AKI""A"
_GHP="ghp""_"
_PRIVKEY="-----BEGIN RSA PRIV""ATE KEY-----"
_SKANT="sk-a""nt-api03-abcdefghijklmnopqrstuvwxyz"
_SKLIVE="sk_li""ve_abcdefghijklmnopqrstuvwxyz1234"

# --- Branch Protection ---

@test "pre-commit: allows commit on feature branch" {
  MOCKDIR=$(mktemp -d)
  cat > "$MOCKDIR/git" << 'EOF'
#!/usr/bin/env bash
if [[ "$1" == "rev-parse" && "$2" == "--abbrev-ref" ]]; then
  echo "feat/test-feature"
  exit 0
fi
if [[ "$1" == "diff" && "$2" == "--cached" && "$3" == "--name-only" ]]; then
  echo ""
  exit 0
fi
exec /usr/bin/git "$@"
EOF
  chmod +x "$MOCKDIR/git"
  run bash -c "PATH='$MOCKDIR:$PATH' bash '$HOOK'"
  rm -rf "$MOCKDIR"
  [[ "$status" -eq 0 ]]
}

@test "pre-commit: blocks commit on main" {
  MOCKDIR=$(mktemp -d)
  cat > "$MOCKDIR/git" << 'EOF'
#!/usr/bin/env bash
if [[ "$1" == "rev-parse" && "$2" == "--abbrev-ref" ]]; then
  echo "main"
  exit 0
fi
exec /usr/bin/git "$@"
EOF
  chmod +x "$MOCKDIR/git"
  run bash -c "PATH='$MOCKDIR:$PATH' bash '$HOOK'"
  rm -rf "$MOCKDIR"
  [[ "$status" -eq 1 ]]
  [[ "$output" == *"Cannot commit directly on 'main'"* ]]
}

@test "pre-commit: blocks commit on master" {
  MOCKDIR=$(mktemp -d)
  cat > "$MOCKDIR/git" << 'EOF'
#!/usr/bin/env bash
if [[ "$1" == "rev-parse" && "$2" == "--abbrev-ref" ]]; then
  echo "master"
  exit 0
fi
exec /usr/bin/git "$@"
EOF
  chmod +x "$MOCKDIR/git"
  run bash -c "PATH='$MOCKDIR:$PATH' bash '$HOOK'"
  rm -rf "$MOCKDIR"
  [[ "$status" -eq 1 ]]
  [[ "$output" == *"Cannot commit directly on 'master'"* ]]
}

@test "pre-commit: blocks commit on develop" {
  MOCKDIR=$(mktemp -d)
  cat > "$MOCKDIR/git" << 'EOF'
#!/usr/bin/env bash
if [[ "$1" == "rev-parse" && "$2" == "--abbrev-ref" ]]; then
  echo "develop"
  exit 0
fi
exec /usr/bin/git "$@"
EOF
  chmod +x "$MOCKDIR/git"
  run bash -c "PATH='$MOCKDIR:$PATH' bash '$HOOK'"
  rm -rf "$MOCKDIR"
  [[ "$status" -eq 1 ]]
  [[ "$output" == *"Cannot commit directly on 'develop'"* ]]
}

@test "pre-commit: suggests creating feature branch when blocked" {
  MOCKDIR=$(mktemp -d)
  cat > "$MOCKDIR/git" << 'EOF'
#!/usr/bin/env bash
if [[ "$1" == "rev-parse" && "$2" == "--abbrev-ref" ]]; then
  echo "main"
  exit 0
fi
exec /usr/bin/git "$@"
EOF
  chmod +x "$MOCKDIR/git"
  run bash -c "PATH='$MOCKDIR:$PATH' bash '$HOOK'"
  rm -rf "$MOCKDIR"
  [[ "$output" == *"git checkout -b feat/"* ]]
}

# --- Secret Detection ---

@test "pre-commit: detects AWS AKIA key in staged diff" {
  MOCKDIR=$(mktemp -d)
  WORKDIR=$(mktemp -d)
  local FAKE="${_AKIA}IOSFODNN7EXAMPLE"
  echo "const key = '${FAKE}';" > "$WORKDIR/config.ts"
  cat > "$MOCKDIR/git" << EOF
#!/usr/bin/env bash
if [[ "\$1" == "rev-parse" && "\$2" == "--abbrev-ref" ]]; then
  echo "feat/test"
  exit 0
fi
if [[ "\$1" == "diff" && "\$2" == "--cached" && "\$3" == "--name-only" ]]; then
  echo "$WORKDIR/config.ts"
  exit 0
fi
if [[ "\$1" == "diff" && "\$2" == "--cached" && "\$3" == "--" ]]; then
  echo "+const key = '${FAKE}';"
  exit 0
fi
exec /usr/bin/git "\$@"
EOF
  chmod +x "$MOCKDIR/git"
  run bash -c "PATH='$MOCKDIR:$PATH' bash '$HOOK'"
  rm -rf "$MOCKDIR" "$WORKDIR"
  [[ "$status" -eq 1 ]]
  [[ "$output" == *"secrets detected"* ]]
}

@test "pre-commit: detects GitHub PAT in staged diff" {
  MOCKDIR=$(mktemp -d)
  WORKDIR=$(mktemp -d)
  local FAKE="${_GHP}ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghij"
  echo "token=${FAKE}" > "$WORKDIR/env.ts"
  cat > "$MOCKDIR/git" << EOF
#!/usr/bin/env bash
if [[ "\$1" == "rev-parse" && "\$2" == "--abbrev-ref" ]]; then
  echo "feat/test"
  exit 0
fi
if [[ "\$1" == "diff" && "\$2" == "--cached" && "\$3" == "--name-only" ]]; then
  echo "$WORKDIR/env.ts"
  exit 0
fi
if [[ "\$1" == "diff" && "\$2" == "--cached" && "\$3" == "--" ]]; then
  echo "+token=${FAKE}"
  exit 0
fi
exec /usr/bin/git "\$@"
EOF
  chmod +x "$MOCKDIR/git"
  run bash -c "PATH='$MOCKDIR:$PATH' bash '$HOOK'"
  rm -rf "$MOCKDIR" "$WORKDIR"
  [[ "$status" -eq 1 ]]
  [[ "$output" == *"secrets detected"* ]]
}

@test "pre-commit: detects private key header in staged diff" {
  MOCKDIR=$(mktemp -d)
  WORKDIR=$(mktemp -d)
  local FAKE="${_PRIVKEY}"
  echo "${FAKE}" > "$WORKDIR/key.pem"
  cat > "$MOCKDIR/git" << EOF
#!/usr/bin/env bash
if [[ "\$1" == "rev-parse" && "\$2" == "--abbrev-ref" ]]; then
  echo "feat/test"
  exit 0
fi
if [[ "\$1" == "diff" && "\$2" == "--cached" && "\$3" == "--name-only" ]]; then
  echo "$WORKDIR/key.pem"
  exit 0
fi
if [[ "\$1" == "diff" && "\$2" == "--cached" && "\$3" == "--" ]]; then
  echo "+${FAKE}"
  exit 0
fi
exec /usr/bin/git "\$@"
EOF
  chmod +x "$MOCKDIR/git"
  run bash -c "PATH='$MOCKDIR:$PATH' bash '$HOOK'"
  rm -rf "$MOCKDIR" "$WORKDIR"
  [[ "$status" -eq 1 ]]
  [[ "$output" == *"secrets detected"* ]]
}

@test "pre-commit: detects Anthropic API key in staged diff" {
  MOCKDIR=$(mktemp -d)
  WORKDIR=$(mktemp -d)
  local FAKE="${_SKANT}"
  echo "ANTHROPIC_API_KEY=${FAKE}" > "$WORKDIR/cfg.ts"
  cat > "$MOCKDIR/git" << EOF
#!/usr/bin/env bash
if [[ "\$1" == "rev-parse" && "\$2" == "--abbrev-ref" ]]; then
  echo "feat/test"
  exit 0
fi
if [[ "\$1" == "diff" && "\$2" == "--cached" && "\$3" == "--name-only" ]]; then
  echo "$WORKDIR/cfg.ts"
  exit 0
fi
if [[ "\$1" == "diff" && "\$2" == "--cached" && "\$3" == "--" ]]; then
  echo "+ANTHROPIC_API_KEY=${FAKE}"
  exit 0
fi
exec /usr/bin/git "\$@"
EOF
  chmod +x "$MOCKDIR/git"
  run bash -c "PATH='$MOCKDIR:$PATH' bash '$HOOK'"
  rm -rf "$MOCKDIR" "$WORKDIR"
  [[ "$status" -eq 1 ]]
  [[ "$output" == *"secrets detected"* ]]
}

@test "pre-commit: allows commit without secrets in staged diff" {
  MOCKDIR=$(mktemp -d)
  WORKDIR=$(mktemp -d)
  echo "const name = 'hello';" > "$WORKDIR/app.ts"
  cat > "$MOCKDIR/git" << EOF
#!/usr/bin/env bash
if [[ "\$1" == "rev-parse" && "\$2" == "--abbrev-ref" ]]; then
  echo "feat/test"
  exit 0
fi
if [[ "\$1" == "diff" && "\$2" == "--cached" && "\$3" == "--name-only" ]]; then
  echo "$WORKDIR/app.ts"
  exit 0
fi
if [[ "\$1" == "diff" && "\$2" == "--cached" && "\$3" == "--" ]]; then
  echo "+const name = 'hello';"
  exit 0
fi
exec /usr/bin/git "\$@"
EOF
  chmod +x "$MOCKDIR/git"
  run bash -c "PATH='$MOCKDIR:$PATH' bash '$HOOK'"
  rm -rf "$MOCKDIR" "$WORKDIR"
  [[ "$status" -eq 0 ]]
}

@test "pre-commit: allows commit with empty staged diff" {
  MOCKDIR=$(mktemp -d)
  cat > "$MOCKDIR/git" << 'EOF'
#!/usr/bin/env bash
if [[ "$1" == "rev-parse" && "$2" == "--abbrev-ref" ]]; then
  echo "feat/test"
  exit 0
fi
if [[ "$1" == "diff" && "$2" == "--cached" && "$3" == "--name-only" ]]; then
  echo ""
  exit 0
fi
exec /usr/bin/git "$@"
EOF
  chmod +x "$MOCKDIR/git"
  run bash -c "PATH='$MOCKDIR:$PATH' bash '$HOOK'"
  rm -rf "$MOCKDIR"
  [[ "$status" -eq 0 ]]
}

@test "pre-commit: does not flag context lines (only + lines)" {
  MOCKDIR=$(mktemp -d)
  WORKDIR=$(mktemp -d)
  local FAKE="${_AKIA}IOSFODNN7EXAMPLE"
  echo "safe code" > "$WORKDIR/app.ts"
  cat > "$MOCKDIR/git" << EOF
#!/usr/bin/env bash
if [[ "\$1" == "rev-parse" && "\$2" == "--abbrev-ref" ]]; then
  echo "feat/test"
  exit 0
fi
if [[ "\$1" == "diff" && "\$2" == "--cached" && "\$3" == "--name-only" ]]; then
  echo "$WORKDIR/app.ts"
  exit 0
fi
if [[ "\$1" == "diff" && "\$2" == "--cached" && "\$3" == "--" ]]; then
  # Context line (no +), should NOT be flagged
  printf ' const old = "%s";\n+const safe = "hello";' "${FAKE}"
  exit 0
fi
exec /usr/bin/git "\$@"
EOF
  chmod +x "$MOCKDIR/git"
  run bash -c "PATH='$MOCKDIR:$PATH' bash '$HOOK'"
  rm -rf "$MOCKDIR" "$WORKDIR"
  [[ "$status" -eq 0 ]]
}

# --- Secret patterns file usage ---

@test "pre-commit: uses secret-patterns.txt if it exists" {
  grep -q "secret-patterns.txt" "$HOOK"
}

@test "pre-commit: has fallback patterns if secret-patterns.txt missing" {
  # Check the hook source contains fallback patterns
  grep -q 'AKIA' "$HOOK"
  grep -q 'PRIVATE KEY' "$HOOK"
  grep -q 'ghp_' "$HOOK"
}

@test "pre-commit: resolves secret-patterns.txt relative to script dir" {
  grep -q 'SCRIPT_DIR' "$HOOK"
  grep -q 'PATTERN_FILE' "$HOOK"
}

# --- Exit codes ---

@test "pre-commit: exit code 0 on feature branch without secrets" {
  MOCKDIR=$(mktemp -d)
  cat > "$MOCKDIR/git" << 'EOF'
#!/usr/bin/env bash
if [[ "$1" == "rev-parse" && "$2" == "--abbrev-ref" ]]; then
  echo "fix/bugfix-123"
  exit 0
fi
if [[ "$1" == "diff" && "$2" == "--cached" && "$3" == "--name-only" ]]; then
  echo ""
  exit 0
fi
exec /usr/bin/git "$@"
EOF
  chmod +x "$MOCKDIR/git"
  run bash -c "PATH='$MOCKDIR:$PATH' bash '$HOOK'"
  rm -rf "$MOCKDIR"
  [[ "$status" -eq 0 ]]
}

@test "pre-commit: exit code 1 on protected branch" {
  MOCKDIR=$(mktemp -d)
  cat > "$MOCKDIR/git" << 'EOF'
#!/usr/bin/env bash
if [[ "$1" == "rev-parse" && "$2" == "--abbrev-ref" ]]; then
  echo "main"
  exit 0
fi
exec /usr/bin/git "$@"
EOF
  chmod +x "$MOCKDIR/git"
  run bash -c "PATH='$MOCKDIR:$PATH' bash '$HOOK'"
  rm -rf "$MOCKDIR"
  [[ "$status" -eq 1 ]]
}

@test "pre-commit: exit code 1 with secrets detected" {
  MOCKDIR=$(mktemp -d)
  WORKDIR=$(mktemp -d)
  local FAKE="${_SKLIVE}"
  echo "key" > "$WORKDIR/secret.ts"
  cat > "$MOCKDIR/git" << EOF
#!/usr/bin/env bash
if [[ "\$1" == "rev-parse" && "\$2" == "--abbrev-ref" ]]; then
  echo "feat/test"
  exit 0
fi
if [[ "\$1" == "diff" && "\$2" == "--cached" && "\$3" == "--name-only" ]]; then
  echo "$WORKDIR/secret.ts"
  exit 0
fi
if [[ "\$1" == "diff" && "\$2" == "--cached" && "\$3" == "--" ]]; then
  echo "+${FAKE}"
  exit 0
fi
exec /usr/bin/git "\$@"
EOF
  chmod +x "$MOCKDIR/git"
  run bash -c "PATH='$MOCKDIR:$PATH' bash '$HOOK'"
  rm -rf "$MOCKDIR" "$WORKDIR"
  [[ "$status" -eq 1 ]]
}

@test "pre-commit: suggests using env vars when secrets found" {
  MOCKDIR=$(mktemp -d)
  WORKDIR=$(mktemp -d)
  local FAKE="${_AKIA}IOSFODNN7EXAMPLE"
  echo "key" > "$WORKDIR/cfg.ts"
  cat > "$MOCKDIR/git" << EOF
#!/usr/bin/env bash
if [[ "\$1" == "rev-parse" && "\$2" == "--abbrev-ref" ]]; then
  echo "feat/test"
  exit 0
fi
if [[ "\$1" == "diff" && "\$2" == "--cached" && "\$3" == "--name-only" ]]; then
  echo "$WORKDIR/cfg.ts"
  exit 0
fi
if [[ "\$1" == "diff" && "\$2" == "--cached" && "\$3" == "--" ]]; then
  echo "+${FAKE}"
  exit 0
fi
exec /usr/bin/git "\$@"
EOF
  chmod +x "$MOCKDIR/git"
  run bash -c "PATH='$MOCKDIR:$PATH' bash '$HOOK'"
  rm -rf "$MOCKDIR" "$WORKDIR"
  [[ "$output" == *"environment variables"* ]]
}

# --- Allows various feature branch naming ---

@test "pre-commit: allows commit on fix/ branch" {
  MOCKDIR=$(mktemp -d)
  cat > "$MOCKDIR/git" << 'EOF'
#!/usr/bin/env bash
if [[ "$1" == "rev-parse" && "$2" == "--abbrev-ref" ]]; then
  echo "fix/important-bug"
  exit 0
fi
if [[ "$1" == "diff" && "$2" == "--cached" && "$3" == "--name-only" ]]; then
  echo ""
  exit 0
fi
exec /usr/bin/git "$@"
EOF
  chmod +x "$MOCKDIR/git"
  run bash -c "PATH='$MOCKDIR:$PATH' bash '$HOOK'"
  rm -rf "$MOCKDIR"
  [[ "$status" -eq 0 ]]
}

@test "pre-commit: allows commit on refactor/ branch" {
  MOCKDIR=$(mktemp -d)
  cat > "$MOCKDIR/git" << 'EOF'
#!/usr/bin/env bash
if [[ "$1" == "rev-parse" && "$2" == "--abbrev-ref" ]]; then
  echo "refactor/auth-module"
  exit 0
fi
if [[ "$1" == "diff" && "$2" == "--cached" && "$3" == "--name-only" ]]; then
  echo ""
  exit 0
fi
exec /usr/bin/git "$@"
EOF
  chmod +x "$MOCKDIR/git"
  run bash -c "PATH='$MOCKDIR:$PATH' bash '$HOOK'"
  rm -rf "$MOCKDIR"
  [[ "$status" -eq 0 ]]
}

@test "pre-commit: script is executable" {
  [[ -x "$HOOK" ]]
}

@test "pre-commit: script has bash shebang" {
  head -1 "$HOOK" | grep -q "^#!/usr/bin/env bash"
}
