# ADR 004: 1Password SSH Agent for Authentication

**Date:** 2026-04-22
**Status:** Accepted

## Context

Prior setup: `~/.ssh/id_ed25519` on disk; `scripts/ssh-restore.sh` pulls the private key from 1Password on new machines. The private key ends up in plaintext on disk protected only by filesystem permissions.

1Password 8+ ships an SSH agent: a local UNIX socket at `~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock` that speaks the standard ssh-agent protocol. Clients configured with `IdentityAgent` point at it; signing happens inside 1Password with Touch ID per authentication (or cached session).

## Decision

Enable the 1Password SSH agent. Configure `~/.ssh/config` with:

```
Host *
  IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
```

Store the SSH private key in 1Password as a native SSH Key item (`op://Employee/id_ed25519/private key`). On any machine signed into 1Password with the SSH agent enabled, `ssh` / `git push` / etc. work without a private key file on disk.

Keep `scripts/ssh-restore.sh` and `home/private_dot_ssh/id_ed25519.pub` for ~a week as a belt-and-braces fallback. Remove after verification period.

## Consequences

- **Private key never lands on disk** in plaintext on future machines.
- **Touch ID per SSH use** (or timed caching) adds a per-auth audit signal in 1Password's activity log.
- **New-machine SSH is zero-config** — sign into 1Password, agent works immediately. `ssh-restore.sh` becomes optional.
- **Dependency**: `ssh` fails if 1Password isn't running. In practice 1Password is always up; mitigated by fallback key on disk during transition.
- **Some tools may not talk to the agent socket** — e.g. SSH-using daemons running outside the user's login session. Not encountered in current toolchain.
- **Enables ADR 009** — SSH-signed git commits through the same mechanism.
