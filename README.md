# dotfiles

Reproducible macOS dev environment, managed with [chezmoi](https://www.chezmoi.io/).
Secrets live in 1Password and are pulled in at apply time. IDE settings sync via vendor accounts (JetBrains, VSCode). Employer-agnostic — anything Benefex-specific (repo clones, work skills) lives in a separate repo.

## Layout

```
.
├── install.sh                end-to-end bootstrap (accepts --role work|personal)
├── Brewfile.common           universal packages
├── Brewfile.work             Benefex-specific (dotnet, k8s, docker, gcloud, …)
├── Brewfile.personal         personal-only extras
├── .chezmoi.toml.tmpl        prompts once for role + git identity
├── .chezmoiroot              points chezmoi at home/
├── home/                     chezmoi source tree
│   ├── .chezmoiignore        backstop (node_modules, .DS_Store, sqlite)
│   └── dot_*                 everything that lands in ~
├── scripts/
│   ├── bootstrap.sh            oh-my-zsh, amix/vimrc, SDKMAN, NVM, iTerm pointer, Claude MCP, pre-commit hook
│   ├── claude-mcp-restore.sh   restore user-scoped Claude MCP entries
│   └── verify-new-laptop.sh    post-install acceptance test
├── macos/defaults.sh         `defaults write` tweaks
├── .gitignore                secret-file backstop
└── .gitleaks.toml            pre-commit secret scanner rules
```

## New machine — fresh install

If an AI session is driving the setup, start with
[`docs/new-laptop-ai-onboarding.md`](docs/new-laptop-ai-onboarding.md). It gives
the session the install runbook and points it at the post-install verifier.
This repo also includes a project-local Agent Skill at
`.agents/skills/new-laptop-onboarding/SKILL.md`.

```bash
# One-time OS setup
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Clone via HTTPS (no SSH key yet, no gh required)
mkdir -p ~/git
git clone https://github.com/matthew-a-carr/dotfiles ~/git/dotfiles

# Bootstrap
~/git/dotfiles/install.sh --role work      # or --role personal
```

`install.sh` does:

1. Homebrew → `brew bundle Brewfile.common` + `Brewfile.<role>`
2. Waits for `op signin` (retry loop, no hard-exit)
3. `chezmoi init --apply` — renders `home/` → `~`. Prompts once for git identity.
4. `scripts/bootstrap.sh` — oh-my-zsh, amix/vimrc, SDKMAN, NVM + default Node LTS, iTerm2 custom-prefs pointer, Claude MCP restore, pre-commit gitleaks hook
5. `macos/defaults.sh` — system preferences

Manual follow-ups after install:

- Enable the 1Password SSH agent in the 1Password app, then re-run `~/git/dotfiles/scripts/bootstrap.sh` if auto-sync was skipped.
- Run `gh auth login`.
- Sign in to Claude Code, Codex, Gemini, Antigravity, Cursor, and GitHub Copilot.

## Migrating an already-configured machine

Your existing personal or work laptop can be brought onto this system non-destructively. Nothing gets written until you explicitly apply.

```bash
brew install chezmoi 1password-cli gitleaks
mkdir -p ~/git
git clone https://github.com/matthew-a-carr/dotfiles ~/git/dotfiles

# chezmoi init prompts once: role, git name, git email, signingkey.
# Writes ~/.config/chezmoi/chezmoi.toml. Does NOT touch any dotfiles.
chezmoi init --source ~/git/dotfiles

# Inspect every change before anything is written.
chezmoi diff
```

Then decide per file:

```bash
# Keep your live version → pull it back into the repo
chezmoi re-add ~/.zshrc

# Accept the repo's version → overwrite live file
chezmoi apply ~/.gitconfig

# Skip a file → don't touch it for now
```

Brewfiles are additive by default — nothing existing gets removed:

```bash
brew bundle --file Brewfile.common
brew bundle --file Brewfile.personal   # or Brewfile.work

# Only if you WANT to prune packages not listed:
~/git/dotfiles/install.sh --role personal --prune
```

## Keeping apps in sync

Brewfiles are maintained intentionally, not auto-dumped from the machine:

- Put packages used on every machine in `Brewfile.common`.
- Put Benefex-only packages in `Brewfile.work`.
- Put personal-only packages in `Brewfile.personal`.
- After adding entries, run `brew bundle check --file Brewfile.common` and the role file.
- Use `brew bundle dump --file /tmp/Brewfile --describe` only as a discovery aid, then copy the entries you actually want.

## Day-to-day workflow

chezmoi copies files (not symlinks). Edit live, pull the change into source, commit.

```bash
# Edit source and apply in one step
chezmoi edit --apply ~/.zshrc

# Catch up with edits you made outside chezmoi
chezmoi diff                # preview
chezmoi re-add ~/.zshrc     # pull single file back into source
chezmoi re-add              # …or whole tree

# Push to other machines
(cd $(chezmoi source-path)/.. && git add -A && git commit && git push)

# On the other machine
chezmoi update              # = git pull + chezmoi apply
```

Aliases in `.zshrc`: `cm`, `cmd` (diff), `cma` (apply), `cmr` (re-add), `cme` (edit --apply).

## Secrets

Nothing sensitive enters the repo. Defences:

1. `.gitignore` + `home/.chezmoiignore` block known filenames
2. `.gitleaks.toml` + pre-commit hook refuses commits containing tokens
3. chezmoi `private_*` prefix applies 0600 permissions
4. Templated files pull secrets at apply time (never stored in source)

1Password items the repo references (create once, forget):

| Reference | Used by |
|---|---|
| `op://Employee/Mongo Dev/notesPlain` | zsh helpers `load-mongo-dev` / `claude-mongo-dev`, Claude MongoDB MCP wrapper |
| `op://Employee/Mongo Prod/notesPlain` | zsh helpers |
| `op://Employee/id_ed25519` | 1Password SSH agent (auth + signing — never read by any script) |

SSH + git commit signing go through the 1Password SSH agent — no keys on disk, no GPG stack. See [ADR 013](docs/decisions/013-1password-ssh-agent-sole-mechanism.md) and [ADR 009](docs/decisions/009-ssh-signed-commits-via-1password.md).

## What's managed here vs elsewhere

| Managed here | Managed elsewhere |
|---|---|
| Shell (`.zshrc`, `.zprofile`, `.zshenv`, `.p10k.zsh`) | oh-my-zsh + amix/vimrc → cloned by `bootstrap.sh` |
| Git (`.gitconfig` with templated identity, `.gitmessage`, `.git-coauthors`) | — |
| Vim (`.vimrc`) | `.vim_runtime` → amix/vimrc repo, cloned by bootstrap |
| Ghostty, iTerm2 prefs | — |
| Claude Code, Codex, Gemini, Cursor, Copilot, Antigravity **settings only**; Claude MCP restore scripts; repo-local bootstrap skill | Normal global skills/rules/plugins → Backend_AI_Tools / agent-scripts (separate repo) |
| SSH `config`, `known_hosts`, `id_ed25519.pub` | Private key → 1Password |
| Brewfiles, VSCode extension list | VSCode settings/keybindings → Settings Sync (GitHub) |
| — | IntelliJ settings → JetBrains Settings Sync |
| macOS `defaults write` tweaks | Full system config → Apple Migration Assistant |

## What's NOT in this repo (intentional)

- **Work repo clones.** The list of Benefex repos to `gh repo clone` on day one belongs in a company-specific setup repo — dotfiles outlasts any employer.
- **Normal global AI-tool skills.** Claude/Codex/Cursor skills link to content in `Backend_AI_Tools` / `agent-scripts`. Clone those; their own bootstrap links the skills back into `~/.claude/skills/` etc. The only dotfiles-owned exception is the repo-local bootstrap `new-laptop-onboarding` skill.
- **IntelliJ + VSCode user settings.** Use vendor sync. Keeping them in a repo fights the built-in sync and leaks licenses.

## Verification

```bash
chezmoi doctor                                     # tool health
chezmoi diff                                        # empty after apply
gitleaks detect --source . --config .gitleaks.toml  # zero findings
brew bundle check --file Brewfile.common
brew bundle check --file Brewfile.$(chezmoi data | jq -r .role)
git lfs version                                     # LFS filters available
nvm use default                                     # Node default alias works
test -x ~/.local/bin/claude-mongodb-mcp             # Mongo MCP wrapper present (injected per-session by claude-mongo-dev/prod)
ssh -T git@github.com                               # key works
git -C . log -1 --show-signature                    # commit signature verifies
```

Secret-leak sanity check (must return nothing):

```bash
git grep -Ei 'authtoken|_token=|-----BEGIN (OPENSSH|PGP|RSA)'
```
