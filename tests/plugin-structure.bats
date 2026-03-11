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

@test "plugin.json has only name, description, author (auto-discovery)" {
  keys=$(jq -r 'keys[]' .claude-plugin/plugin.json | sort | tr '\n' ',')
  [[ "$keys" == "author,description,name," ]]
}

# --- Auto-discovered skills exist ---

@test "9 skill directories exist with SKILL.md" {
  count=0
  for skill_dir in skills/*/; do
    [[ -f "$skill_dir/SKILL.md" ]] && ((count++))
  done
  [[ "$count" -eq 9 ]]
}

# --- Auto-discovered agents exist ---

@test "3 agent files exist" {
  count=$(ls -1 agents/*.md 2>/dev/null | wc -l | tr -d ' ')
  [[ "$count" -eq 3 ]]
}

# --- Skills frontmatter has no deprecated fields ---

@test "no SKILL.md uses deprecated model field" {
  for skill_dir in skills/*/; do
    skill_file="${skill_dir}SKILL.md"
    [[ -f "$skill_file" ]] || continue
    ! grep -q "^model:" "$skill_file" || { echo "DEPRECATED model: in $skill_file"; false; }
  done
}

@test "no SKILL.md uses deprecated context field" {
  for skill_dir in skills/*/; do
    skill_file="${skill_dir}SKILL.md"
    [[ -f "$skill_file" ]] || continue
    ! grep -q "^context:" "$skill_file" || { echo "DEPRECATED context: in $skill_file"; false; }
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

@test "hooks.json Stop hook has no matcher field" {
  result=$(jq '.hooks.Stop[0] | has("matcher")' hooks/hooks.json)
  [[ "$result" == "false" ]]
}

@test "hooks.json SessionStart hook has no matcher field" {
  result=$(jq '.hooks.SessionStart[0] | has("matcher")' hooks/hooks.json)
  [[ "$result" == "false" ]]
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

@test ".claude/settings.json Stop hook has no matcher field" {
  result=$(jq '.hooks.Stop[0] | has("matcher")' .claude/settings.json)
  [[ "$result" == "false" ]]
}

@test ".claude/settings.json has SessionStart hook" {
  count=$(jq '.hooks.SessionStart | length' .claude/settings.json)
  [[ "$count" -gt 0 ]]
}

@test ".claude/settings.json SessionStart hook has no matcher field" {
  result=$(jq '.hooks.SessionStart[0] | has("matcher")' .claude/settings.json)
  [[ "$result" == "false" ]]
}

# --- Permissions completeness ---

@test "settings.json has Bash(uvx *) permission" {
  jq -r '.permissions.allow[]' settings.json | grep -q 'Bash(uvx \*)'
}

@test "settings.json has git fetch permission" {
  jq -r '.permissions.allow[]' settings.json | grep -q 'Bash(git fetch \*)'
}

@test "settings.json has git pull permission" {
  jq -r '.permissions.allow[]' settings.json | grep -q 'Bash(git pull \*)'
}

@test "settings.json has git switch permission" {
  jq -r '.permissions.allow[]' settings.json | grep -q 'Bash(git switch \*)'
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

@test "marketplace.json references cristianargotti/vibe repo" {
  result=$(jq -r '.plugins[0].source.repo' .claude-plugin/marketplace.json)
  [[ "$result" == "cristianargotti/vibe" ]]
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
