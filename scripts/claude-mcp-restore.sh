#!/usr/bin/env bash
# Restore Claude Code MCP entries that belong in ~/.claude.json without syncing that file.
set -euo pipefail

say() { printf "\n\033[1;34m==> %s\033[0m\n" "$*"; }
warn() { printf "\n\033[1;33m!! %s\033[0m\n" "$*"; }

if ! command -v claude >/dev/null 2>&1; then
  warn "Claude Code CLI not found; skipping Claude MCP restore"
  exit 0
fi

mongodb_wrapper="$HOME/.local/bin/claude-mongodb-mcp"
if [ ! -x "$mongodb_wrapper" ]; then
  warn "MongoDB MCP wrapper missing or not executable: $mongodb_wrapper"
  exit 0
fi

say "Restoring Claude MCP: mongodb"
claude mcp remove mongodb -s user >/dev/null 2>&1 || true
claude mcp add -s user mongodb -- "$mongodb_wrapper" >/dev/null

echo "claude-mcp-restore.sh done."
