# ADR 001: chezmoi for Dotfiles Management

**Date:** 2026-04-22
**Status:** Accepted

## Context

Migrating from a legacy symlink-based `setup.sh` approach to a maintainable dotfiles system that reproduces a full macOS dev environment on a new laptop and keeps two machines (work + personal) in sync. Requirements: idempotent, secret-safe, templated per-machine where needed, and discoverable enough that Claude Code / Codex agents can reason about it.

Options considered:
- **Keep symlink + setup.sh** — simple but no templating, no secret injection, manual to extend.
- **[chezmoi](https://www.chezmoi.io)** — templating, built-in 1Password integration, `private_` / `executable_` file-prefix conventions, auto-commit + auto-push, non-destructive apply with diff preview.
- **YADM** — bare git in home dir; minimal templating.
- **GNU Stow** — symlink package-manager; no templating or secrets.

## Decision

Adopt chezmoi. Source tree lives at `~/git/dotfiles/home/` with standard `dot_*`, `private_*`, `executable_*`, `*.tmpl` prefixes. `chezmoi apply` writes to `~`; `chezmoi re-add` pulls live edits back into source.

Repo layout keeps scaffolding (Brewfiles, `install.sh`, `scripts/`, `macos/`) outside `home/` so those files are managed directly in git and never applied to `~`.

## Consequences

- **Simpler than Stow**, **more structured than bare git**: templating + prefix conventions solve per-machine variance and permission preservation out of the box.
- **chezmoi copies rather than symlinking** — edits to `~/.zshrc` don't auto-propagate to source. Mitigated by ADR 006 (launchd auto-sync).
- **One-way model per operation** (`apply` source→live, `re-add` live→source) forces explicit thinking about which direction a change is flowing.
- **Tool dependency**: chezmoi must be installed before any apply. Handled by Brewfile.common + install.sh.
