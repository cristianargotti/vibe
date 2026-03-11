#!/usr/bin/env bash
# Vibe Health Check — validates plugin configuration
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

PASS=0
WARN=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
warn() { echo "  WARN: $1"; WARN=$((WARN + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "Vibe Health Check"
echo "================="
echo ""

# 1. Check plugin manifest
echo "Plugin Manifest:"
if [ -f "$PLUGIN_ROOT/.claude-plugin/plugin.json" ]; then
  if jq empty "$PLUGIN_ROOT/.claude-plugin/plugin.json" 2>/dev/null; then
    pass "plugin.json is valid JSON"
  else
    fail "plugin.json is invalid JSON"
  fi
else
  fail "plugin.json not found"
fi

if [ -f "$PLUGIN_ROOT/.claude-plugin/marketplace.json" ]; then
  if jq empty "$PLUGIN_ROOT/.claude-plugin/marketplace.json" 2>/dev/null; then
    pass "marketplace.json is valid JSON"
  else
    fail "marketplace.json is invalid JSON"
  fi
else
  fail "marketplace.json not found"
fi
echo ""

# 2. Check hooks
echo "Hooks:"
if [ -f "$PLUGIN_ROOT/hooks/hooks.json" ]; then
  if jq empty "$PLUGIN_ROOT/hooks/hooks.json" 2>/dev/null; then
    pass "hooks.json is valid JSON"
  else
    fail "hooks.json is invalid JSON"
  fi
else
  fail "hooks.json not found"
fi

for hook in block-dangerous-commands.sh workflow-guard.sh branch-guard.sh post-edit-lint.sh validate-config.sh; do
  if [ -f "$PLUGIN_ROOT/hooks/$hook" ]; then
    if [ -x "$PLUGIN_ROOT/hooks/$hook" ]; then
      pass "$hook exists and is executable"
    else
      warn "$hook exists but is not executable"
    fi
  else
    fail "$hook not found"
  fi
done
echo ""

# 3. Check skills
echo "Skills:"
for skill in setup review-security deploy-check fix-issue refactor create-pr test health-check whats-new; do
  if [ -f "$PLUGIN_ROOT/skills/$skill/SKILL.md" ]; then
    if head -1 "$PLUGIN_ROOT/skills/$skill/SKILL.md" | grep -q '^---'; then
      pass "/vibe:$skill has valid SKILL.md with frontmatter"
    else
      warn "/vibe:$skill SKILL.md missing YAML frontmatter"
    fi
  else
    fail "/vibe:$skill SKILL.md not found"
  fi
done
echo ""

# 4. Check agents
echo "Agents:"
for agent in code-reviewer.md ecommerce-expert.md infra-reviewer.md; do
  if [ -f "$PLUGIN_ROOT/agents/$agent" ]; then
    if [ -s "$PLUGIN_ROOT/agents/$agent" ]; then
      pass "$agent exists and is non-empty"
    else
      warn "$agent exists but is empty"
    fi
  else
    fail "$agent not found"
  fi
done
echo ""

# 5. Check settings
echo "Settings:"
if [ -f "$PLUGIN_ROOT/settings.json" ]; then
  if jq empty "$PLUGIN_ROOT/settings.json" 2>/dev/null; then
    pass "Plugin settings.json is valid JSON"
  else
    fail "Plugin settings.json is invalid JSON"
  fi
else
  fail "Plugin settings.json not found"
fi
echo ""

# 6. Check standards
echo "Standards:"
EXPECTED_STANDARDS="api-design aws database docker llm-ai nestjs observability python react-nextjs terraform testing typescript"
for std in $EXPECTED_STANDARDS; do
  if [ -f "$PLUGIN_ROOT/docs/standards/$std.md" ]; then
    pass "$std.md exists"
  else
    fail "$std.md not found"
  fi
done
echo ""

# 7. Version check
echo "Version:"
if [ -f "$PLUGIN_ROOT/versions.json" ]; then
  if jq empty "$PLUGIN_ROOT/versions.json" 2>/dev/null; then
    pass "versions.json is valid JSON"
    TRACKED=$(jq -r '.claudeCode' "$PLUGIN_ROOT/versions.json")
    if command -v claude &>/dev/null; then
      INSTALLED=$(claude --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
      if [ "$TRACKED" = "$INSTALLED" ]; then
        pass "Claude Code version matches: $TRACKED"
      else
        warn "Claude Code version mismatch: tracked=$TRACKED installed=$INSTALLED"
      fi
    else
      warn "Claude CLI not found — cannot verify version"
    fi
  else
    fail "versions.json is invalid JSON"
  fi
elif [ -f "$PLUGIN_ROOT/.claude-code-version" ]; then
  warn "Using legacy .claude-code-version — migrate to versions.json"
  TRACKED=$(cat "$PLUGIN_ROOT/.claude-code-version" | tr -d '[:space:]')
  if command -v claude &>/dev/null; then
    INSTALLED=$(claude --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
    if [ "$TRACKED" = "$INSTALLED" ]; then
      pass "Version matches: $TRACKED"
    else
      warn "Version mismatch: tracked=$TRACKED installed=$INSTALLED"
    fi
  else
    warn "Claude CLI not found — cannot verify version"
  fi
else
  fail "No version tracking file found (versions.json or .claude-code-version)"
fi
echo ""

# 8. Secret patterns
echo "Secret Patterns:"
if [ -f "$PLUGIN_ROOT/hooks/secret-patterns.txt" ]; then
  PATTERN_COUNT=$(grep -v '^#' "$PLUGIN_ROOT/hooks/secret-patterns.txt" | grep -v '^$' | wc -l | tr -d ' ')
  if [ "$PATTERN_COUNT" -ge 25 ]; then
    pass "secret-patterns.txt has $PATTERN_COUNT patterns"
  else
    warn "secret-patterns.txt has only $PATTERN_COUNT patterns (expected 25+)"
  fi
else
  fail "hooks/secret-patterns.txt not found"
fi
echo ""

# 9. Dependabot
echo "Auto-updates:"
if [ -f "$PLUGIN_ROOT/.github/dependabot.yml" ]; then
  pass "dependabot.yml present"
else
  warn "dependabot.yml not found — npm and GitHub Actions won't auto-update"
fi

# Check MCP template doesn't use deprecated server
if [ -f "$PLUGIN_ROOT/skills/setup/templates/mcp.json" ]; then
  if grep -q "@modelcontextprotocol/server-github" "$PLUGIN_ROOT/skills/setup/templates/mcp.json"; then
    warn "MCP template uses deprecated @modelcontextprotocol/server-github — migrate to ghcr.io/github/github-mcp-server"
  else
    pass "MCP template uses current GitHub MCP server"
  fi
fi
echo ""

# Summary
echo "========================"
echo "Results: $PASS passed, $WARN warnings, $FAIL failures"
if [ "$FAIL" -gt 0 ]; then
  echo "Status: BROKEN"
  exit 1
elif [ "$WARN" -gt 0 ]; then
  echo "Status: NEEDS ATTENTION"
  exit 0
else
  echo "Status: HEALTHY"
  exit 0
fi
