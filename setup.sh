#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link_file() {
  local source="$1"
  local target="$2"

  mkdir -p "$(dirname "$target")"

  if [ -L "$target" ]; then
    local existing
    existing="$(readlink "$target")"
    if [ "$existing" = "$source" ]; then
      return 0
    fi
  fi

  if [ -e "$target" ] && [ ! -L "$target" ]; then
    local ts
    ts="$(date +%Y%m%d%H%M%S)"
    mv "$target" "${target}.bak.${ts}"
  fi

  ln -sf "$source" "$target"
}

ensure_line() {
  local line="$1"
  local file="$2"

  if [ ! -f "$file" ]; then
    printf "%s\n" "$line" > "$file"
    return 0
  fi

  if ! grep -Fqx "$line" "$file"; then
    printf "\n%s\n" "$line" >> "$file"
  fi
}

link_file "$repo_dir/ghostty/config" "$HOME/Library/Application Support/com.mitchellh.ghostty/config"

ensure_line 'eval "$(zoxide init zsh)"' "$HOME/.zshrc"

if command -v brew >/dev/null 2>&1; then
  brew bundle --file "$repo_dir/Brewfile"
else
  echo "Homebrew not found; skipping Brewfile." >&2
fi

echo "Done."
