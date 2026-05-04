# Post-install sign-ins

After `install.sh` and `scripts/bootstrap.sh` finish, you still have to log into a handful of services. This is the cheatsheet — for each one, the command (or GUI step), and how to validate that you're actually signed in.

`scripts/verify-new-laptop.sh` covers everything in the **CLI** section automatically (it fails with a clear name if any of these aren't done). The **GUI** section is eyeball-only — there's no programmatic auth probe most desktop apps will tell you.

## CLI

### 1Password CLI + SSH agent

**Sign in:**
1. Open `/Applications/1Password.app`, sign in to your account(s).
2. **Settings → Developer**: enable both *"Integrate with 1Password CLI"* and *"Use the SSH agent"*.

**Validate:**
```sh
test -S "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
op vault list --account benefex.1password.eu   # work account
```

The agent socket is what `verify-new-laptop.sh` checks. `op whoami` is *not* a reliable check when multiple accounts are registered — it returns "account is not signed in" even when the CLI is fully usable via the GUI integration.

### GitHub CLI

```sh
gh auth login            # follow prompts (HTTPS, browser flow)
gh auth status           # validates
```

### GitHub SSH

The 1Password SSH agent already holds your `op://Employee/id_ed25519` key, so once the agent socket is up there's nothing else to configure.

**Validate:**
```sh
ssh -T git@github.com    # expect: "Hi <user>! You've successfully authenticated"
```

### gcloud (work only)

```sh
gcloud auth login                          # sign in as your work GCP user
gcloud auth application-default login      # sets ADC for SDKs
```

**Validate:**
```sh
gcloud auth list --filter=status:ACTIVE --format='value(account)'
test -s "$HOME/.config/gcloud/application_default_credentials.json"
```

The first command must print your `@hellobenefex.com` address. The second confirms the ADC file exists.

### git-lfs

Installed by Brewfile, but each *new* repo with LFS content needs `git lfs install` once. No global sign-in.

## GUI

These are eyeball-only. After installing each app via the Brewfile, open it once and complete the sign-in flow.

| App | Sign-in flow | How to validate |
|---|---|---|
| Claude (`/Applications/Claude.app`) | Open → log in to Anthropic account | Top-right shows your avatar |
| Claude Code (terminal) | `claude` (first run prompts for browser auth) | `claude --version` returns; subsequent runs don't reprompt |
| Codex (`/Applications/Codex.app`) | Open → log in to OpenAI account | App stops showing the welcome screen |
| Codex CLI | `codex` (first run prompts) | `codex` opens without re-asking for login |
| Cursor | Open → sign in (GitHub or email) | Avatar in lower-left |
| Antigravity | Open → sign in | App stops showing welcome screen |
| ChatGPT (`/Applications/ChatGPT.app`) | Open → sign in to OpenAI | Avatar in top bar |
| Gemini CLI | `gemini` (first run prompts via browser) | Subsequent runs don't reprompt |
| GitHub Copilot (in VSCode/JetBrains) | Sign in via the editor command palette → "Sign in to GitHub Copilot" | Status bar shows Copilot icon active |
| VSCode Settings Sync | Command palette → *Settings Sync: Turn On* → sign in via GitHub | Synced status icon in lower-left |
| JetBrains Toolbox | Open → sign in with JetBrains Account; from Toolbox install IntelliJ; in IntelliJ enable *Settings Sync* (with the same JetBrains Account) | All your IntelliJ prefs land on the new machine |
| Rectangle | Open once → grant Accessibility permission in *System Settings → Privacy & Security → Accessibility* | Window-snapping shortcuts work |

## Reverify

After each sign-in batch:
```sh
~/git/dotfiles/scripts/verify-new-laptop.sh
```

Anything still failing is either a deterministic repo bug or a sign-in you haven't completed. Repo bugs get fixed in this repo (commit + push); sign-ins go in the table above with their command.
