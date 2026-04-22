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
commitMessageTemplate = """
{{- if eq (len .Items) 1 -}}
chore(chezmoi): update {{ (index .Items 0).TargetRelPath }}
{{- else -}}
chore(chezmoi): sync {{ len .Items }} files

{{ range .Items }}- {{ .TargetRelPath }}
{{ end -}}
{{- end -}}
"""
```

Produces messages like:
- Single file: `chore(chezmoi): update dot_zshrc.tmpl`
- Multiple files: `chore(chezmoi): sync 3 files` + bullet list in body

The same template is baked into `.chezmoi.toml.tmpl` so any new machine's `chezmoi init` inherits it.

For **manual commits**, the convention is documented in `AGENTS.md`. Common types used: `feat`, `fix`, `chore`, `docs`, `refactor`, `revert`. Scopes are free-form (`chezmoi`, `brewfile`, `install`, `zsh`, `adr`, etc.).

## Consequences

- **Consistent `git log` surface.** `git log --oneline` is now scannable by intent.
- **Future-proofs** any tooling we might add later (changelog generation, auto-tagging, PR title lint).
- **Auto-sync commit messages lose some per-file detail** for multi-file runs — acceptable trade since the body contains the file list.
- **Discipline required on manual commits.** The pre-commit hook does NOT lint commit messages; this is a convention, not enforcement. If it drifts we can add commitlint later.
- **Existing history is unchanged.** We don't rewrite; only commits from this point onward follow the format.
