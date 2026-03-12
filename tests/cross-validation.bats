#!/usr/bin/env bats
# Cross-validation tests: consistency between configuration files

# --- Hooks consistency ---

@test "hooks.json and .claude/settings.json have the same lifecycle events" {
  hooks_events=$(jq -r '.hooks | keys[]' hooks/hooks.json | sort)
  settings_events=$(jq -r '.hooks | keys[]' .claude/settings.json | sort)
  [[ "$hooks_events" == "$settings_events" ]]
}

@test "hooks.json PreToolUse commands reference existing scripts" {
  while IFS= read -r cmd; do
    # Replace ${CLAUDE_PLUGIN_ROOT} with .
    resolved=$(echo "$cmd" | sed 's|\${CLAUDE_PLUGIN_ROOT}|.|g')
    [[ -f "$resolved" ]] || { echo "MISSING: $resolved (from $cmd)"; false; }
  done < <(jq -r '.hooks.PreToolUse[].hooks[].command // empty' hooks/hooks.json)
}

@test "hooks.json PostToolUse commands reference existing scripts" {
  while IFS= read -r cmd; do
    resolved=$(echo "$cmd" | sed 's|\${CLAUDE_PLUGIN_ROOT}|.|g')
    [[ -f "$resolved" ]] || { echo "MISSING: $resolved (from $cmd)"; false; }
  done < <(jq -r '.hooks.PostToolUse[].hooks[].command // empty' hooks/hooks.json)
}

@test "hooks.json SessionStart command references existing script" {
  while IFS= read -r cmd; do
    resolved=$(echo "$cmd" | sed 's|\${CLAUDE_PLUGIN_ROOT}|.|g')
    [[ -f "$resolved" ]] || { echo "MISSING: $resolved (from $cmd)"; false; }
  done < <(jq -r '.hooks.SessionStart[].hooks[].command // empty' hooks/hooks.json)
}

@test "all .sh scripts in hooks/ are referenced in hooks.json" {
  hooks_json_content=$(cat hooks/hooks.json)
  for script in hooks/*.sh; do
    basename=$(basename "$script")
    echo "$hooks_json_content" | grep -q "$basename" || { echo "UNREFERENCED: $script"; false; }
  done
}

@test "hooks.json uses CLAUDE_PLUGIN_ROOT variable in all command paths" {
  # All command-type hooks should use the variable
  while IFS= read -r cmd; do
    [[ "$cmd" == *'${CLAUDE_PLUGIN_ROOT}'* ]] || { echo "MISSING variable in: $cmd"; false; }
  done < <(jq -r '.. | .command? // empty' hooks/hooks.json | grep -v '^$')
}

# --- Permissions consistency ---

@test "settings.json and .claude/settings.json have the same permissions.allow" {
  root_allow=$(jq -r '.permissions.allow[]' settings.json | sort)
  claude_allow=$(jq -r '.permissions.allow[]' .claude/settings.json | sort)
  [[ "$root_allow" == "$claude_allow" ]]
}

@test "settings.json and .claude/settings.json have the same permissions.deny" {
  root_deny=$(jq -r '.permissions.deny[]' settings.json | sort)
  claude_deny=$(jq -r '.permissions.deny[]' .claude/settings.json | sort)
  [[ "$root_deny" == "$claude_deny" ]]
}

@test "every skill has Skill() permission in settings.json" {
  for skill_dir in skills/*/; do
    skill_name=$(basename "$skill_dir")
    # Check for Skill(vibe:skill-name) pattern
    if ! jq -r '.permissions.allow[]' settings.json | grep -q "Skill(vibe:${skill_name})"; then
      # Some skills might have wildcard like "Skill(vibe:fix-issue *)"
      if ! jq -r '.permissions.allow[]' settings.json | grep -q "Skill(vibe:${skill_name}"; then
        echo "MISSING permission for vibe:$skill_name in settings.json"; false
      fi
    fi
  done
}

@test "every skill has Skill() permission in .claude/settings.json" {
  for skill_dir in skills/*/; do
    skill_name=$(basename "$skill_dir")
    if ! jq -r '.permissions.allow[]' .claude/settings.json | grep -q "Skill(vibe:${skill_name})"; then
      if ! jq -r '.permissions.allow[]' .claude/settings.json | grep -q "Skill(vibe:${skill_name}"; then
        echo "MISSING permission for vibe:$skill_name in .claude/settings.json"; false
      fi
    fi
  done
}

# --- Templates consistency ---

@test "templates settings.json has the same permissions.allow as root settings.json" {
  template_allow=$(jq -r '.permissions.allow[]' skills/setup/templates/settings.json | sort)
  root_allow=$(jq -r '.permissions.allow[]' settings.json | sort)
  [[ "$template_allow" == "$root_allow" ]]
}

@test "templates settings.json has the same permissions.deny as root settings.json" {
  template_deny=$(jq -r '.permissions.deny[]' skills/setup/templates/settings.json | sort)
  root_deny=$(jq -r '.permissions.deny[]' settings.json | sort)
  [[ "$template_deny" == "$root_deny" ]]
}

@test "templates mcp.json is valid JSON with servers defined" {
  jq empty skills/setup/templates/mcp.json
  count=$(jq '.mcpServers | length' skills/setup/templates/mcp.json)
  [[ "$count" -gt 0 ]]
}

@test "CLAUDE.md templates reference commands that exist as skills" {
  for template in skills/setup/templates/claude-md/*.md; do
    [[ -f "$template" ]] || continue
    # Extract /vibe:xxx references from the template
    while IFS= read -r skill_ref; do
      skill_name=$(echo "$skill_ref" | sed 's|/vibe:||; s|[[:space:]].*||')
      [[ -d "skills/$skill_name" ]] || { echo "MISSING skill '$skill_name' referenced in $(basename "$template")"; false; }
    done < <(grep -oE '/vibe:[a-z-]+' "$template" 2>/dev/null || true)
  done
}

# --- Standards completeness ---

@test "every standard in docs/standards/ is referenced in CLAUDE.md" {
  for std_file in docs/standards/*.md; do
    basename=$(basename "$std_file")
    grep -q "$basename" CLAUDE.md || { echo "UNREFERENCED standard: $basename"; false; }
  done
}

@test "every standard referenced in CLAUDE.md exists in docs/standards/" {
  # Extract standard file references from CLAUDE.md
  while IFS= read -r ref; do
    std_file=$(echo "$ref" | grep -oE 'docs/standards/[a-z-]+\.md' || true)
    if [ -n "$std_file" ]; then
      [[ -f "$std_file" ]] || { echo "MISSING: $std_file referenced in CLAUDE.md"; false; }
    fi
  done < <(grep 'docs/standards/' CLAUDE.md)
}

@test "12 standards files exist and match CLAUDE.md count" {
  file_count=$(ls -1 docs/standards/*.md 2>/dev/null | wc -l | tr -d ' ')
  [[ "$file_count" -eq 12 ]]
  # Count references in CLAUDE.md
  ref_count=$(grep -cE 'docs/standards/[a-z-]+\.md' CLAUDE.md)
  [[ "$ref_count" -eq 12 ]]
}

# --- Marketplace + Plugin ---

@test "marketplace.json plugin name matches plugin.json name" {
  marketplace_name=$(jq -r '.plugins[0].name' .claude-plugin/marketplace.json)
  plugin_name=$(jq -r '.name' .claude-plugin/plugin.json)
  [[ "$marketplace_name" == "$plugin_name" ]]
}

@test "marketplace.json source repo is owner/repo format" {
  repo=$(jq -r '.plugins[0].source.repo' .claude-plugin/marketplace.json)
  [[ "$repo" =~ ^[a-zA-Z0-9_-]+/[a-zA-Z0-9_-]+$ ]]
}

@test "marketplace.json source type is github" {
  source_type=$(jq -r '.plugins[0].source.source' .claude-plugin/marketplace.json)
  [[ "$source_type" == "github" ]]
}

# --- Hooks JSON structure matches settings hooks ---

@test ".claude/settings.json hooks use relative paths (no CLAUDE_PLUGIN_ROOT)" {
  # .claude/settings.json should use relative paths since it's inside the project
  while IFS= read -r cmd; do
    [[ "$cmd" != *'${CLAUDE_PLUGIN_ROOT}'* ]] || { echo "UNEXPECTED variable in .claude/settings.json: $cmd"; false; }
  done < <(jq -r '.. | .command? // empty' .claude/settings.json | grep -v '^$')
}

@test "hooks.json and .claude/settings.json reference the same hook scripts" {
  # Extract script basenames from hooks.json
  hooks_json_scripts=$(jq -r '.. | .command? // empty' hooks/hooks.json | grep -v '^$' | xargs -I{} basename {} | sort)
  # Extract script basenames from .claude/settings.json
  settings_scripts=$(jq -r '.. | .command? // empty' .claude/settings.json | grep -v '^$' | xargs -I{} basename {} | sort)
  [[ "$hooks_json_scripts" == "$settings_scripts" ]]
}

# --- Hooks matchers consistency ---

@test "hooks.json and .claude/settings.json have same PreToolUse matchers" {
  hooks_matchers=$(jq -r '.hooks.PreToolUse[].matcher' hooks/hooks.json | sort)
  settings_matchers=$(jq -r '.hooks.PreToolUse[].matcher' .claude/settings.json | sort)
  [[ "$hooks_matchers" == "$settings_matchers" ]]
}

@test "hooks.json and .claude/settings.json have same PostToolUse matchers" {
  hooks_matchers=$(jq -r '.hooks.PostToolUse[].matcher' hooks/hooks.json | sort)
  settings_matchers=$(jq -r '.hooks.PostToolUse[].matcher' .claude/settings.json | sort)
  [[ "$hooks_matchers" == "$settings_matchers" ]]
}
