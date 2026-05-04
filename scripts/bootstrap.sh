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
# chezmoi creates ~/.vim_runtime/ to hold my_configs.vim, so checking for the
# directory's existence isn't enough — we test for a file that only exists
# after the upstream amix/vimrc has been cloned in.
if [ ! -f "$HOME/.vim_runtime/install_awesome_vimrc.sh" ]; then
  say "Installing amix/vimrc"
  tmpdir="$(mktemp -d)"
  git clone --depth 1 https://github.com/amix/vimrc.git "$tmpdir/vimrc"
  # Copy upstream contents into ~/.vim_runtime without clobbering the
  # chezmoi-managed my_configs.vim that's already there.
  mkdir -p "$HOME/.vim_runtime"
  cp -R "$tmpdir/vimrc/." "$HOME/.vim_runtime/"
  rm -rf "$tmpdir"
  # Deliberately not running install_awesome_vimrc.sh: ~/.vimrc is managed by
  # chezmoi (see home/dot_vimrc) and already contains the right source lines.
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

# ---- Docker CLI plugins (compose + buildx) ----
# Homebrew installs docker-compose and docker-buildx as standalone binaries.
# They need to be symlinked into ~/.docker/cli-plugins/ for `docker compose`
# and `docker buildx` to work as subcommands of the docker CLI. Per the
# brew formulae's caveats: https://formulae.brew.sh/formula/docker-compose
brew_prefix="$(/opt/homebrew/bin/brew --prefix 2>/dev/null || true)"
if [ -n "$brew_prefix" ]; then
  mkdir -p "$HOME/.docker/cli-plugins"
  for plugin in docker-compose docker-buildx; do
    target="$brew_prefix/opt/$plugin/bin/$plugin"
    link="$HOME/.docker/cli-plugins/$plugin"
    if [ -x "$target" ] && [ ! -L "$link" ]; then
      say "Linking $plugin into ~/.docker/cli-plugins"
      ln -sfn "$target" "$link"
    fi
  done
fi

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
# Re-write the hook every run so older versions get the brew-shellenv shim.
hook="$repo_dir/.git/hooks/pre-commit"
say "Installing gitleaks pre-commit hook"
cat > "$hook" <<'HOOK'
#!/usr/bin/env bash
# Block commits that contain secrets.
# Source brew shellenv so PATH includes /opt/homebrew/bin even when git is
# invoked from a non-interactive shell that hasn't sourced ~/.zshrc.
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
exec gitleaks protect --staged --redact --config .gitleaks.toml
HOOK
chmod +x "$hook"

echo "bootstrap.sh done."
