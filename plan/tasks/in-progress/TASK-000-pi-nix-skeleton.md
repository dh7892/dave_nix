# TASK-000 — pi-nix-skeleton

Status: **in progress**
Source: Phase 0 of `plan/pi-addons-plan.md`.

## Goal

Establish the directory + home-manager wiring so every future Pi
addon (extension, skill, prompt template, pi-package) is a one-liner.
Nothing functional yet — just the plumbing.

## What to build

- `modules/home-manager/pi.nix` — new home-manager module, imported
  from `default.nix`.
- Generates `~/.pi/agent/settings.json` from a Nix attrset
  (`piSettings`), merged over Pi-owned keys via jq at activation.
- Symlinks (recursive, individual entries):
  - `dotfiles/pi/extensions/*` → `~/.pi/agent/extensions/`
  - `dotfiles/pi/skills/*`     → `~/.pi/agent/skills/`
  - `dotfiles/pi/prompts/*`    → `~/.pi/agent/prompts/`
- `dotfiles/pi/LAYOUT.md` — CLAUDE.md-style note explaining the
  layout for future agents (also exposed under
  `~/.config/dave_nix/pi-LAYOUT.md`).
- `.gitkeep` in each of the three subdirs so empty dirs are tracked.

## Constraints (from the plan)

- No `pi install` outside the flake — `packages` is declared in
  `piSettings` instead.
- `settings.json` must remain writable (Pi mutates it at runtime),
  so it is **not** a symlink — activation script merges instead.
- Per-machine info goes through `private.nix`. (None needed yet.)
- All work must survive a fresh `danix-switch` on a clean machine.

## Acceptance

- After `danix-switch`:
  - `~/.pi/agent/{extensions,skills,prompts}/` exist.
  - `~/.pi/agent/settings.json` is a regular file (not symlink) and
    still contains any Pi-owned bookkeeping keys it had before
    (e.g. `lastChangelogVersion`).
  - `pi` starts cleanly, reports zero extensions/skills/prompts (per
    spec; we haven't added any yet).
- Adding a new extension / skill / prompt = drop a file in the
  matching `dotfiles/pi/*/` subdir, `git add`, `danix-switch`,
  appears in `~/.pi/agent/...`.

## Implementation notes

- `home.file."<x>".recursive = true` symlinks each *child* entry, not
  the dir itself. That keeps `~/.pi/agent/extensions/` writable so
  Pi can scribble next to our managed entries if it ever needs to —
  but in practice it shouldn't, and we don't.
- `lib.escapeShellArg (builtins.toJSON piSettings)` is safe for
  passing through to `jq --argjson` (e.g. `'{}'`, `'{"theme":"dark"}'`).
- `$DRY_RUN_CMD` is honoured for `darwin-rebuild build` / dry-runs.

## Follow-ups (do NOT do here)

- Anything actually populating `extensions/`, `skills/`, `prompts/` —
  that's Phase 1 onward.
- `piSettings.packages` for pi-packages — added when Phase 2 needs it.
- Touching `davim/` — different subflake, out of scope.

## Hand-off

Once acceptance is met:
- Move this file to `plan/tasks/completed/`.
- Tell Dave to `git add` the new files and run `danix-switch` (do
  not run it for him — see `CLAUDE.md`).
