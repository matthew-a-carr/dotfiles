# ADR 008: AI Tool Skills Managed in Source Repos, Not Dotfiles

**Date:** 2026-04-22
**Status:** Accepted

## Context

Claude Code, Codex, and Cursor all support "skills" (or "rules") — reusable prompts and scripts that extend agent behaviour for specific workflows. On the current work laptop, `~/.claude/skills/`, `~/.codex/skills/`, and `~/.cursor/rules/` all contain skill directories.

Observations when we tried to capture these into the dotfiles repo:

- `~/.claude/skills/` entries are **symlinks** into project repos (`~/git/Backend_AI_Tools/skills/*` and `~/git/agent-scripts/skills/*`). Committing the symlinks to dotfiles produces broken links on the new machine until those repos are cloned.
- `~/.codex/skills/` contains **real content** — 30 MB, including `node_modules/` symlinks inside skills like `brave-search`, plus executable scripts whose `+x` bits need preserving via `executable_` prefixes. Noisy.
- Skills are actively developed — committing a snapshot into dotfiles instantly diverges from the authoritative version in the source repo.

## Decision

**Skills are generally NOT managed in dotfiles.** They live in their authoritative source repos (`Backend_AI_Tools`, `agent-scripts`) and get linked/copied into `~/.claude/skills/`, `~/.codex/skills/`, `~/.cursor/rules/` by a company-specific setup repo (ADR 003) after those source repos are cloned.

One exception is allowed by
[ADR 012](012-repo-local-agent-skill-for-ai-driven-initialisation.md): a small
repo-local `.agents/skills/new-laptop-onboarding` skill may live in this repo
because it documents how to bootstrap this repo itself before the external
skill repos are available. It is not synced into global `~/.claude/skills` or
`~/.codex/skills`.

`home/.chezmoiignore` + `.gitignore` keep large or external skill directories
out of chezmoi's view.

## Consequences

- **Source of truth stays in one place** for normal skills — the skill's own repo.
- **Dotfiles bootstrap is fast and clean** — no 30 MB of `node_modules` symlinks, no `executable_` rename scaffolding.
- **Day-one on a new machine**: normal skills are unavailable until the relevant repos are cloned. The repo-local bootstrap skill is available from dotfiles so an AI session can drive setup while working in this repo.
- **Users need to know** skills aren't in here. Documented in `AGENTS.md` (never-dos list) and `README.md` (what's NOT in this repo).
- **Risk of skill loss** if a user forgets to clone the source repos. Mitigated by the company-setup repo (ADR 003) handling the clone + link step.
