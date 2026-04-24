---
name: new-laptop-onboarding
description: Use when setting up or migrating a macOS laptop from this dotfiles repo, especially when an AI session is driving install, bootstrap, sign-ins, verification, or fixes for failed new-laptop checks.
---

# New Laptop Onboarding

Use this skill only for this dotfiles repo. The repo is the source of truth; do
not improvise install steps when a repo script exists.

## Workflow

1. Locate or clone the repo at `~/git/dotfiles`.
2. Read `docs/new-laptop-ai-onboarding.md` if present.
3. Run `~/git/dotfiles/install.sh --role work` unless the user explicitly says this is a personal machine.
4. Guide required sign-ins: 1Password CLI/app, 1Password SSH agent, GitHub CLI, AI tools, and work `gcloud` auth.
5. Run `~/git/dotfiles/scripts/verify-new-laptop.sh`.
6. For verification failures, distinguish auth/manual failures from deterministic repo bugs.
7. If a deterministic repo bug is found, edit the repo, validate, commit, and push.

## Rules

- Never commit secrets, auth files, app session state, cache files, or private keys.
- Do not manage `~/.claude.json`; restore Claude MCP entries through `scripts/claude-mcp-restore.sh`.
- Maintain Brewfiles intentionally. Do not dump the whole machine into the repo.
- Re-run `scripts/bootstrap.sh` after enabling the 1Password SSH agent if auto-sync was skipped.
- Use `scripts/verify-new-laptop.sh` as the acceptance test.
