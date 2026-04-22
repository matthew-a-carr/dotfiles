#!/usr/bin/env bash
# Post-chezmoi bootstrap: install tools that live outside Homebrew and must be cloned/curled.
set -euo pipefail

say() { printf "\n\033[1;34m==> %s\033[0m\n" "$*"; }

# ---- oh-my-zsh ----
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  say "Installing oh-my-zsh"
  RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# ---- amix/vimrc ----
if [ ! -d "$HOME/.vim_runtime" ]; then
  say "Installing amix/vimrc"
  git clone --depth 1 https://github.com/amix/vimrc.git "$HOME/.vim_runtime"
  sh "$HOME/.vim_runtime/install_awesome_vimrc.sh"
fi

# ---- SDKMAN ----
if [ ! -d "$HOME/.sdkman" ]; then
  say "Installing SDKMAN"
  curl -s "https://get.sdkman.io?rcupdate=false" | bash
fi

# ---- NVM ----
if [ ! -d "$HOME/.nvm" ]; then
  say "Installing NVM"
  PROFILE=/dev/null bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash'
fi

# ---- iTerm2: load prefs from dotfiles folder ----
say "Pointing iTerm2 at ~/.config/iterm2"
defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$HOME/.config/iterm2"
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
defaults write com.googlecode.iterm2 NoSyncNeverRemindPrefsChangesLostForFile -bool true

# ---- gitleaks pre-commit hook (for this repo) ----
repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
hook="$repo_dir/.git/hooks/pre-commit"
if [ ! -f "$hook" ]; then
  say "Installing gitleaks pre-commit hook"
  cat > "$hook" <<'HOOK'
#!/usr/bin/env bash
# Block commits that contain secrets.
exec gitleaks protect --staged --redact --config .gitleaks.toml
HOOK
  chmod +x "$hook"
fi

echo "bootstrap.sh done."
