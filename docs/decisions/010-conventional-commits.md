# ADR 010: Conventional Commits Repo-Wide

**Date:** 2026-04-22
**Status:** Accepted

## Context

Commit history in this repo is a mix of manual commits (scaffolding edits, ADRs, Brewfile changes) and auto-generated messages from chezmoi's `autoCommit` (syncing tracked file changes). The auto-generated messages defaulted to patterns like `Update .zshrc` or `Add Library/LaunchAgents/...`, which:

- Don't indicate the *kind* of change (feature? fix? chore?)
- Don't group cleanly when scanning `git log`
- Conflict with any future automation that wants to parse messages (release notes, change-type filtering)

[Conventional Commits](https://www.conventionalcommits.org/) is the de-facto standard for disambiguating commit types. Already adopted by the `travel-planner` repo and widely understood by tooling.

## Decision

All commits in this repo follow Conventional Commits. Both auto-generated and manual.

For **auto-sync commits**, `~/.config/chezmoi/chezmoi.toml` sets:

```toml
[git]
commitMessageTemplate = "chore(chezmoi): auto-sync"
```

Every auto-commit produced by the launchd agent (or any `chezmoi re-add`/`chezmoi add`) uses this literal message. The same line is baked into `.chezmoi.toml.tmpl` so any new machine's `chezmoi init` inherits it.

A more detailed per-file template was attempted using chezmoi 2.70.2's `.Items` template variable, but it failed at runtime (`map has no entry for key "Items"` — variable naming differs across chezmoi versions and is not reliably documented). Since auto-sync commits are low-value for archaeology (the diff is always the source of truth), a static message is the pragmatic choice.

For **manual commits**, the convention is documented in `AGENTS.md`. Common types used: `feat`, `fix`, `chore`, `docs`, `refactor`, `revert`. Scopes are free-form (`chezmoi`, `brewfile`, `install`, `zsh`, `adr`, etc.).

## Consequences

- **Consistent `git log` surface.** `git log --oneline` is now scannable by intent.
- **Future-proofs** any tooling we might add later (changelog generation, auto-tagging, PR title lint).
- **Auto-sync commit messages lose all per-file detail** — every auto-commit reads `chore(chezmoi): auto-sync`. The *diff* is the source of truth, not the subject line. Acceptable for a personal dotfiles repo; noisy for one collaborating multiple humans.
- **Discipline required on manual commits.** The pre-commit hook does NOT lint commit messages; this is a convention, not enforcement. If it drifts we can add commitlint later.
- **Existing history is unchanged.** We don't rewrite; only commits from this point onward follow the format.
