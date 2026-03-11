#!/usr/bin/env bash
# Pre-tool-use hook: blocks dangerous Bash commands
# Reads tool input JSON from stdin, returns JSON decision

set -euo pipefail

# Read the tool input from stdin
INPUT=$(cat)

# Extract the command from the tool input
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Dangerous patterns to block
check_pattern() {
  local pattern="$1"
  local reason
  reason=$(echo "$2" | sed 's/\\/\\\\/g; s/"/\\"/g')
  if echo "$COMMAND" | grep -qiE "$pattern"; then
    echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"${reason}\"}}"
    exit 0
  fi
}

# Destructive filesystem operations
check_pattern 'rm[[:space:]]+(-[a-zA-Z]*f[a-zA-Z]*[[:space:]]+)?/' "Blocked: recursive delete on root/system paths is not allowed"
check_pattern 'rm[[:space:]]+-[a-zA-Z]*(rf|fr)[a-zA-Z]*[[:space:]]' "Blocked: rm -rf requires explicit user approval"
check_pattern 'rm[[:space:]]+-r[[:space:]]+-f[[:space:]]' "Blocked: rm -r -f requires explicit user approval"
check_pattern 'chmod[[:space:]]+777' "Blocked: chmod 777 is a security risk — use specific permissions"
check_pattern 'chown[[:space:]]+-R[[:space:]]+root' "Blocked: recursive chown to root is dangerous"

# Database destruction
check_pattern 'DROP[[:space:]]+(TABLE|DATABASE|SCHEMA)' "Blocked: DROP operations require manual execution"
check_pattern 'TRUNCATE[[:space:]]+TABLE' "Blocked: TRUNCATE requires manual execution"
check_pattern 'DELETE[[:space:]]+FROM[[:space:]]+[^[:space:]]+[[:space:]]*;?[[:space:]]*$' "Blocked: DELETE without WHERE clause is dangerous"

# Git destructive operations on main
check_pattern 'git[[:space:]]+push[[:space:]]+.*--force($|[[:space:]])' "Blocked: force push requires explicit user approval"
check_pattern 'git[[:space:]]+push[[:space:]]+-f[[:space:]]' "Blocked: force push requires explicit user approval"
check_pattern 'git[[:space:]]+push[[:space:]]+[^[:space:]]+[[:space:]]+\+' "Blocked: force push via + refspec requires explicit user approval"
check_pattern 'git[[:space:]]+branch[[:space:]]+-D[[:space:]]+(main|master)' "Blocked: deleting main/master branch is not allowed"

# Infrastructure destruction without plan
check_pattern 'terraform[[:space:]]+destroy[[:space:]]+(-auto-approve|--auto-approve)' "Blocked: terraform destroy with auto-approve requires manual execution"

# Credential exposure
check_pattern 'printenv|env[[:space:]]*$|set[[:space:]]*$' "Blocked: dumping environment variables may expose secrets"
check_pattern 'cat[[:space:]]+.*\.(pem|key|env)\b' "Blocked: reading secret files directly is not allowed"

# Network exfiltration
check_pattern 'curl[[:space:]]+.*\|[[:space:]]*(bash|sh|zsh)' "Blocked: piping curl to shell is a security risk"
check_pattern 'wget[[:space:]]+.*\|[[:space:]]*(bash|sh|zsh)' "Blocked: piping wget to shell is a security risk"

# If no dangerous patterns matched, allow the command
exit 0
