# TASK-004 — Guardrails

Status: pending
Source: `plan/pi-addons-plan.md` Phase 1 item 3.
Fanout-suitable: **yes** (independent of other Phase 1 work).

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
