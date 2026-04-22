#!/usr/bin/env bash
# End-to-end bootstrap for a macOS machine.
# Idempotent: safe to re-run. Works for fresh installs AND existing laptops.
#
# Usage:
#   install.sh --role work|personal          # prompts if --role is omitted
#   install.sh --role personal --prune       # also remove pkgs not in Brewfile.*
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
role=""
prune=0

while [ $# -gt 0 ]; do
  case "$1" in
    --role)   role="${2:-}"; shift 2 ;;
    --prune)  prune=1; shift ;;
    -h|--help)
      sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

say()  { printf "\n\033[1;34m==> %s\033[0m\n" "$*"; }
warn() { printf "\n\033[1;33m!! %s\033[0m\n" "$*"; }

# ---- 0. Role ----
while [ -z "$role" ]; do
  read -rp "Machine role [work/personal]: " role
  case "$role" in work|personal) ;; *) role=""; echo "Please type 'work' or 'personal'." ;; esac
done
export CHEZMOI_ROLE="$role"

# ---- 1. Homebrew ----
if ! command -v brew >/dev/null 2>&1; then
  say "Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# ---- 2. Brewfile (common + role) ----
say "Installing Brewfile.common"
brew bundle --file "$repo_dir/Brewfile.common"

say "Installing Brewfile.$role"
brew bundle --file "$repo_dir/Brewfile.$role"

if [ "$prune" -eq 1 ]; then
  warn "Pruning packages not listed in Brewfile.common + Brewfile.$role"
  brew bundle cleanup --force --file "$repo_dir/Brewfile.common"
  brew bundle cleanup --force --file "$repo_dir/Brewfile.$role"
fi

# ---- 3. 1Password sign-in (retry loop, don't hard-exit) ----
while ! op whoami >/dev/null 2>&1; do
  warn "1Password CLI not signed in."
  echo "   In another terminal: eval \$(op signin)"
  read -rp "   Press enter once signed in (Ctrl-C to abort): " _
done

# ---- 4. chezmoi apply ----
say "Applying chezmoi source (role=$role)"
chezmoi init --apply --source "$repo_dir"

# ---- 5. Bootstrap (oh-my-zsh, vim_runtime, SDKMAN, NVM, iTerm pointer, pre-commit hook) ----
say "Running post-install bootstrap"
"$repo_dir/scripts/bootstrap.sh"

# ---- 6. SSH (optional — only needed if you don't use the 1Password SSH agent) ----
# ssh-restore.sh has been deleted; 1Password handles SSH via its agent.
# On a new machine, enable the 1Password SSH agent in the app's Developer settings
# and SSH just works. Git commits are SSH-signed through the same agent (see ADR 009).

# ---- 7. macOS defaults ----
say "Applying macOS defaults"
"$repo_dir/macos/defaults.sh"

cat <<EOF

=====================================================
 Install complete. Role: $role
=====================================================

Manual follow-ups (one-time sign-ins):
  - JetBrains Toolbox → install IntelliJ → enable Settings Sync
  - VSCode → enable Settings Sync (GitHub)
  - Sign in to Claude Code, Codex, Gemini, Antigravity, Cursor, gh copilot
  - gcloud auth login && gcloud auth application-default login   (work only)

Company-specific stuff (repo clones, work skills) lives in a separate repo.
Dotfiles is done.
EOF
