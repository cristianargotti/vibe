#!/usr/bin/env bash
# Post-tool-use hook: auto-formats files after Edit/Write operations
# Reads tool input JSON from stdin, formats based on file extension
# Runs async to avoid blocking Claude

set -euo pipefail

# Read the tool input from stdin
INPUT=$(cat)

# Extract the file path from the tool input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Get file extension
EXT="${FILE_PATH##*.}"

format_file() {
  case "$EXT" in
    ts|tsx|js|jsx|json|md|yml|yaml|css|scss)
      if command -v npx &>/dev/null; then
        npx --yes prettier --write "$FILE_PATH" 2>/dev/null &
      fi
      ;;
    py)
      if command -v ruff &>/dev/null; then
        ruff format "$FILE_PATH" 2>/dev/null &
        ruff check --fix "$FILE_PATH" 2>/dev/null &
      fi
      ;;
    tf|tfvars)
      if command -v terraform &>/dev/null; then
        terraform fmt "$FILE_PATH" 2>/dev/null &
      fi
      ;;
  esac
}

# Run formatting in background to avoid blocking
format_file &
wait
