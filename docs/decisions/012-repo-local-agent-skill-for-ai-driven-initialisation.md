# ADR 012: Repo-Local Agent Skill for AI-Driven Initialisation

**Date:** 2026-04-24
**Status:** Accepted

## Context

New laptop setup may be driven by an AI session rather than by manually
following README steps. The AI needs a concise, discoverable workflow for this
specific repo before external skill repos such as `Backend_AI_Tools` or
`agent-scripts` have been cloned and installed.

ADR 008 keeps normal Claude/Codex/Cursor skills out of dotfiles because those
skills have their own source repos and global install locations. That remains
the right default, but the bootstrap workflow is different: it is about
initialising this dotfiles repo itself.

## Decision

Add one repo-local Agent Skill at:

```text
.agents/skills/new-laptop-onboarding/SKILL.md
```

The skill follows the Agent Skills project-local directory convention and is
not synced into `~/.claude/skills`, `~/.codex/skills`, or any other global skill
directory. It points agents to the repo runbook and verification script:

- `docs/new-laptop-ai-onboarding.md`
- `scripts/verify-new-laptop.sh`

Normal global skills continue to live in their dedicated source repos.

## Consequences

An AI session working in this repo can discover the setup workflow without
requiring the global skills ecosystem to exist first.

The exception is intentionally narrow. Dotfiles remains free of normal global
skills, large skill assets, generated dependencies, and symlinks into external
skill repos.
