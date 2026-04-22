# ADR 003: Employer-Agnostic Dotfiles Scope

**Date:** 2026-04-22
**Status:** Accepted

## Context

Beyond tool config, a "new laptop day one" needs also:

- A list of work repos to `gh repo clone` (reward, keycloak, onehub-infrastructure, etc.)
- AI-tool skills linked from project repos (Claude/Codex/Cursor skills live in `Backend_AI_Tools` and `agent-scripts`)
- Company-specific setup scripts (skill linking, internal CLI tools)

Candidates for where this lives:
- **Inside this dotfiles repo** — one-command bootstrap; mixes employer-specific lists with personal tool config.
- **Separate company-specific repo** (e.g. `onehub-dev-setup` or extending `Backend_AI_Tools`) — clean split; requires two clones on day one.

## Decision

**Company-specific setup is out of scope for this repo.** Dotfiles stays employer-agnostic so it outlasts any job. A separate repo (to be created when needed — e.g. `onehub-dev-setup`) owns:

- `repos.txt` / `bootstrap.sh` that clones the Benefex repo set
- Skill-linking into `~/.claude/skills/`, `~/.codex/skills/`, `~/.cursor/rules/`
- Any other company-specific onboarding

When switching jobs, throw away the company-setup repo and keep dotfiles. Dotfiles has no reference to Benefex repo names, GCP projects, or internal tooling.

Note: `.zshrc` DOES contain `alias reward='cd ~/git/reward'`-style shortcuts. These stay in the common config (see ADR 002) — the aliases themselves don't leak employer IP and `cd`-ing to a missing dir is a no-op.

## Consequences

- **Dotfiles is portable** across any future employer with zero surgery.
- **New-machine day one is two clones**, not one: `dotfiles` + `<company>-dev-setup`. Acceptable friction.
- **The `--company-setup <url>` flag** considered for `install.sh` was rejected — adds coupling between dotfiles and a specific company-setup URL format, scope creep.
- **Documentation**: `README.md` explicitly calls out what's NOT in this repo and why, so future-self (or readers) don't expect to find it here.
