#!/usr/bin/env bash
# Restore SSH private key from 1Password to ~/.ssh/id_ed25519.
# Requires: op signed in, and a 1Password item matching the reference below.
set -euo pipefail

key_path="$HOME/.ssh/id_ed25519"
ref="op://Employee/id_ed25519/private key"

if [ -f "$key_path" ]; then
  echo "SSH key already present at $key_path — leaving untouched."
  exit 0
fi

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

umask 077
op read "$ref" > "$key_path"
chmod 600 "$key_path"
echo "Restored $key_path from $ref"

# Add to macOS keychain for agent
ssh-add --apple-use-keychain "$key_path" 2>/dev/null || ssh-add -K "$key_path" 2>/dev/null || true
