# ADR 002: Single Repo with Work/Personal Role Prompt

**Date:** 2026-04-22
**Status:** Accepted

## Context

Work and personal laptops share most configuration (shell, editor, AI tools, terminal, macOS tweaks) but diverge meaningfully on a small number of points:

- **Brewfile** — personal shouldn't install dotnet, circleci, datadog, gcloud, k8s tooling, Microsoft apps, cloudflare-warp.
- **Git identity** — different email (work noreply vs personal) and different SSH signing key.

Options considered:
- **Two separate repos** (`dotfiles-work`, `dotfiles-personal`) — total isolation but doubled maintenance; improvements on one side drift from the other.
- **Branch-per-machine** — permanent rebase pain.
- **Base repo + private overlay** — clean split but two sync loops.
- **Single repo with chezmoi `{{ if eq .role "work" }}` conditionals** sprinkled inline — ugly when overused.
- **Single repo with a role prompt gating only the files that truly diverge** — minimal template complexity.

## Decision

Single repo. `chezmoi init` prompts once (via `.chezmoi.toml.tmpl`) for:

- `role` — `work` or `personal` (choice)
- `git.name`, `git.email`, `git.signingkey` — written once, drive `dot_gitconfig.tmpl`

Only two places use `{{ .role }}`:

1. `install.sh` runs `Brewfile.common` + `Brewfile.<role>`. Three plain Brewfiles (`Brewfile.common`, `Brewfile.work`, `Brewfile.personal`) at repo root.
2. `dot_gitconfig.tmpl` consumes `{{ .git.* }}`.

Benefex-named aliases (`reward`, `keycloak`, `infra`, `trs`, etc.) in `.zshrc` stay on **both** machines. They `cd` to paths that may not exist on personal — harmless when unused, no shell-init error.

## Consequences

- **One git push benefits both machines.** No drift between work and personal base.
- **Role prompt is a one-time question at `chezmoi init`**, stored in `~/.config/chezmoi/chezmoi.toml`. Never asked again.
- **Minimal template conditionals** — almost everything is common; only `.gitconfig` uses `{{ .git.* }}`.
- **Brewfile split is coarse** — a package that becomes useful on personal later needs to be moved from `Brewfile.work` to `Brewfile.common`. Acceptable given the low frequency.
- **Risk**: a config that SHOULD be role-gated but isn't (e.g. `GOOGLE_CLOUD_PROJECT` env export) leaks across. Mitigation: only export environment values that are cheap-if-ignored; don't export credentials.
