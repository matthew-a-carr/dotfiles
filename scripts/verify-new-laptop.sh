#!/usr/bin/env bash
# Post-install checks for a new laptop. Safe to run repeatedly.
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
failures=0

check() {
  local name="$1"
  shift
  printf "\n==> %s\n" "$name"
  if "$@"; then
    printf "ok: %s\n" "$name"
  else
    printf "FAILED: %s\n" "$name" >&2
    failures=$((failures + 1))
  fi
}

check_github_ssh() {
  local output
  output="$(ssh -T git@github.com 2>&1 || true)"
  printf "%s\n" "$output"
  [[ "$output" == *"successfully authenticated"* ]]
}

check_nvm_default() {
  export NVM_DIR="$HOME/.nvm"
  # shellcheck disable=SC1091
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  command -v nvm >/dev/null 2>&1 && nvm use default >/dev/null
}

check_brew_role() {
  local role
  role="$(chezmoi data | jq -r '.role // empty')"
  [ -n "$role" ] && brew bundle check --file "$repo_dir/Brewfile.$role"
}

check "chezmoi doctor" chezmoi doctor
check "chezmoi diff is empty" bash -c '[ -z "$(chezmoi diff)" ]'
check "Brewfile.common is satisfied" brew bundle check --file "$repo_dir/Brewfile.common"
check "role Brewfile is satisfied" check_brew_role
check "1Password CLI installed" command -v op
check "1Password SSH agent socket exists" test -S "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
check "GitHub CLI authenticated" gh auth status
check "GitHub SSH authenticated" check_github_ssh
check "git-lfs available" git lfs version
check "default Node.js available through nvm" check_nvm_default
check "Claude MongoDB MCP wrapper available" test -x "$HOME/.local/bin/claude-mongodb-mcp"
check "gitleaks clean" gitleaks detect --source "$repo_dir" --config "$repo_dir/.gitleaks.toml" --redact

if [ "$failures" -gt 0 ]; then
  printf "\n%d check(s) failed. Fix the failures above, then re-run this script.\n" "$failures" >&2
  exit 1
fi

printf "\nAll new-laptop checks passed.\n"
