#!/usr/bin/env bats
# Tests for hooks/post-edit-lint.sh

HOOK="hooks/post-edit-lint.sh"

@test "exits 0 for empty file_path" {
  run bash -c 'echo "{\"tool_input\":{}}" | '"$HOOK"
  [[ "$status" -eq 0 ]]
}

@test "exits 0 for missing file" {
  run bash -c 'echo "{\"tool_input\":{\"file_path\":\"/nonexistent/file.ts\"}}" | '"$HOOK"
  [[ "$status" -eq 0 ]]
}

@test "exits 0 for typescript file" {
  # Create a temp file
  TMPFILE=$(mktemp /tmp/test_XXXXXX.ts)
  echo "const x = 1" > "$TMPFILE"
  run bash -c 'echo "{\"tool_input\":{\"file_path\":\"'"$TMPFILE"'\"}}" | '"$HOOK"
  rm -f "$TMPFILE"
  [[ "$status" -eq 0 ]]
}

@test "exits 0 for python file" {
  TMPFILE=$(mktemp /tmp/test_XXXXXX.py)
  echo "x = 1" > "$TMPFILE"
  run bash -c 'echo "{\"tool_input\":{\"file_path\":\"'"$TMPFILE"'\"}}" | '"$HOOK"
  rm -f "$TMPFILE"
  [[ "$status" -eq 0 ]]
}

@test "exits 0 for json file" {
  TMPFILE=$(mktemp /tmp/test_XXXXXX.json)
  echo '{"key":"value"}' > "$TMPFILE"
  run bash -c 'echo "{\"tool_input\":{\"file_path\":\"'"$TMPFILE"'\"}}" | '"$HOOK"
  rm -f "$TMPFILE"
  [[ "$status" -eq 0 ]]
}

@test "exits 0 for unknown extension" {
  TMPFILE=$(mktemp /tmp/test_XXXXXX.xyz)
  echo "data" > "$TMPFILE"
  run bash -c 'echo "{\"tool_input\":{\"file_path\":\"'"$TMPFILE"'\"}}" | '"$HOOK"
  rm -f "$TMPFILE"
  [[ "$status" -eq 0 ]]
}
