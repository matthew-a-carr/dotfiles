# ADR 009: SSH-Signed Commits via 1Password Agent

**Date:** 2026-04-22
**Status:** Accepted

## Context

Prior state: git commits signed with GPG (`signingkey = BBD68EACBD96C903`), GPG Suite installed, pinentry-mac caching passphrase in macOS Keychain. New-machine bootstrap plan: export secret key to a 1Password document, `scripts/gpg-import.sh` re-imports on first run, re-grant ultimate trust.

After adopting the 1Password SSH agent (ADR 004), the full GPG stack (gpg-agent, pinentry-mac, GPG Suite, ~/.gnupg, secret-key export/import ceremony) is redundant — git supports SSH-format signatures (`gpg.format = ssh`) since 2.34, and the same SSH key used for authentication can sign commits via `/Applications/1Password.app/Contents/MacOS/op-ssh-sign`.

GitHub accepts SSH signatures when the public key is registered as a *signing* key (distinct from an *authentication* key — same key material, two registrations).

## Decision

Switch commit signing from GPG to SSH. The 1Password SSH agent signs via `op-ssh-sign`; the same private key handles authentication and signing.

`home/dot_gitconfig.tmpl` configures:

```ini
[gpg]
    format = ssh
[gpg "ssh"]
    program = /Applications/1Password.app/Contents/MacOS/op-ssh-sign
    allowedSignersFile = {{ .chezmoi.homeDir }}/.ssh/allowed_signers
[user]
    signingkey = {{ .git.signingkey }}     # SSH public key, e.g. "ssh-ed25519 AAAA..."
[commit]
    gpgsign = true
[tag]
    gpgsign = true
```

`home/private_dot_ssh/allowed_signers.tmpl` contains `{{ .git.email }} <pubkey>` so local `git log --show-signature` reports "Good signature" without a GPG key ring.

Delete `scripts/gpg-import.sh`. Remove the GPG import step from `install.sh`. The 1Password document storing the GPG secret key can be deleted separately.

## Consequences

- **One key, one mechanism**: same 1Password SSH key authenticates to GitHub AND signs commits. Touch ID prompts come from the same source.
- **No GPG stack** on future machines — no `~/.gnupg`, no gpg-agent, no GPG Suite app, no pinentry-mac cache config. Smaller surface.
- **New-machine bootstrap shrinks**: remove the "import GPG secret key" step. 1Password login is the only prerequisite.
- **Pre-existing GPG-signed history still verifies**: git supports mixed signature formats across history.
- **GitHub "Verified" badge** requires the public key to be registered as a *signing* key, not just an *authentication* key. One-time UI step: Settings → SSH and GPG keys → New SSH key → Key type = "Signing Key". Documented in `README.md`.
- **`allowedSignersFile` is required for local verification** — otherwise `git log --show-signature` errors. The file is tiny and git-managed.
- **Loss of GPG for non-git uses** (email encryption, file encryption) — not in current workflow, but if needed later, GPG can be re-added without removing the SSH signing setup.
