# ADR 007: Vendor Sync for IDE Settings (JetBrains + VSCode)

**Date:** 2026-04-22
**Status:** Accepted

## Context

IntelliJ (via JetBrains Toolbox) and VSCode both have first-party "settings sync" features tied to a vendor account (JetBrains / GitHub). These handle keymaps, themes, installed plugins/extensions, snippets, and per-IDE preferences.

Alternative: commit `~/Library/Application Support/JetBrains/*/` and `~/Library/Application Support/Code/User/*` into this repo.

## Decision

**Use vendor sync for IDE settings.** Do not put `~/Library/Application Support/JetBrains/*` or `~/Library/Application Support/Code/User/*` into the chezmoi source tree.

What this repo DOES manage for the IDEs:

- `Brewfile` lines for installing extensions (VSCode) and the Toolbox launcher (JetBrains)
- Pinning the JetBrains Toolbox install itself so the IDE is reproducible

## Consequences

- **Zero maintenance** on IDE settings — they sync via the vendor's account infrastructure.
- **Avoids fighting vendor sync**: if we committed those folders, every IDE upgrade that bumps folder structure would create spurious diffs.
- **License files stay out of the repo**: `~/Library/Application Support/JetBrains/*/idea.key` and `plugin_*.license` would be accidentally captured if we synced that tree. `.gitignore` would help but vendor sync avoids the problem entirely.
- **New-machine bootstrap**: sign into JetBrains Toolbox + VSCode once; Settings Sync pulls everything. One extra login per IDE.
- **Extensions still pinned in Brewfile** — if vendor sync doesn't restore an extension for any reason, `brew bundle` does.
- **Tradeoff**: we trust JetBrains and GitHub's sync services to not lose settings. Acceptable for a personal setup; if either service fails, re-enabling takes minutes.
