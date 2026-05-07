# TASK-012 — Print "last switched" timestamp at end of `danix-switch`

Status: pending
Fanout-suitable: **no** (tiny, single-file change).

## Goal

After a successful `danix-switch`, echo a human-readable
timestamp so I can tell at a glance whether I've already run
it recently (and avoid re-running it if I got distracted
mid-session).

## Scope

- Edit the `danix-switch` shell function in
  `modules/home-manager/dotfiles/zshrc`.
- Only the success path. If `sudo darwin-rebuild switch …`
  exits non-zero, do **not** print a timestamp (the failure
  output is more important and a "completed at …" line would
  be misleading).
- No persistent file, no state directory, no consumer in
  `danix-ask` or the prompt — just an echo to stdout at the
  end of the run. We can add fancier reporting later if it
  ever turns out to be useful.

## Plan

1. Capture the exit status of the `darwin-rebuild` call
   instead of letting it be the function's tail call. Roughly:

   ```sh
   if sudo darwin-rebuild switch --flake "${repo_path}#default" --impure; then
     echo
     echo "✓ danix-switch completed at $(date '+%a %d %b %Y %H:%M:%S')"
   else
     return $?
   fi
   ```

   Pick whatever exact `date` format reads nicely — human
   readable, local time, includes day-of-week so "yeah I did
   that this morning" is obvious. No need for ISO8601.

2. Leave `danix-up` alone — it calls `danix-switch` at the
   end, so it inherits the message for free.

3. Dry-run-build (`darwin-rebuild build --flake .#default
   --impure`) to confirm the zshrc still evaluates.

4. Commit. User runs `danix-switch` themselves to pick up the
   change (and will see the new line on the *next* run after
   that).

## Acceptance

- A successful `danix-switch` ends with a line like
  `✓ danix-switch completed at Wed 06 May 2026 14:32:10`.
- A failing `darwin-rebuild switch` does **not** print that
  line, and `danix-switch` still returns a non-zero exit
  status in that case.
- `danix-up` shows the same line at the end of its run.

## Notes

- Pure quality-of-life. Five-minute job; in scope for
  `danix-add`.
