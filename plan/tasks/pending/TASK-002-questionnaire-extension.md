# TASK-002 — Questionnaire extension (better question UI)

Status: pending
Source: `plan/pi-addons-plan.md` Phase 1 item 1.
Fanout-suitable: **yes**.

## Goal

When the agent would otherwise ask the user a wall of questions, it
should instead use a structured multi-question tool that the TUI
renders with selectable options + tab navigation + free-text "other".
This dramatically improves UX during planning/design conversations
without bloating the system prompt — only a single tool description
sits in context.

## Source material

Pi ships two example extensions that already do this:

- `questionnaire.ts` — multi-question form, tab navigation between
  fields, selectable options, free-text "other".
- `question.ts` — single-question variant.

Locate them in the pi-coding-agent examples directory (under the
nix store path for the `pi` package — `find /nix/store -path
'*pi-coding-agent*/examples/extensions*' 2>/dev/null` is a starting
point), and confirm they are still bundled in the version we have
installed.

## Plan

1. Locate the bundled example(s).
2. Vendor `questionnaire.ts` into
   `modules/home-manager/dotfiles/pi/extensions/`. Take the
   single-question one too if it's small and adds value.
3. Confirm `pi.nix` already symlinks the extensions dir into
   `~/.pi/agent/extensions/` (it should, per TASK-000).
4. Set a `promptSnippet` / `promptGuidelines` on the extension so
   the model is nudged to use the structured tool when it would
   otherwise ask a wall of questions. Keep this **short** — every
   character lives in the steady-state system prompt.
5. `git add` the new files and run a dry-run rebuild
   (`darwin-rebuild build --flake .#<host>` — check the host name
   in `flake.nix`) to validate. Do **not** run `darwin-rebuild
   switch` — that's Dave's job.
6. Commit on this branch.

## Acceptance

- After `danix-switch`, in a fresh Pi session, asking the agent
  "I want to plan a new feature, ask me what you need to know"
  causes it to invoke the questionnaire tool, and the TUI
  renders selectable options.
- `pi list` (or equivalent) shows the questionnaire extension.
- The system prompt has grown by no more than ~one tool
  description's worth of text.

## Notes

- Ground rule #2 from the plan: prefer skills over extensions
  for context cost. This is one of the few cases where an
  extension is the right shape, because the *behaviour* (a TUI
  form) is what we want, not just a workflow.
- If the bundled example has a heavyweight `before_agent_start`
  prompt injection, trim it to the bare minimum.
