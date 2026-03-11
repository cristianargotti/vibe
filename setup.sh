#!/usr/bin/env bash
# Vibe Setup — now a Claude Code plugin
# Legacy setup.sh redirects to plugin installation

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo -e "${GREEN}Vibe${NC} is now a Claude Code plugin."
echo ""
echo "Install with Claude Code:"
echo ""
echo -e "  ${YELLOW}/plugin marketplace add dafiti-group/vibe${NC}"
echo -e "  ${YELLOW}/plugin install vibe${NC}"
echo -e "  ${YELLOW}/vibe:setup${NC}"
echo ""
echo "The interactive wizard will configure your project with:"
echo "  - Tech stack detection and CLAUDE.md generation"
echo "  - Security level selection (Basic / Standard / Strict)"
echo "  - MCP server integrations"
echo "  - GitHub Actions workflows"
echo "  - Skills and hooks"
echo ""
echo "For manual setup, see README.md."
