# dotfiles

Purpose: versioned, reproducible terminal + shell config for my machines.

Personal dotfiles.

## Contents
- ghostty/config
- Brewfile
- AGENTS.MD
- setup.sh

## Setup
- Run:
  - `~/git/dotfiles/setup.sh`
  - This will also run `brew bundle` if Homebrew is installed.

## Notes
- Powerlevel10k is the prompt; config lives in `~/.p10k.zsh` (not in repo).
- zoxide init is appended to `~/.zshrc` by `setup.sh`.
- Keep secrets out of this repo.
