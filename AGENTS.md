# AGENTS.md — guidance for coding agents working in this repo

> Claude Code reads `CLAUDE.md`, which is a symlink to this file. One source of truth.

## What this repo is

Personal dotfiles managed by [chezmoi](https://www.chezmoi.io/). Works across two machines (work + personal) with a `role` prompt at `chezmoi init` selecting which Brewfile applies. Employer-agnostic — anything Benefex-specific (repo clones, work-only skills) lives in a separate repo.

Never commit secrets. Use 1Password references (`op://...`) or chezmoi `.tmpl` files with `{{ onepasswordRead }}`.

## Layout you need to know

```
~/git/dotfiles/
├── Brewfile.common          universal packages
├── Brewfile.work            Benefex-specific (dotnet, k8s, gcloud, …)
├── Brewfile.personal        personal-only
├── install.sh               one-command bootstrap
├── .chezmoi.toml.tmpl       prompts for role + git identity at chezmoi init
├── home/                    chezmoi SOURCE tree (what becomes ~ via `chezmoi apply`)
│   ├── .chezmoiignore       backstop (node_modules, .DS_Store, sqlite)
│   ├── dot_zshrc.tmpl       → ~/.zshrc
│   ├── dot_claude/…         → ~/.claude/…
│   ├── private_dot_ssh/…    → ~/.ssh/… (dir mode 700)
│   └── …
├── scripts/                 bootstrap.sh, ssh-restore.sh, gpg-import.sh
└── macos/defaults.sh        system tweaks
```

Files outside `home/` (Brewfiles, scripts, install.sh) are repo scaffolding — **not** synced to `~`. Files inside `home/` ARE synced.

## chezmoi naming conventions

| Prefix | Meaning |
|---|---|
| `dot_<name>` | Applies to `~/.<name>` |
| `private_dot_<name>` | As above + forces 0600/0700 permissions |
| `private_<name>` | As above for files/dirs already inside a `dot_*` parent |
| `<name>.tmpl` | Processed as Go template at apply time (can use `{{ .git.* }}`, `{{ .chezmoi.homeDir }}`, `{{ onepasswordRead }}`, etc.) |
| `executable_<name>` | Ensures 0755 executable bit survives |

## How sync works (critical mental model)

chezmoi **copies** files, it does not symlink. Source tree (`home/`) and live files (`~/`) are two separate states. The flow is one-directional per operation:

```
  chezmoi apply       home/  →  ~/     (write live)
  chezmoi re-add      ~/     →  home/  (capture live back into source)
  chezmoi diff                          (preview apply)
  chezmoi edit --apply <file>           (edit source, apply in one step)
```

**This machine has auto-sync enabled.** A launchd agent runs `chezmoi re-add` every 15 min, and chezmoi's `autoCommit = true` + `autoPush = true` in `~/.config/chezmoi/chezmoi.toml` commits and pushes each change. You don't need to remember to sync.

### When you edit a managed file

If you modify anything under `~` that chezmoi tracks (e.g. `~/.zshrc`, `~/.claude/settings.json`), do nothing special. Within 15 minutes, auto-sync captures it into `home/dot_zshrc.tmpl` (etc.) and pushes to GitHub.

Manual trigger on demand: `csync` (alias defined in `.zshrc`) = `chezmoi re-add`.

### When you edit repo scaffolding directly

Files outside `home/` (Brewfiles, `install.sh`, `macos/defaults.sh`, `scripts/*`, `README.md`, `AGENTS.md`) are **not** auto-synced. Commit them yourself:

```
cd ~/git/dotfiles
git add <files>
git commit -m "…"
git push
```

### When you add a brand-new tracked file

`chezmoi re-add` only catches changes to files already in source. To start tracking a new file, run `chezmoi add ~/.new-thing` once — this copies it into the source tree with the right prefix. After that, auto-sync picks up future edits.

### When you pull from the other machine

```
chezmoi update     # = git pull in source repo + chezmoi apply
```

## Role-gated content

Only two places use `{{ .role }}` / `{{ .git.* }}`:

1. **Brewfile split** — `install.sh` runs `Brewfile.common + Brewfile.<role>`
2. **`home/dot_gitconfig.tmpl`** — name/email/signingkey come from `{{ .git.* }}` set at init time

Everything else is common. Benefex-named aliases in `.zshrc` (e.g. `alias reward='cd ~/git/reward'`) stay on both machines — harmless `cd` to missing dirs on personal. Don't sprinkle `{{ if eq .role "work" }}` blocks unless there's a genuine functional conflict.

## Things to NEVER do

- Commit secrets. `.gitleaks.toml` + pre-commit hook will reject them, but don't test it.
- Put Benefex repo lists in this repo — that's a separate company-setup repo concern.
- Hard-code absolute paths like `/Users/mattcarr@hellobenefex.com/...` — use `{{ .chezmoi.homeDir }}` instead.
- Commit `.codex/auth.json`, `.gemini/oauth_creds.json`, `.claude.json`, `~/.npmrc` (has `_authToken`), `~/.ssh/id_*` (private keys). All are in `.gitignore`.
- Manage Claude/Codex/Cursor **skills** in this repo. They live in `Backend_AI_Tools` / `agent-scripts` and link into `~/.claude/skills/` etc.
- Commit IntelliJ / VSCode settings folders. Use vendor Settings Sync instead.

## Secrets that ARE wired up

1Password references the repo expects (items must exist in `Employee` vault):

| Reference | Used by |
|---|---|
| `op://Employee/Mongo Dev/notesPlain` | zsh helpers `load-mongo-dev`, `claude-mongo-dev` |
| `op://Employee/Mongo Prod/notesPlain` | zsh helpers |
| `op://Employee/SSH id_ed25519/private key` | `scripts/ssh-restore.sh` |
| `Employee` vault document `GPG Secret Key` | `scripts/gpg-import.sh` |

## Before committing manually

Pre-commit hook runs `gitleaks protect --staged --config .gitleaks.toml`. If it fails, investigate — don't `--no-verify`.

## If auto-sync seems stuck

```
tail -20 ~/Library/Logs/chezmoi-autosync.log
launchctl list | grep chezmoi
launchctl kickstart -k gui/$(id -u)/com.mattcarr.chezmoi-autosync
```
