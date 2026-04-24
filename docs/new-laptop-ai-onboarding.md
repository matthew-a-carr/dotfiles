# New Laptop AI Onboarding

Use this when an AI session is driving setup on a fresh Mac.

## Prompt to Paste

```text
You are helping me set up a new macOS laptop from my dotfiles repo.

Goals:
- Install the dotfiles end-to-end.
- Keep secrets out of git.
- Prefer the repo's scripts over ad-hoc manual setup.
- After install, run the repo verification script and fix any deterministic failures.

Repo:
https://github.com/matthew-a-carr/dotfiles

Start by checking whether Xcode command line tools and Homebrew exist. If not,
install them. Then clone the repo to ~/git/dotfiles over HTTPS, run:

~/git/dotfiles/install.sh --role work

During setup, guide me through any required browser/app sign-ins:
- 1Password CLI and app
- 1Password SSH agent
- GitHub CLI
- Claude Code, Codex, Gemini, Antigravity, Cursor, GitHub Copilot
- gcloud auth login and gcloud auth application-default login for work

When install finishes, run:

~/git/dotfiles/scripts/verify-new-laptop.sh

For any failure:
- If it is an account/auth sign-in, tell me exactly what to sign into and rerun the check.
- If it is deterministic repo config, edit the repo, run validation, commit, and push.
- Do not commit secrets, auth files, cache files, app session state, or private keys.
```

## Notes for the AI Session

- `install.sh` is idempotent and safe to rerun.
- `scripts/bootstrap.sh` is idempotent and safe to rerun after enabling the 1Password SSH agent.
- `scripts/verify-new-laptop.sh` is the acceptance test.
- `~/.claude.json` is not managed; Claude MCP entries are restored through `scripts/claude-mcp-restore.sh`.
- Brewfiles are maintained intentionally. Do not run `brew bundle dump` into the repo without reviewing every entry.
