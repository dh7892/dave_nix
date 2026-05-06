# TASK-001 — `pi-fanout`: parallel task execution via git worktrees + Zellij

Status: pending
Depends on: TASK-000 (done)
Fanout-suitable: **no** — this is the tool that *enables* fanout. Build it manually.

## Motivation

We want to fan out independent task files (the rest of this plan, for
starters) to parallel Pi sessions, each in its own git worktree and
Zellij pane, so they progress concurrently without polluting each
other's context or working tree.

Subagents were considered and parked (see `plan/pi-addons-plan.md`
Phase 1 item 0 for the rationale). The short version: `/tree` already
solves context-cleanliness for side-quests; what's actually missing is
*parallelism with isolation*, which worktrees + panes solve more
honestly than subagents would.

## Scope

Ship one shell command, `pi-fanout`, declared in
`modules/home-manager/default.nix` (likely as `pkgs.writeShellApplication`).
**Not** under the `danix-*` family — it's not Nix-specific and might
later be useful in other repos.

### Behaviour

```
pi-fanout [tasks-dir]
```

- Default `tasks-dir` is `plan/tasks/pending` (relative to repo root).
- Must be run from inside a git repo; bail otherwise.
- Lists all `*.md` files in `tasks-dir`, presents them via
  `gum choose --no-limit --header "Select tasks to fan out"`.
  - `gum` gives space-toggle, `a` for select-all, enter to confirm.
- For each selected task file:
  1. Derive a branch name: strip `.md`, prefix with `task/`. E.g.
     `TASK-002-questionnaire-extension.md` → `task/TASK-002-questionnaire-extension`.
     Slugify if needed (lowercase, replace whitespace with `-`).
  2. Create a sibling worktree at `../<repo-name>-worktrees/<branch>/`
     on a new branch off the current branch. (Use `git worktree add -b`.)
  3. Move the task file from `tasks-dir` to
     `<repo>/plan/tasks/in-progress/` **inside the worktree** (so the
     move is part of the worker's branch and gets merged back later).
     If `in-progress/` doesn't exist or `tasks-dir` isn't the
     conventional layout, skip the move and just leave the file
     where it is. The tool should not invent conventions; it should
     respect the one already declared in `~/code/CLAUDE.md` when
     present.
  4. Open a new Zellij pane (or tab — pick one and stick with it;
     tab is probably better for visibility) named after the task,
     `cd`'d into the worktree.
  5. Launch `pi` in that pane with a seeded initial prompt (see
     "Worker prompt" below). Use `pi "<prompt>"` — pi's CLI accepts
     a positional initial message.

### Worker prompt (seed)

Store the template at
`modules/home-manager/dotfiles/pi/prompts/fanout-worker.md` so it's
editable without touching the script. The script substitutes
`{{TASK_FILE}}` before passing it to `pi`. Initial content:

> You are working on a single task in a fanned-out parallel session.
> Read `{{TASK_FILE}}` carefully. Follow the conventions in any
> `CLAUDE.md` files at the repo root or its parents.
>
> If the task is ambiguous, under-specified, or you have
> reservations about the approach, **ask clarifying questions
> before starting** — the human is available in this Zellij pane.
> Otherwise, proceed.
>
> When you finish:
> 1. Move the task file from `plan/tasks/in-progress/` to
>    `plan/tasks/completed/` (only if those directories exist).
> 2. Commit your work on this branch with a clear message
>    referencing the task.
> 3. Print a short summary of what you did and what to verify,
>    then stop. Do not push and do not merge.

### Reconciliation (no separate tool)

Per Dave's call: fan-in is just `git merge task/<branch>` from main,
manually, after eyeballing the worker's summary. The task-file move
to `completed/` is already in the worker's commit, so it lands on
main with the merge. If we later find we want a `pi-fanin` helper
to automate `git merge && git worktree remove`, that's a follow-up
task — not part of this one.

## Dependencies

Verify and add to home-manager packages if missing:

- `git` — present.
- `zellij` — present.
- `gum` — **add** (charmbracelet, in nixpkgs). Already added as part
  of TASK-001 prep.
- `pi` — present.

## Acceptance

1. From this repo, with three task files in `plan/tasks/pending/`,
   running `pi-fanout` opens a `gum` multi-select, lets me pick two
   of them, and produces:
   - Two new git branches `task/<...>` with worktrees at
     `../dave_nix-worktrees/<branch>/`.
   - Two new Zellij panes, each running `pi` with the worker
     prompt seeded.
   - The two task files moved to `plan/tasks/in-progress/` in
     their respective worktrees (the main checkout still shows
     them in `pending/` until merged).
2. Closing one of the panes and running `git merge task/<branch>`
   from main brings the worker's code changes and the
   `pending/ → completed/` move across in one commit.
3. The third (unselected) task file is untouched.

## Out of scope

- Pane notifications when a worker is awaiting input or done.
  Nice-to-have; needs investigation into Zellij's IPC / OSC story
  through a Pi process. **Future task.**
- Cross-project formalisation, dependency graphs between tasks,
  per-task model selection, GitHub/Jira integration. Defer until
  this version has been used in anger on at least one real
  multi-task batch.
- A `pi-fanin` helper. Defer until manual `git merge` proves
  insufficient.
- Auto-cleanup of worktrees after merge. Defer.

## Notes for the implementer

- This task is **not fanout-suitable** (chicken/egg). Do it
  manually in the main session.
- Remember: new files must be `git add`ed before `danix-switch`.
- Test the `gum choose` flow standalone first before wiring it
  into the worktree machinery.
- The worker prompt template is a new file at
  `modules/home-manager/dotfiles/pi/prompts/fanout-worker.md` —
  make sure `pi.nix` symlinks the `prompts/` dir already (it
  should, per TASK-000) so it picks up the new file.
