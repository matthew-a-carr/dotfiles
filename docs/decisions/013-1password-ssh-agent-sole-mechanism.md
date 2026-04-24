# ADR 013: 1Password SSH Agent as Sole SSH Mechanism

**Date:** 2026-04-24
**Status:** Accepted — supersedes [ADR 004](004-1password-ssh-agent-for-authentication.md)

## Context

ADR 004 adopted the 1Password SSH agent for authentication but kept a transitional safety net: `scripts/ssh-restore.sh` (pulls `op://Employee/id_ed25519/private key` onto disk) and an `~/.ssh/id_ed25519` file on disk, "for ~a week … Remove after verification period."

The verification period has elapsed. Today the fallback actively caused two failure modes:

1. **Repeated 1Password approval prompts on git push.** `~/.ssh/config` contained `Host github.com { AddKeysToAgent yes; UseKeychain yes; IdentityFile ~/.ssh/id_ed25519 }` alongside the ADR 004 `Host * IdentityAgent = 1Password agent`. The github.com block tried to present the on-disk key to the 1Password agent, triggering an approval dialog on every SSH op to GitHub.

2. **Signing failure with a cryptic error.** A leftover repo-local `user.signingkey = BBD68EACBD96C903` (the pre-ADR-009 GPG key ID) in one repo caused `op-ssh-sign: no ssh public key file found: "BBD68EACBD96C903"`. Unrelated to the fallback, but surfaced during the same debugging pass and is worth noting in the same retirement.

The transitional fallback is now the liability it was supposed to prevent.

## Decision

The 1Password SSH agent is the sole mechanism for both SSH authentication and git commit signing. No private key on disk. No fallback script. No per-host overrides in `~/.ssh/config`.

Concretely:

- **Delete** `scripts/ssh-restore.sh`.
- **Delete** `~/.ssh/id_ed25519` on the current machine. Future machines never materialise it.
- **Keep** `~/.ssh/id_ed25519.pub` and `~/.ssh/allowed_signers` — non-sensitive, useful for `git log --show-signature` and identity pinning.
- **Keep** `home/private_dot_ssh/config` at the minimal form:

  ```
  Include ~/.colima/ssh_config

  Host *
    IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
  ```

  No `Host github.com` stanza. No `IdentityFile`. No `AddKeysToAgent`. No `UseKeychain`.

- **Keep** the 1Password SSH Key item (`op://Employee/id_ed25519`). The 1Password agent reads it directly; nothing outside 1Password needs to touch it.
- **Keep** git commit signing as defined by [ADR 009](009-ssh-signed-commits-via-1password.md) — `gpg.format = ssh`, `gpg.ssh.program = op-ssh-sign`.

New-machine bootstrap: enable the 1Password SSH agent in the 1Password app's Developer settings. Nothing else.

## Consequences

- **Private key never on disk.** The filesystem-permissions-only protection model from ADR 004 pre-state is gone for good.
- **No dual-source confusion.** ssh-agent operations have one path — through the 1Password socket — so misconfigured per-host blocks can't pit two key sources against each other.
- **Harder recovery if 1Password is unavailable.** Mitigations: 1Password CLI can re-fetch the key on demand if ever needed (`op read "op://Employee/id_ed25519/private key"` into a temporary location), and the key never leaves 1Password's vault under normal operation. Accepting this trade-off over the recurring-friction cost of keeping the fallback.
- **Simpler ssh-config.** Just the `Host *` IdentityAgent line. No per-host special cases until something genuinely requires one.
- **ADR 004 retired.** Its core decision (use the 1Password SSH agent) remains true — this ADR absorbs and restates it without the transitional clauses.
