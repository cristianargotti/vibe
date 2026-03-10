#!/usr/bin/env bash
# Pre-tool-use hook: blocks dangerous Bash commands
# Reads tool input JSON from stdin, returns JSON decision

set -euo pipefail

# Read the tool input from stdin
INPUT=$(cat)

# Extract the command from the tool input
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  echo '{"decision":"allow"}'
  exit 0
fi

# Dangerous patterns to block
check_pattern() {
  local pattern="$1"
  local reason="$2"
  if echo "$COMMAND" | grep -qiE "$pattern"; then
    echo "{\"decision\":\"deny\",\"reason\":\"$reason\"}"
    exit 0
  fi
}

# Destructive filesystem operations
check_pattern 'rm\s+(-[a-zA-Z]*f[a-zA-Z]*\s+)?/' "Blocked: recursive delete on root/system paths is not allowed"
check_pattern 'rm\s+-rf\s' "Blocked: rm -rf requires explicit user approval"
check_pattern 'chmod\s+777' "Blocked: chmod 777 is a security risk — use specific permissions"
check_pattern 'chown\s+-R\s+root' "Blocked: recursive chown to root is dangerous"

# Database destruction
check_pattern 'DROP\s+(TABLE|DATABASE|SCHEMA)' "Blocked: DROP operations require manual execution"
check_pattern 'TRUNCATE\s+TABLE' "Blocked: TRUNCATE requires manual execution"
check_pattern 'DELETE\s+FROM\s+\S+\s*;?\s*$' "Blocked: DELETE without WHERE clause is dangerous"

# Git destructive operations on main
check_pattern 'git\s+push\s+.*--force.*\s+(main|master)' "Blocked: force push to main/master is not allowed"
check_pattern 'git\s+push\s+-f\s+.*\s+(main|master)' "Blocked: force push to main/master is not allowed"
check_pattern 'git\s+branch\s+-D\s+(main|master)' "Blocked: deleting main/master branch is not allowed"

# Infrastructure destruction without plan
check_pattern 'terraform\s+destroy\s+(-auto-approve|--auto-approve)' "Blocked: terraform destroy with auto-approve requires manual execution"

# Credential exposure
check_pattern 'printenv|env\s*$|set\s*$' "Blocked: dumping environment variables may expose secrets"
check_pattern 'cat\s+.*\.(pem|key|env)' "Blocked: reading secret files directly is not allowed"

# Network exfiltration
check_pattern 'curl\s+.*\|\s*bash' "Blocked: piping curl to bash is a security risk"
check_pattern 'wget\s+.*\|\s*bash' "Blocked: piping wget to bash is a security risk"

# If no dangerous patterns matched, allow the command
echo '{"decision":"allow"}'
