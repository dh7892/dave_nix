# Pi addon layout (Nix-managed)

This tree is the **single source of truth** for everything that lands in
`~/.pi/agent/` on this machine. It is wired into home-manager via
`modules/home-manager/pi.nix`. After editing anything here, run
`danix-switch` (and remember to `git add` new files first — the flake
won't see untracked files).

## Tree

```
modules/home-manager/dotfiles/pi/
├── LAYOUT.md          # this file
├── extensions/        # *.ts files, mirrored to ~/.pi/agent/extensions/
├── skills/            # one subdir per skill (must contain SKILL.md),
│                      # mirrored to ~/.pi/agent/skills/
└── prompts/           # *.md prompt templates, mirrored to ~/.pi/agent/prompts/
```

Each entry inside `extensions/`, `skills/`, and `prompts/` is symlinked
**individually** into `~/.pi/agent/...` (home-manager `recursive = true`).
That means:

- Adding a new addon = drop a file/dir in here, `git add`, `danix-switch`.
- The parent `~/.pi/agent/extensions/` directory itself is **writable**,
  so `pi install ...` would still work — but don't use it: it mutates
  state outside the flake. Install pi-packages declaratively via the
  `packages` key in `settings.json` (rendered from `pi.nix`) instead.

## settings.json

`~/.pi/agent/settings.json` is **not** a symlink. It's a regular file
that gets re-rendered at activation time from a Nix attrset
(`piSettings` in `pi.nix`), with one wrinkle: Pi itself writes
bookkeeping keys into it (e.g. `lastChangelogVersion`), so the
activation script merges our managed keys *over* whatever Pi has
already written. Managed keys win; everything else is preserved.

If you want a setting to be Nix-managed, add it to `piSettings` in
`pi.nix`. If you want Pi to own a setting (e.g. one-off TUI state),
just leave it out of `piSettings` and let Pi write it.

## Adding things — quick recipes

**A new extension:**
```
modules/home-manager/dotfiles/pi/extensions/myext.ts
```
`git add`, `danix-switch`, `/reload` inside Pi.

**A new skill:**
```
modules/home-manager/dotfiles/pi/skills/myskill/SKILL.md
modules/home-manager/dotfiles/pi/skills/myskill/helper.py   # optional
```
`git add` the directory, `danix-switch`. Skills auto-register as
`/skill:myskill`.

**A new prompt template:**
```
modules/home-manager/dotfiles/pi/prompts/review.md
```
`git add`, `danix-switch`. Invoke with `/review` inside Pi.

**A pi-package from npm/git** (no local files needed):
Edit `piSettings.packages` in `pi.nix`, e.g.
```nix
packages = [ "git:github.com/badlogic/pi-skills" ];
```
`danix-switch`. Pi auto-installs it on next startup.

## Why .gitkeep?

The three subdirs ship empty `.gitkeep` markers so git tracks the
directories even when they have no real content yet. Pi ignores
non-`.ts` / non-`SKILL.md` / non-`.md` files in these locations.
