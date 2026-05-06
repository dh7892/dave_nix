You are working on a single task in a fanned-out parallel session.
Read `{{TASK_FILE}}` carefully. Follow the conventions in any
`CLAUDE.md` files at the repo root or its parents.

You are checked out on branch `{{TASK_BRANCH}}` in a git worktree
(your current working directory). The main worktree, on branch
`{{MAIN_BRANCH}}`, lives at:

    {{MAIN_WORKTREE}}

That's where your work needs to land when the human is happy
with it.

If the task is ambiguous, under-specified, or you have
reservations about the approach, **ask clarifying questions
before starting** — the human is available in this Zellij pane.
Otherwise, proceed.

## When you've finished the task itself

1. Move the task file from `plan/tasks/in-progress/` to
   `plan/tasks/completed/` (only if those directories exist).
2. Commit your work on this branch with a clear message
   referencing the task.
3. Print a short summary of what you did and what to verify.
4. **Stop and wait for the human to confirm they're happy.**
   Do not merge yet. Do not push. Do not delete anything.

## After the human confirms

Only once they've explicitly said they're happy:

5. Squash-merge your branch into `{{MAIN_BRANCH}}` from the
   main worktree, so the whole task lands as one clean commit
   on `{{MAIN_BRANCH}}`:

       git -C {{MAIN_WORKTREE}} merge --squash {{TASK_BRANCH}}
       git -C {{MAIN_WORKTREE}} commit -m "<task-id>: <short summary>"

   Replace the placeholder message with something genuinely
   useful: start with the task identifier (e.g. `TASK-002`) so
   the commit is greppable, then a one-line summary of what
   actually changed. Keep it imperative mood, present tense.

   This is safe from inside your own worktree — git handles
   cross-worktree operations fine as long as the target branch
   isn't checked out elsewhere (it won't be: the main worktree
   owns `{{MAIN_BRANCH}}`). `--squash` stages the changes
   without creating a merge commit, so the follow-up `commit`
   step is mandatory — don't skip it.

   If git reports an index-lock error, another worker is
   merging right now — wait a moment and retry.

6. If the squash-merge has conflicts, resolve them in the
   main worktree: edit the conflicting files under
   `{{MAIN_WORKTREE}}`, then

       git -C {{MAIN_WORKTREE}} add <files>
       git -C {{MAIN_WORKTREE}} commit -m "<task-id>: <short summary>"

   Ask the human for help if the resolution isn't obvious.

7. Once the squash commit is in, print:

       Squash-merged into {{MAIN_BRANCH}}. Safe to close this tab.

   and stop. Do not push. Do not delete the worktree or the
   branch — the human will tidy those up after all workers
   are in. (Note for the human's later cleanup: because this
   was a squash-merge, `git branch -d {{TASK_BRANCH}}` will
   refuse — use `-D` to force-delete.)
