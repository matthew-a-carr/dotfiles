#!/usr/bin/env bash
# Import GPG secret key from 1Password.
# Store the armored secret key export in a 1Password document named "GPG Secret Key".
set -euo pipefail

doc_name="GPG Secret Key"
key_id="BBD68EACBD96C903"   # matches ~/.gitconfig signingkey

if gpg --list-secret-keys "$key_id" >/dev/null 2>&1; then
  echo "GPG secret key $key_id already imported — skipping."
  exit 0
fi

if ! op document get "$doc_name" 2>/dev/null | gpg --import; then
  cat <<EOF >&2

Could not import GPG key from 1Password document "$doc_name".
Create the document first:
  gpg --export-secret-keys --armor $key_id | op document create - --title "$doc_name"
EOF
  exit 1
fi

# Trust the key ultimately (needed for commit signing to work silently)
echo "$key_id:6:" | gpg --import-ownertrust

echo "Imported GPG secret key $key_id"
