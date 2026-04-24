---
name: staleness-review
description: Audit this dotfiles repo for drift — ADRs with unclosed "transitional" promises, docs/scripts referencing files that no longer exist, README/AGENTS.md layout tables that disagree with `ls`, per-repo git signingkeys still pointing at retired mechanisms, chezmoi source/live drift, and orphaned 1Password references. Use when: asked to "review for out-of-dateness", after deleting a script or retiring an ADR, before a new-laptop test, or on any cadence. Outputs a triaged finding list; does NOT auto-fix.
---

# Staleness Review — dotfiles repo

Use this skill only in `~/git/dotfiles`. It encodes the review that found today's SSH-agent fallout (ADR 004 transitional fallback outliving its window, stale `user.signingkey = BBD68EACBD96C903`, docs referencing `ssh-restore.sh` after deletion).

Goal: surface drift, not delete things. Every finding is a candidate fix — let the user confirm per item.

## Workflow

Work from `~/git/dotfiles` and run each of the seven checks. For each, classify findings:

- **Stale (fix)** — code/docs claim something that isn't true now.
- **Historical (keep)** — ADRs intentionally narrate prior state; references inside `docs/decisions/*.md` to removed files are usually expected.
- **Noise** — test your heuristic before flagging (e.g. backstop ignore patterns have no matching file and that's the point).

Present findings grouped by check with a short verdict per finding. Do not edit files until the user picks which fixes to apply.

### 1. ADRs with unclosed time-bound promises

```bash
grep -rniE 'for ~?a week|for now|transition|temporar|remove after|TODO|FIXME|deprecat' docs/decisions/*.md \
  | grep -v Superseded
```

For each hit, decide:
- Did the time window pass? Then either act on the promise (delete the thing, write a supersede ADR) or document why it's deferred.
- Is the hit inside a ADR that's already `Superseded by …`? Ignore.

### 2. Docs/scripts referencing files that no longer exist

```bash
# scripts referenced anywhere
for s in $(grep -rohE 'scripts/[a-zA-Z_-]+\.sh' . \
            --include='*.md' --include='*.sh' --include='*.tmpl' \
            --exclude-dir=.git 2>/dev/null | sort -u); do
  test -f "$s" || echo "MISSING: $s"
done
```

Run the same check restricted to non-ADR files — references inside `docs/decisions/` are expected to cite deleted files as history:

```bash
grep -rn '<missing-path>' . --include='*.md' --include='*.sh' --include='*.tmpl' \
  --exclude-dir=.git | grep -v 'docs/decisions/'
```

Only the non-history matches are actionable.

### 3. README.md / AGENTS.md layout vs reality

```bash
echo '-- claimed --'
grep -nE 'scripts/|home/|Brewfile' AGENTS.md README.md
echo '-- actual scripts --'
ls scripts/
echo '-- actual top-level home/ --'
ls home/
echo '-- actual Brewfiles --'
ls Brewfile.*
```

Walk the layout tables in both files and confirm each listed entry exists and each actual entry is listed.

### 4. ADR index cross-refs

```bash
# ADR file numbers vs index
ls docs/decisions/ | grep -E '^[0-9]{3}-' | cut -d- -f1 | sort -u > /tmp/adr_files
grep -oE '\[0-9]{3}\]' docs/decisions/README.md | tr -d '[]' | sort -u > /tmp/adr_index

# Any ADR file numbers referenced but missing?
for ref in $(grep -rohE 'ADR [0-9]+' docs/decisions/*.md README.md AGENTS.md 2>/dev/null \
              | grep -oE '[0-9]+' | sort -un); do
  ls docs/decisions/${ref}-*.md >/dev/null 2>&1 || echo "MISSING: ADR $ref referenced but no file"
done
```

Also eyeball that every ADR's `**Status:**` line matches its entry in `docs/decisions/README.md`.

### 5. Per-repo git signingkeys still pointing at retired mechanisms

```bash
for d in ~/git/*/.git/config; do
  repo=$(dirname $(dirname "$d"))
  key=$(git -C "$repo" config --local --get user.signingkey 2>/dev/null || true)
  if [ -n "$key" ] && ! echo "$key" | grep -q '^ssh-'; then
    echo "NON-SSH signingkey in $repo : $key"
  fi
done
```

Any hit is stale from the pre-ADR-009 GPG era. Fix with `git -C <repo> config --local --unset user.signingkey` so it inherits the global SSH signingkey.

### 6. chezmoi drift

```bash
chezmoi doctor
chezmoi status                 # empty = no live→source drift
chezmoi diff --reverse | head  # empty = no source→live drift
chezmoi managed | while read f; do
  test -e "$HOME/$f" || echo "MISSING LIVE: $f"
done
```

Expected: all silent. Anything else is drift to investigate.

### 7. Orphaned 1Password references

```bash
grep -rhoE 'op://[A-Za-z]+/[^"'\'' )]+' . \
  --include='*.md' --include='*.sh' --include='*.tmpl' \
  --exclude-dir=.git | sort -u
```

Cross-reference against the tables in `README.md` ("1Password items the repo references") and `AGENTS.md` ("Secrets that ARE wired up"). Any `op://` appearing in code/docs but missing from both tables, or vice versa, is drift.

## Reporting

Return a single triaged report with this shape:

```
## Staleness findings

### Stale (fix candidates)
- <file:line> — <one-line verdict and proposed fix>

### Historical (keep)
- <file:line> — <why it's OK>

### No findings
- <checks that came up clean>
```

Then ask the user which fixes to apply. If the user says "do them all", batch into a single conventional-commits commit with type `docs` (if doc-only), `chore` (mechanical cleanup), or `refactor` (structural), scope `staleness` or the specific area.

## Rules

- Do not delete or edit anything until the user picks findings to act on.
- Never strip content from ADRs in `docs/decisions/` — they are historical record. Time-bound language inside a superseded ADR is expected. Write a new supersede ADR rather than editing the old one.
- Do not chase transient staleness (e.g. a TODO with a date in the future, a "deprecated in next major" note) — flag and move on.
- If a finding would require a new ADR (e.g. retiring a documented decision), propose the ADR number and title but let the user approve the write.
- Don't use `--no-verify` on the resulting commit. gitleaks pre-commit is cheap; if it fails, investigate.
