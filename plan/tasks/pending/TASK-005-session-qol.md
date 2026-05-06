# TASK-005 — Session quality-of-life

Status: pending
Source: `plan/pi-addons-plan.md` Phase 1 item 4.
Fanout-suitable: **yes**.

## Goal

Two small bundled-example extensions for session ergonomics.

## Scope

1. **`session-name.ts`** — auto-name sessions from the first
   user prompt so `/resume` shows meaningful labels instead of
   UUIDs.
2. **`bash-spawn-hook.ts`** — source `~/.profile` (and/or our
   relevant shell init) so `bash` tool calls see the same
   environment Dave does (mise, custom PATH entries, etc.).

## Plan

1. Locate both bundled examples.
2. Vendor each into
   `modules/home-manager/dotfiles/pi/extensions/`.
3. **For `bash-spawn-hook.ts`:** check it actually helps under
   our setup. Dave's interactive shell is nushell with zsh
   underneath; tooling like mise, direnv, fnm etc. may already
   be picked up by Pi's bash invocations or may not. Run a
   small probe (e.g. ask Pi to `bash -c 'which mise'` before
   and after enabling) to verify the extension does something
   useful here. If it doesn't help, **skip** it and document
   why in a comment at the top of the (un-vendored) file's
   slot in this task.
4. `session-name.ts` should be safe to adopt unconditionally.
5. `git add`, dry-run-build, commit.

## Acceptance

- `/resume` lists previous sessions with human-readable names
  derived from their first prompts.
- (If `bash-spawn-hook.ts` is kept) `bash -c 'env'` from inside
  Pi shows the same key environment variables as `env` in a
  fresh Ghostty terminal.

## Notes

- These are the kind of tiny QoL wins that pile up. Don't
  spend more than an afternoon on this whole task. If something
  doesn't fit cleanly, drop it and move on.
