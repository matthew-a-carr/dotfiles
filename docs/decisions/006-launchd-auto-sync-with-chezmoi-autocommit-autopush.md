# ADR 006: Launchd Bidirectional Auto-Sync with chezmoi autoCommit + autoPush

**Date:** 2026-04-22
**Status:** Accepted

## Context

chezmoi copies files; edits to `~/.zshrc` don't propagate back into source automatically. The user has to remember `chezmoi re-add`, `git commit`, `git push` — three steps that are easy to forget. Symmetrically, on a second machine, edits pushed from the first machine don't land unless `git pull` + `chezmoi apply` runs there. Forgotten syncs in either direction cause silent drift.

Options considered:
- **Manual discipline** — fails in practice.
- **Shell-prompt integration** — still requires the user to act.
- **File-system watcher** (fswatch, launchd `WatchPaths`) — reactive but noisy; tools rewrite files all the time.
- **Scheduled launchd agent** with a reasonable interval — periodic, bounded churn, simple.

## Decision

A `LaunchAgent` at `~/Library/LaunchAgents/com.mattcarr.chezmoi-autosync.plist` (managed via `home/Library/LaunchAgents/*.plist.tmpl`) runs every 15 minutes and on login (`RunAtLoad = true`). Each run does:

```bash
chezmoi update   # git pull in source dir, then chezmoi apply → live
chezmoi re-add   # live → source; autoCommit + autoPush if drift
```

Run in that order with `&&` so re-add only runs if update succeeded.

In `~/.config/chezmoi/chezmoi.toml`:

```toml
[git]
autoCommit = true
autoPush = true
```

stdout/stderr tee'd to `~/Library/Logs/chezmoi-autosync.log` with a timestamp banner per run.

## Consequences

- **Zero-discipline bidirectional sync** for files chezmoi already tracks. Edit anywhere, it reaches the other machine within ~15 min.
- **Brand-new files still require `chezmoi add <file>` once** — re-add only catches edits to known files. Documented in `AGENTS.md`.
- **Scaffolding files outside `home/` (Brewfiles, `install.sh`, scripts/, macos/, README.md, AGENTS.md, docs/)** are NOT auto-synced on the write side — they are on the read side via `git pull` inside `chezmoi update`. Commit them manually.
- **Auto-commit messages are terse** ("Update .zshrc"). Acceptable; squash before any reflection-worthy moment.
- **Pre-commit hook (gitleaks) still runs** — a secret that slips in blocks auto-push. User sees the failure via the log; no force-push of secrets.

### Conflict handling

Bidirectional sync introduces a small conflict surface. Types:

1. **Same file edited on two machines within the 15-min window.**
   - Agent on the later machine runs `chezmoi update` → `git pull` tries to merge → fails with a standard git merge conflict (source file has `<<<<<<< HEAD` markers) → `re-add` does NOT run (the `&&` chain stops).
   - Effect: live files on both machines are unaffected (apply hadn't run for the conflicted file yet). The conflict sits in `~/git/dotfiles/` awaiting manual resolution.
   - Visible in `~/Library/Logs/chezmoi-autosync.log` as a failed merge.
   - Resolve: `cd ~/git/dotfiles && git status` → open the conflicted file, pick the right hunks, `git add`, `git commit`, `git push`. Next agent tick proceeds normally.

2. **Auto-push rejected (non-fast-forward) because remote advanced.**
   - Can only happen if `chezmoi update` passed (nothing to pull) but between that moment and the `re-add` auto-push, the other machine pushed. Very unlikely given the 15-min interval.
   - If it happens: re-add's autoCommit succeeds locally, autoPush fails, user sees failure in the log, next agent tick pulls the other machine's change and tries again — usually auto-resolves on the next run.

3. **Mid-edit capture** — user in the middle of editing `~/.zshrc` when agent fires.
   - re-add captures the half-edited state. Gets pushed. User finishes edit locally a minute later. Next agent tick captures the finished version, commits again. History is noisy but correct.

4. **Gitleaks rejection** — a secret slipped into a tracked file.
   - Pre-commit hook blocks auto-commit. Error visible in log. User must strip the secret and re-add.

### What the agent deliberately does NOT do

- **Does not `git stash` before pull.** A dirty working tree in the source dir (e.g. user in the middle of editing `install.sh` manually) causes `chezmoi update` to fail the pull. Agent leaves it alone; user resolves. We prefer surfaced failure over silent stash-drop.
- **Does not rebase on pull.** Default `git pull` is merge. Merge commits in the auto-sync history are ugly but deterministic; rebasing mid-auto-push is riskier.
- **Does not retry failed pushes.** The next scheduled tick retries the whole flow; retrying inside one agent run adds complexity without meaningful benefit.
