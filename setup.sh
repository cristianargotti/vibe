#!/usr/bin/env bash
# Vibe Setup Script
# Adds Claude Code configuration to an existing project or sets up a new one.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${1:-.}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[vibe]${NC} $1"; }
warn() { echo -e "${YELLOW}[vibe]${NC} $1"; }
error() { echo -e "${RED}[vibe]${NC} $1"; exit 1; }

# --- Prerequisite checks ---
info "Checking prerequisites..."

command -v git &>/dev/null || error "git is required. Install it: https://git-scm.com"
command -v node &>/dev/null || error "node is required. Install it: https://nodejs.org"
command -v jq &>/dev/null || error "jq is required. Install it: brew install jq / apt install jq"

if command -v claude &>/dev/null; then
  info "Claude Code CLI found: $(claude --version 2>/dev/null || echo 'installed')"
else
  warn "Claude Code CLI not found. Install it: npm install -g @anthropic-ai/claude-code"
fi

# --- Target directory setup ---
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

if [ "$TARGET_DIR" = "$SCRIPT_DIR" ]; then
  info "Running in the Vibe template directory itself — nothing to copy."
  info "Usage: ./setup.sh /path/to/your/project"
  exit 0
fi

info "Setting up in: $TARGET_DIR"
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

# --- Git init if needed ---
if [ ! -d ".git" ]; then
  info "Initializing git repository..."
  git init
fi

# --- Copy Claude Code configuration ---
info "Copying Claude Code configuration..."

# Copy .claude directory (preserving structure)
if [ -d "$SCRIPT_DIR/.claude" ]; then
  mkdir -p .claude
  cp -r "$SCRIPT_DIR/.claude/rules" .claude/ 2>/dev/null || true
  cp -r "$SCRIPT_DIR/.claude/commands" .claude/ 2>/dev/null || true
  cp -r "$SCRIPT_DIR/.claude/skills" .claude/ 2>/dev/null || true
  cp -r "$SCRIPT_DIR/.claude/agents" .claude/ 2>/dev/null || true
  cp "$SCRIPT_DIR/.claude/settings.json" .claude/ 2>/dev/null || true
  cp "$SCRIPT_DIR/.claude/settings.local.json.example" .claude/ 2>/dev/null || true
fi

# Copy hooks
if [ -d "$SCRIPT_DIR/hooks" ]; then
  mkdir -p hooks
  cp -r "$SCRIPT_DIR/hooks/"* hooks/
  chmod +x hooks/*.sh
  # Make native git hooks executable
  if [ -d "hooks/git-hooks" ]; then
    chmod +x hooks/git-hooks/*
  fi
fi

# --- Configure native git hooks ---
# Set git hooks path (skip if husky, lefthook, or pre-commit framework is detected)
if [ -d "hooks/git-hooks" ]; then
  if [ -f ".husky/_/husky.sh" ] || [ -f ".lefthook.yml" ] || [ -f ".pre-commit-config.yaml" ]; then
    warn "Existing git hook framework detected — skipping git hooks path configuration"
    warn "Manually integrate hooks/git-hooks/ with your hook framework"
  else
    git config core.hooksPath hooks/git-hooks
    info "Configured git hooks path: hooks/git-hooks/"
  fi
fi

# Copy docs/standards
if [ -d "$SCRIPT_DIR/docs/standards" ]; then
  mkdir -p docs/standards
  cp -r "$SCRIPT_DIR/docs/standards/"* docs/standards/
fi

# Copy GitHub templates and workflows
if [ -d "$SCRIPT_DIR/.github" ]; then
  mkdir -p .github
  cp -r "$SCRIPT_DIR/.github/"* .github/
fi

# Copy root files
cp "$SCRIPT_DIR/CLAUDE.md" . 2>/dev/null || true
cp "$SCRIPT_DIR/REVIEW.md" . 2>/dev/null || true
cp "$SCRIPT_DIR/.mcp.json" . 2>/dev/null || true

# --- Smart merge .gitignore ---
if [ -f ".gitignore" ]; then
  info "Merging .gitignore..."
  while IFS= read -r line; do
    if [ -n "$line" ] && ! grep -qF "$line" .gitignore; then
      echo "$line" >> .gitignore
    fi
  done < "$SCRIPT_DIR/.gitignore"
else
  cp "$SCRIPT_DIR/.gitignore" .
fi

# --- Handle package.json ---
if [ -f "package.json" ]; then
  info "Adding dev dependencies to existing package.json..."
  npm install --save-dev eslint prettier @typescript-eslint/eslint-plugin @typescript-eslint/parser 2>/dev/null || warn "npm install failed — you may need to install dependencies manually"
else
  cp "$SCRIPT_DIR/package.json" .
  info "Created package.json with dev dependencies"
fi

# --- Create settings.local.json from example ---
if [ ! -f ".claude/settings.local.json" ]; then
  if [ -f ".claude/settings.local.json.example" ]; then
    cp .claude/settings.local.json.example .claude/settings.local.json
    info "Created .claude/settings.local.json from template"
  fi
fi

# --- Set autocompact environment variable ---
SHELL_RC=""
if [ -f "$HOME/.zshrc" ]; then
  SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
  SHELL_RC="$HOME/.bashrc"
fi

if [ -n "$SHELL_RC" ]; then
  if ! grep -q "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE" "$SHELL_RC" 2>/dev/null; then
    echo '' >> "$SHELL_RC"
    echo '# Claude Code auto-compact threshold (extends usable context)' >> "$SHELL_RC"
    echo 'export CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=90' >> "$SHELL_RC"
    info "Added CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=90 to $SHELL_RC"
  else
    info "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE already set in $SHELL_RC"
  fi
fi

# --- Summary ---
echo ""
info "Setup complete! Here's what was configured:"
echo ""
echo "  .claude/rules/        → Tier 1: Always-loaded coding rules"
echo "  .claude/commands/      → Slash commands (/create-pr, /test)"
echo "  .claude/skills/        → Advanced skills (/review-security, /fix-issue, /refactor, /deploy-check)"
echo "  .claude/agents/        → Specialized agents (code-reviewer, ecommerce-expert, infra-reviewer)"
echo "  .claude/settings.json  → Permissions, hooks, safety guards"
echo "  docs/standards/        → Tier 2: Detailed coding standards (on-demand)"
echo "  hooks/                 → Pre/post tool-use hooks"
echo "  .github/               → Issue templates, PR template, CI workflows"
echo "  CLAUDE.md              → Main configuration hub"
echo "  REVIEW.md              → Code review guidelines"
echo "  .mcp.json              → MCP server configuration"
echo ""
info "Next steps:"
echo "  1. Run: npm install"
echo "  2. Set GITHUB_TOKEN for MCP GitHub server"
echo "  3. Set ANTHROPIC_API_KEY in GitHub repo secrets (for CI workflows)"
echo "  4. Enable branch protection on main in GitHub (Settings > Branches > Add rule)"
echo "  5. Start coding: claude"
echo ""
info "Tips:"
echo "  - Use /compact proactively to extend context"
echo "  - Use /clear between unrelated tasks"
echo "  - Available skills: /review-security, /fix-issue, /create-pr, /refactor, /test, /deploy-check"
