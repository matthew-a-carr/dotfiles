# ADR 006: Launchd Auto-Sync with chezmoi autoCommit + autoPush

**Date:** 2026-04-22
**Status:** Accepted

## Context

chezmoi copies files; edits to `~/.zshrc` don't propagate back into source automatically. The user has to remember `chezmoi re-add`, `git commit`, `git push` — three steps that are easy to forget, especially for small edits like a new alias or a tweaked AI tool setting. Forgotten syncs lead to silent drift between machines and eventually lost edits.

Options considered:
- **Manual discipline** — simplest; relies on the user remembering. Fails in practice.
- **Shell-prompt integration** — show sync state in the prompt; still requires the user to act.
- **File-system watcher** (e.g. fswatch, launchd `WatchPaths`) — fires on any edit, but noisy; many tools rewrite files as they use them.
- **Scheduled launchd agent** with a reasonable interval — periodic rather than reactive; bounded churn.

## Decision

A `LaunchAgent` at `~/Library/LaunchAgents/com.mattcarr.chezmoi-autosync.plist` (managed by chezmoi from `home/Library/LaunchAgents/*.plist.tmpl`) runs `chezmoi re-add` every 15 minutes and on login (`RunAtLoad = true`).

In `~/.config/chezmoi/chezmoi.toml`:

```toml
[git]
autoCommit = true
autoPush = true
```

When `re-add` finds drift, it updates the source tree. chezmoi then auto-commits and auto-pushes to `origin`. End-to-end: edit live → within 15 min → commit visible on GitHub.

Stdout/stderr logged to `~/Library/Logs/chezmoi-autosync.log`.

## Consequences

- **Zero-discipline sync** for files chezmoi already tracks.
- **Brand-new files still require `chezmoi add <file>` once** — re-add only catches edits to known files. Documented in `AGENTS.md`.
- **Scaffolding files outside `home/` (Brewfiles, `install.sh`, scripts/, macos/, README.md, AGENTS.md) are NOT auto-synced** — commit them manually. `autoCommit` runs in the chezmoi source dir after chezmoi modifies source; it won't touch unrelated dirty state unless staged.
- **Commit messages are auto-generated and terse** ("Update .zshrc"). Acceptable for a personal repo; can squash before any reflection-worthy moment.
- **pre-commit hook (gitleaks) still runs** — a secret that slips in blocks auto-push. User sees the failure via the log; no force-push of secrets.
- **Codex trust list drift**: if the user trusts a new project interactively, the `[projects.*]` entry auto-commits. Accepted noise — we stripped the list from the initial seed (ADR 002 / internal decision) and don't actively curate.
- **Risk of auto-pushing in-progress edits**: mitigated by the 15-min interval (most edits are complete within that window) and by the `.chezmoiignore` / `.gitignore` filters.
