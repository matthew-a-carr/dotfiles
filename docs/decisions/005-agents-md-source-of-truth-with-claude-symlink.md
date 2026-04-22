# ADR 005: AGENTS.md Source of Truth with CLAUDE.md Symlink

**Date:** 2026-04-22
**Status:** Accepted

## Context

Multiple coding agents need guidance on this repo — Claude Code reads `CLAUDE.md`, Codex reads `AGENTS.md`, and other tools may look at additional files. Maintaining parallel documents guarantees drift: a change to one gets missed in the other, and agents get contradictory guidance.

## Decision

`AGENTS.md` is the canonical source. `CLAUDE.md` is a repository-level symlink to it. macOS + git both handle symlinks correctly; git tracks it as a symlink blob referencing `AGENTS.md`.

Any agent opening either file reads the same content. One source to update, zero drift.

## Consequences

- **One file to maintain.** Updates land in both tools automatically.
- **Git portability**: symlinks work on macOS and Linux. On Windows checkout, git would materialise as a copy (with `core.symlinks = false`) or a symlink (with it true) — not relevant for this single-user repo but worth noting.
- **File-renderer edge cases**: GitHub renders the symlink contents when viewing `CLAUDE.md` in the UI.
- **Agent-specific guidance** (if ever needed) goes in sections clearly marked "for Claude only" or "for Codex only" within `AGENTS.md`. Currently none.
