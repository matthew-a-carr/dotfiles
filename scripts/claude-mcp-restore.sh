#!/usr/bin/env bash
# Restore Claude Code MCP entries that belong in ~/.claude.json without syncing that file.
set -euo pipefail

say() { printf "\n\033[1;34m==> %s\033[0m\n" "$*"; }
warn() { printf "\n\033[1;33m!! %s\033[0m\n" "$*"; }

if ! command -v claude >/dev/null 2>&1; then
  warn "Claude Code CLI not found; skipping Claude MCP restore"
  exit 0
fi

# MongoDB MCP is disabled by default. The wrapper still lives at
# ~/.local/bin/claude-mongodb-mcp; to enable it for a session run:
#   claude mcp add -s user mongodb -- "$HOME/.local/bin/claude-mongodb-mcp"

echo "claude-mcp-restore.sh done."
