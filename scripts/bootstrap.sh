#!/usr/bin/env bash
# Post-chezmoi bootstrap: install tools that live outside Homebrew and must be cloned/curled.
set -euo pipefail

say() { printf "\n\033[1;34m==> %s\033[0m\n" "$*"; }
repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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
if [ -s "$HOME/.nvm/nvm.sh" ] && [ ! -f "$HOME/.nvm/alias/default" ]; then
  say "Installing default Node.js LTS"
  # shellcheck disable=SC1091
  . "$HOME/.nvm/nvm.sh"
  nvm install --lts >/dev/null
  nvm alias default 'lts/*' >/dev/null
fi

# ---- MesloLGS NF fonts (p10k-distributed; match the PostScript name iTerm prefs reference) ----
# Brewfile installs the Nerd Font cask for general use, but the .ttfs there
# carry different PostScript names. iTerm's profile expects exactly
# "MesloLGS-NF-Regular", which is what the powerlevel10k-media repo ships.
fonts_dir="$HOME/Library/Fonts"
mkdir -p "$fonts_dir"
for variant in Regular Bold Italic "Bold Italic"; do
  fname="MesloLGS NF $variant.ttf"
  if [ ! -f "$fonts_dir/$fname" ]; then
    say "Downloading $fname"
    curl -sSLfo "$fonts_dir/$fname" \
      "https://github.com/romkatv/powerlevel10k-media/raw/master/${fname// /%20}"
  fi
done

# ---- iTerm2: load prefs from dotfiles folder ----
say "Pointing iTerm2 at ~/.config/iterm2"
defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$HOME/.config/iterm2"
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
defaults write com.googlecode.iterm2 NoSyncNeverRemindPrefsChangesLostForFile -bool true

# ---- launchd auto-sync agent ----
agent_label="com.mattcarr.chezmoi-autosync"
agent_plist="$HOME/Library/LaunchAgents/$agent_label.plist"
if [ -f "$agent_plist" ]; then
  ssh_agent_sock="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
  if [ -S "$ssh_agent_sock" ]; then
    mkdir -p "$HOME/Library/Logs"
    # Unload first (idempotent reload) then load. bootstrap errors if already loaded.
    launchctl bootout "gui/$(id -u)/$agent_label" 2>/dev/null || true
    launchctl bootstrap "gui/$(id -u)" "$agent_plist"
    say "Loaded launchd agent: $agent_label (runs chezmoi re-add every 15 min)"
  else
    say "Skipping launchd agent: enable the 1Password SSH agent, then re-run bootstrap.sh"
  fi
fi

# ---- Claude MCP servers ----
if [ -x "$repo_dir/scripts/claude-mcp-restore.sh" ]; then
  "$repo_dir/scripts/claude-mcp-restore.sh"
fi

# ---- gitleaks pre-commit hook (for this repo) ----
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
