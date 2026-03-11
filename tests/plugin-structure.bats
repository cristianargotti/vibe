#!/usr/bin/env bats
# Tests for plugin structure, JSON validity, and file integrity

# --- JSON Validity ---

@test "plugin.json is valid JSON" {
  jq empty .claude-plugin/plugin.json
}

@test "marketplace.json is valid JSON" {
  jq empty .claude-plugin/marketplace.json
}

@test "hooks/hooks.json is valid JSON" {
  jq empty hooks/hooks.json
}

@test "settings.json (root) is valid JSON" {
  jq empty settings.json
}

@test ".claude/settings.json is valid JSON" {
  jq empty .claude/settings.json
}

@test "skills/setup/templates/settings.json is valid JSON" {
  jq empty skills/setup/templates/settings.json
}

@test "skills/setup/templates/mcp.json is valid JSON" {
  jq empty skills/setup/templates/mcp.json
}

# --- Plugin Manifest ---

@test "plugin.json has name 'vibe'" {
  result=$(jq -r '.name' .claude-plugin/plugin.json)
  [[ "$result" == "vibe" ]]
}

@test "plugin.json has version" {
  result=$(jq -r '.version' .claude-plugin/plugin.json)
  [[ "$result" != "null" ]]
  [[ "$result" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "plugin.json lists 9 skills" {
  count=$(jq '.skills | length' .claude-plugin/plugin.json)
  [[ "$count" -eq 9 ]]
}

@test "plugin.json lists 3 agents" {
  count=$(jq '.agents | length' .claude-plugin/plugin.json)
  [[ "$count" -eq 3 ]]
}

@test "plugin.json references hooks.json" {
  result=$(jq -r '.hooks' .claude-plugin/plugin.json)
  [[ "$result" == "hooks/hooks.json" ]]
}

@test "plugin.json references settings.json" {
  result=$(jq -r '.settings' .claude-plugin/plugin.json)
  [[ "$result" == "settings.json" ]]
}

# --- All referenced skills exist ---

@test "all skill directories in plugin.json exist" {
  jq -r '.skills[]' .claude-plugin/plugin.json | while read -r skill_path; do
    [[ -d "$skill_path" ]] || { echo "MISSING: $skill_path"; false; }
    [[ -f "$skill_path/SKILL.md" ]] || { echo "MISSING: $skill_path/SKILL.md"; false; }
  done
}

# --- All referenced agents exist ---

@test "all agent files in plugin.json exist" {
  jq -r '.agents[]' .claude-plugin/plugin.json | while read -r agent_path; do
    [[ -f "$agent_path" ]] || { echo "MISSING: $agent_path"; false; }
  done
}

# --- Skill Frontmatter ---

@test "all SKILL.md files have YAML frontmatter" {
  for skill_dir in skills/*/; do
    skill_file="$skill_dir/SKILL.md"
    [[ -f "$skill_file" ]] || continue
    head -1 "$skill_file" | grep -q "^---$" || { echo "MISSING frontmatter: $skill_file"; false; }
  done
}

@test "all SKILL.md files have name field" {
  for skill_dir in skills/*/; do
    skill_file="${skill_dir}SKILL.md"
    [[ -f "$skill_file" ]] || continue
    # Extract frontmatter and check for name
    grep -q "^name:" "$skill_file" || { echo "MISSING name: $skill_file"; false; }
  done
}

@test "all SKILL.md files have description field" {
  for skill_dir in skills/*/; do
    skill_file="${skill_dir}SKILL.md"
    [[ -f "$skill_file" ]] || continue
    grep -q "^description:" "$skill_file" || { echo "MISSING description: $skill_file"; false; }
  done
}

# --- Hook Scripts ---

@test "all hook scripts are executable" {
  for script in hooks/*.sh; do
    [[ -x "$script" ]] || { echo "NOT executable: $script"; false; }
  done
}

@test "all git hooks are executable" {
  for hook in hooks/git-hooks/*; do
    [[ -x "$hook" ]] || { echo "NOT executable: $hook"; false; }
  done
}

@test "all hook scripts have shebang" {
  for script in hooks/*.sh hooks/git-hooks/*; do
    [[ -f "$script" ]] || continue
    head -1 "$script" | grep -q "^#!/usr/bin/env bash" || { echo "BAD shebang: $script"; false; }
  done
}

# --- Agent Files ---

@test "agents are non-empty" {
  for agent in agents/*.md; do
    [[ -s "$agent" ]] || { echo "EMPTY: $agent"; false; }
  done
}

# --- Hooks JSON Structure ---

@test "hooks.json has PreToolUse hooks" {
  count=$(jq '.hooks.PreToolUse | length' hooks/hooks.json)
  [[ "$count" -gt 0 ]]
}

@test "hooks.json has PostToolUse hooks" {
  count=$(jq '.hooks.PostToolUse | length' hooks/hooks.json)
  [[ "$count" -gt 0 ]]
}

@test "hooks.json has Stop hook" {
  count=$(jq '.hooks.Stop | length' hooks/hooks.json)
  [[ "$count" -gt 0 ]]
}

@test "hooks.json has SessionStart hook" {
  count=$(jq '.hooks.SessionStart | length' hooks/hooks.json)
  [[ "$count" -gt 0 ]]
}

@test "hooks.json Stop hook has matcher field" {
  result=$(jq -r '.hooks.Stop[0].matcher' hooks/hooks.json)
  [[ "$result" == "" ]]
}

@test "hooks.json SessionStart hook has matcher field" {
  result=$(jq -r '.hooks.SessionStart[0].matcher' hooks/hooks.json)
  [[ "$result" == "" ]]
}

# --- Settings ---

@test "settings.json has permissions.allow" {
  count=$(jq '.permissions.allow | length' settings.json)
  [[ "$count" -gt 0 ]]
}

@test "settings.json has permissions.deny" {
  count=$(jq '.permissions.deny | length' settings.json)
  [[ "$count" -gt 0 ]]
}

@test ".claude/settings.json has hooks section" {
  result=$(jq 'has("hooks")' .claude/settings.json)
  [[ "$result" == "true" ]]
}

@test ".claude/settings.json Stop hook has matcher field" {
  result=$(jq -r '.hooks.Stop[0].matcher' .claude/settings.json)
  [[ "$result" == "" ]]
}

# --- Skills have vibe: prefix in permissions ---

@test "settings.json includes vibe:review-security skill" {
  jq -r '.permissions.allow[]' settings.json | grep -q 'Skill(vibe:review-security)'
}

@test "settings.json includes vibe:setup skill" {
  jq -r '.permissions.allow[]' settings.json | grep -q 'Skill(vibe:setup)'
}

@test ".claude/settings.json includes vibe:review-security skill" {
  jq -r '.permissions.allow[]' .claude/settings.json | grep -q 'Skill(vibe:review-security)'
}

# --- Marketplace ---

@test "marketplace.json has dafiti-tools name" {
  result=$(jq -r '.name' .claude-plugin/marketplace.json)
  [[ "$result" == "dafiti-tools" ]]
}

@test "marketplace.json has vibe plugin entry" {
  result=$(jq -r '.plugins[0].name' .claude-plugin/marketplace.json)
  [[ "$result" == "vibe" ]]
}

@test "marketplace.json references dafiti-group/vibe repo" {
  result=$(jq -r '.plugins[0].source.repo' .claude-plugin/marketplace.json)
  [[ "$result" == "dafiti-group/vibe" ]]
}

# --- Version Tracker ---

@test "versions.json exists and is valid JSON" {
  [[ -f "versions.json" ]]
  jq empty versions.json
}

@test "versions.json has plugin version" {
  result=$(jq -r '.plugin' versions.json)
  [[ "$result" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "versions.json has claudeCode version" {
  result=$(jq -r '.claudeCode' versions.json)
  [[ "$result" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "versions.json has mcp section" {
  count=$(jq '.mcp | length' versions.json)
  [[ "$count" -ge 3 ]]
}

# --- No Legacy References ---

@test "no .claude/commands directory (migrated to skills)" {
  [[ ! -d ".claude/commands" ]]
}

@test "no .claude/skills directory (migrated to skills/)" {
  [[ ! -d ".claude/skills" ]]
}

@test "no .claude/agents directory (migrated to agents/)" {
  [[ ! -d ".claude/agents" ]]
}

# --- Templates ---

@test "setup templates exist: CLAUDE.md variants" {
  [[ -f "skills/setup/templates/claude-md/typescript.md" ]]
  [[ -f "skills/setup/templates/claude-md/python.md" ]]
  [[ -f "skills/setup/templates/claude-md/fullstack.md" ]]
  [[ -f "skills/setup/templates/claude-md/infra.md" ]]
}

@test "setup templates exist: rules" {
  [[ -f "skills/setup/templates/rules/backend.md" ]]
  [[ -f "skills/setup/templates/rules/frontend.md" ]]
  [[ -f "skills/setup/templates/rules/infra.md" ]]
  [[ -f "skills/setup/templates/rules/quality.md" ]]
  [[ -f "skills/setup/templates/rules/security.md" ]]
}

@test "setup templates exist: settings and mcp" {
  [[ -f "skills/setup/templates/settings.json" ]]
  [[ -f "skills/setup/templates/mcp.json" ]]
}

# --- Standards ---

@test "12 standards files exist" {
  count=$(ls -1 docs/standards/*.md 2>/dev/null | wc -l | tr -d ' ')
  [[ "$count" -eq 12 ]]
}

# --- README ---

@test "README mentions plugin (not template)" {
  grep -qi "plugin" README.md
}

@test "README does not mention bash /tmp/vibe/setup.sh" {
  ! grep -q "/tmp/vibe/setup.sh" README.md
}

# --- Dependabot ---

@test "dependabot.yml exists" {
  [[ -f ".github/dependabot.yml" ]]
}

# --- Secret Patterns ---

@test "secret-patterns.txt exists" {
  [[ -f "hooks/secret-patterns.txt" ]]
}

# --- MCP Template ---

@test "MCP template does not use deprecated server-github" {
  ! grep -q "@modelcontextprotocol/server-github" skills/setup/templates/mcp.json
}

@test "MCP template uses Docker for GitHub MCP" {
  grep -q "github-mcp-server" skills/setup/templates/mcp.json
}

# --- LICENSE ---

@test "LICENSE file exists" {
  [[ -f "LICENSE" ]]
}
