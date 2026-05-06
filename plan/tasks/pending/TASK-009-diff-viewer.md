# TASK-009 — Rich diff viewer for proposed edits

Status: pending
Source: `plan/pi-addons-plan.md` Phase 2.5 item 8.
Fanout-suitable: **yes**, but the `/explain-diff` sub-feature
might want a quick design discussion before implementation.

## Goal

Two things, both opt-in:

1. **Terminal-default rich diffs** for `edit`/`write` tool
   results — use `difftastic` (already chosen) so we get
   tree-sitter-aware structural diffs by default in the
   transcript.
2. **Optional GUI review** (Meld) for proposed edits before
   they're applied, gated behind `/review on` or a
   `--review-diffs` flag, so it doesn't slow down normal flow.
3. **Bonus** (separable): `/explain-diff` command that uses a
   fast model to annotate hunks with one-line semantic
   summaries.

## Plan

### Sub-task A — `difftastic` as default renderer

1. Add `difftastic` to home-manager packages (it's in nixpkgs).
2. Set `GIT_EXTERNAL_DIFF=difft` (or via `git config`) in shell
   config so plain `git diff` uses it. Confirm this doesn't
   break anything Dave uses.
3. Write a small Pi extension (or use an existing
   `tool_result` renderer hook if one exists in the example
   set) that runs `edit`/`write` proposed changes through
   `difft` for display in the Pi transcript. Keep this
   extension tiny — it's purely a presentation hook, no prompt
   text.

### Sub-task B — optional Meld review

1. Add `meld` as a Homebrew cask (it's GUI; nixpkgs has it for
   Linux only on darwin). Use the existing `homebrew.casks`
   surface in `modules/darwin/default.nix`.
2. Pi extension hooks `tool_call` for `edit`/`write`. When
   `/review on` (or `pi --review-diffs`) is active:
   - Write the proposed file content to a tempfile.
   - Open `meld <current> <proposed>` and **block the tool
     call** until Meld exits.
   - On accept: let the tool call proceed.
   - On reject: cancel the tool call with a reason.
3. Default state: **off**. Toggle is per-session.

### Sub-task C (bonus) — `/explain-diff`

1. Discuss with Dave whether to do this in this task or split
   it out. It's the only piece that doesn't have an
   off-the-shelf shape.
2. Sketch: command takes the current pending diff (or last
   applied diff), sends it to a fast model (Haiku/Flash) with
   a prompt asking for a one-line summary per hunk, and
   renders annotated alongside the diff.

## Acceptance

- `git diff` from the shell uses `difftastic`.
- Pi's display of `edit`/`write` results uses structural diffs.
- `pi --review-diffs` causes Meld to pop up before each edit
  is applied; user can accept or reject; the tool call
  proceeds or is blocked accordingly.
- (If C is included) `/explain-diff` annotates pending changes
  with semantic summaries.

## Out of scope

- Kaleidoscope integration (paid; skip unless Dave decides
  he wants it).
- Custom GUI diff viewer of our own.
- Auto-applying LLM-suggested fixes inside the diff viewer.
