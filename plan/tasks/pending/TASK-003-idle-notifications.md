# TASK-003 — Idle notifications

Status: pending
Source: `plan/pi-addons-plan.md` Phase 1 item 2.
Fanout-suitable: **yes**.

## Goal

Native terminal/OS notification when the agent finishes and is
waiting for user input. Zero context cost (pure event hook).

## Plan

1. Locate the bundled `notify.ts` example extension in the
   pi-coding-agent examples directory.
2. Vendor it into
   `modules/home-manager/dotfiles/pi/extensions/notify.ts`.
3. Confirm it works with our terminal: Dave primarily uses
   Ghostty (OSC 777). Read the extension's source to confirm
   which OSC sequences / bell mechanisms it uses, and verify
   Ghostty handles them. If the extension supports multiple
   strategies (OSC 777 / OSC 9 / OSC 99 / native macOS
   `osascript` notifications), pick the one that works in
   Ghostty.
4. Make sure it does **not** fire for fanout-worker sessions
   that are still mid-task — only when the agent is genuinely
   idle awaiting input. (This is the bundled extension's
   default behaviour; just verify.)
5. `git add`, dry-run-build, commit.

## Acceptance

- After `danix-switch`, ending a Pi turn in Ghostty produces
  either a system notification or an audible/visual bell that
  Dave actually notices when the Ghostty window is unfocused.
- No notifications fire mid-turn.

## Notes

- Bonus: this pairs naturally with the parallel-fanout flow
  (TASK-001). If Ghostty/Zellij surfaces per-pane bells, we
  get "this worker needs you" for free. If it doesn't, that's
  the rabbit hole flagged in TASK-001's "out of scope" section.
- Don't add a custom `--notify` CLI flag or anything fancy.
  Just enable the bundled extension as-is.
