# TASK-004 — Guardrails

Status: parked
Source: `plan/pi-addons-plan.md` Phase 1 item 3.
Fanout-suitable: **yes** (independent of other Phase 1 work).

## Parked — 2026-05-06

Parked during a fanout attempt because the bundled
`confirm-destructive.ts` in pi-coding-agent 0.73.0 does **not** do what
the scope here describes. It only confirms destructive *session*
actions (`/clear`, session switch, fork) — it does not gate
destructive bash commands like `rm -rf`, `sudo`, or destructive
`git`. So the acceptance line

> Running `bash` with `rm -rf foo` prompts for confirmation.

can't be satisfied by configuring the bundled extension; it would
require forking it and adding a `tool_call` hook on `bash`, which
contradicts the task's own "Resist the urge to write our own
guardrails" note.

Open questions to resolve before unparking:

1. Do we accept a minimal fork of `confirm-destructive.ts` that adds
   a `tool_call` hook for `bash` with regex-based detection of
   `rm -rf`, `sudo`, `git push --force`, `git reset --hard`, etc.?
   Or do we drop the bash-command acceptance criterion and ship
   only the session-level confirmations the bundled extension
   provides?
2. Should we instead look upstream — is there a different bundled
   example (e.g. `bash-spawn-hook.ts`, `permission-gate.ts`) that
   already covers destructive bash, and was the task description
   conflating two extensions?

The other three pieces (`protected-paths`, `dirty-repo-guard`,
`git-checkpoint`) all looked tractable and could be split out into
their own task if we want partial progress before the
`confirm-destructive` question is resolved. Notes from the fanout
attempt:

- `dirty-repo-guard.ts` only hooks `session_before_switch` /
  `session_before_fork`, so fanout workers (which start clean and
  don't switch sessions) won't see false positives. No env-var
  skip needed.
- `git-checkpoint.ts` uses `git stash create` (no working-tree
  mutation) and clears on `agent_end`, so it shouldn't conflict
  with worker commit-at-end behaviour. Probably safe to ship
  globally.
- `protected-paths.ts` hardcodes its list; the task already
  anticipates a minimal fork with a top-of-file comment.

## Goal

Adopt a small bundle of bundled-example guardrail extensions that
prevent dumb mistakes. All are pure event-hook extensions with
zero steady-state context cost.

## Scope

Vendor these bundled examples from pi-coding-agent into
`modules/home-manager/dotfiles/pi/extensions/`:

1. **`confirm-destructive.ts`** — confirm `rm -rf`, `sudo`,
   destructive `git` commands, etc. before they run.
2. **`protected-paths.ts`** — block writes to sensitive paths.
   Default list plus our additions:
   - `~/.config/dave_nix/private.nix`
   - `secrets/`
   - `*.age` files
   - any path under `~/.ssh/`
   - any path under `~/.gnupg/`
   - `~/.config/op/` (1Password CLI config)
3. **`dirty-repo-guard.ts`** — warn (not block) when starting
   work on a dirty repo. Useful in normal sessions; possibly
   noisy inside fanout workers (which start clean by
   construction). Check the extension's config surface — if it
   can be skipped when an env var is set, have `pi-fanout`
   (TASK-001) set that env var when launching workers.
4. **`git-checkpoint.ts`** — auto-stash per turn, easy revert
   on a bad turn. Read the extension carefully before adopting:
   we want to confirm it doesn't conflict with the worker's
   commit-at-end behaviour described in TASK-001.

## Plan

1. Locate each bundled example.
2. Vendor each into the extensions dir.
3. Customise `protected-paths.ts` config to include our extra
   paths (above). Prefer doing this via the extension's config
   surface rather than editing the file's source — but if the
   bundled version hardcodes the list, fork it minimally and
   note the divergence in a top-of-file comment.
4. For `dirty-repo-guard.ts`: verify it can be silenced for
   fanout workers, or accept that workers will see one warning
   per session (probably fine).
5. For `git-checkpoint.ts`: think carefully about how it
   interacts with worker sessions that *want* the agent to be
   making commits. If there's a conflict, either skip
   `git-checkpoint` for now or constrain it to non-fanout
   sessions.
6. `git add`, dry-run-build, commit.

## Acceptance

- A Pi session refuses to write to `~/.config/dave_nix/private.nix`
  without explicit confirmation.
- Running `bash` with `rm -rf foo` prompts for confirmation.
- Starting a session in a dirty repo surfaces a warning.
- Worker sessions launched by `pi-fanout` (once TASK-001 lands)
  don't get false-positive warnings.

## Notes

- Resist the urge to write our own guardrails. The bundled
  examples are battle-tested. Configure, don't fork, where
  possible.
- Keep `protected-paths.ts`'s list reviewable: a comment at the
  top of the (possibly-forked) file should explain *why* each
  custom path is on the list, so future-Dave can prune.
