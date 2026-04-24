# ADR 011: Restore Claude MCP with Bootstrap Scripts

**Date:** 2026-04-24
**Status:** Accepted

## Context

Claude Code stores user-scoped MCP configuration in `~/.claude.json`.
That file also contains caches, user state, project history, plugin state, and
other machine-local data. Syncing it through dotfiles would risk leaking
sensitive state and would make migrations brittle.

The repo previously managed `~/.claude/.mcp.json`, but Claude Code's current
CLI does not use that file as the user-scoped MCP source of truth.

## Decision

Do not manage `~/.claude.json` directly. Store durable MCP setup as scripts:

- Managed wrapper scripts live under `home/dot_local/bin/`.
- `scripts/claude-mcp-restore.sh` recreates user-scoped MCP entries with the
  supported `claude mcp` CLI.
- `scripts/bootstrap.sh` runs the restore script after `chezmoi apply`.
- Secrets stay out of Claude config. Wrapper scripts read required secrets from
  environment variables or 1Password at runtime.

The MongoDB MCP entry is restored as a user-scoped Claude MCP named `mongodb`
that runs `~/.local/bin/claude-mongodb-mcp`.

## Consequences

New laptops can recreate Claude MCP configuration without copying
`~/.claude.json`. The same restore script can be rerun idempotently after Claude
upgrades or config drift.

This adds one more bootstrap step and means MCP configuration changes must be
made in the restore script or wrapper, not by manually editing `~/.claude.json`.
The MongoDB MCP still depends on Docker, Claude Code, and 1Password access to
the configured Mongo secret unless `MONGODB_URI` is provided separately.
