# dave_nix

Dave's macOS dev environment: Nix Flakes + nix-darwin + home-manager, targeting Apple Silicon (aarch64-darwin).

## Layout
- `flake.nix` / `flake.lock` — flake entry + locked deps
- `modules/darwin/default.nix` — system-level (nix-darwin) config
- `modules/home-manager/default.nix` — user packages/programs
- `modules/home-manager/dotfiles/` — dotfiles (zshrc, tmux.conf, config.nu, aerospace.toml, secrets, etc.)
- `davim/` — nixvim-based Neovim config, consumed as a `path:./davim` subflake. Edit nvim plugins/keymaps in here. Still usable standalone via `github:dh7892/dave_nix?dir=davim`.

## Rules for AI assistants
- **Never run** `darwin-rebuild switch/build`, `nix flake update`, or the `danix-switch` / `danix-up` helpers automatically. They are slow and may prompt for credentials. After making config changes, ask the user to run `danix-switch` themselves.
- **New files must be `git add`ed before `danix-switch`.** This repo is a flake, and Nix only sees files tracked by git. If a change introduces a new file (e.g. a new dotfile, prompt, cheatsheet, module), offer to run `git add <paths>` for the user *before* prompting them to `danix-switch`. Modified-but-tracked files are fine without staging. When in doubt, run `git status` and stage anything under `??`.
- **Prefer ad-hoc `nix shell` for testing over `danix-switch`.** A full `danix-switch` is slow, can prompt for credentials, and rebuilds the whole system — risky when working on a git worktree or iterating on a single package. When a change is ready to try out, tell the user how to spin up an isolated `nix shell` that exercises just the pending feature (e.g. `nix shell .#<pkg>`, `nix shell nixpkgs#<pkg>`, or `nix run .#<app>`). Only suggest `danix-switch` once the change has been validated and the user actually wants it live system-wide.
- **Wrap test shells in `op run` when credentials are needed.** Many things in this repo (Pi, API keys baked into env, etc.) rely on 1Password CLI templates that are normally rendered by home-manager. Inside an ad-hoc `nix shell` those env vars won't be present, so if the feature under test needs them (e.g. running Pi, hitting an LLM API, anything reading `OPENAI_API_KEY` / `ANTHROPIC_API_KEY` / similar), suggest something like `op run --env-file=<file> -- nix shell .#<pkg> -c <cmd>` (or wrap the whole shell: `op run -- nix shell …`). Point the user at the relevant `op run` invocation rather than asking them to export secrets manually.
- Homebrew packages are managed declaratively through Nix — edit the Nix config, don't run `brew` directly.
- Secrets use 1Password CLI templates; don't inline secret values.
- **Personal / per-machine info (PII) belongs in `~/.config/dave_nix/private.nix`, never in the public repo.** This includes the macOS short username, real name, email, and anything else that identifies the user or the machine. The flake imports this file at evaluation time (impure read; `danix-switch` passes `--impure`) and threads the resulting `private` attrset to home-manager via `extraSpecialArgs`. The schema lives in `private.nix.example` at the repo root. When adding a new piece of personal/per-machine config:
  1. Add the field to `private.nix.example` with a placeholder value and a brief comment.
  2. Reference it in the relevant module via the `private` arg (e.g. `private.fullName`).
  3. Tell the user to add the corresponding key to their own `~/.config/dave_nix/private.nix` before the next `danix-switch`.
  Do **not** hardcode names, emails, usernames, hostnames, or similar in any tracked file.

## Manually-wrapped packages
Some software isn't available in nixpkgs (or we want a newer version than
nixpkgs ships) and is wrapped by hand with a pinned `version` + hash.

- All such derivations **must** live inside the region delimited by
  `# WRAPPED PACKAGES — BEGIN` / `# WRAPPED PACKAGES — END` in
  `modules/home-manager/default.nix`. Do not define manually-pinned
  packages anywhere else in the file.
- Each derivation in that region must be preceded by a single
  `# update-source: <kind> <details>` comment so the updater knows where
  to look. Recognised kinds today: `github-release`, `github-tag`, `pypi`.
  See existing entries for the exact format.
- The `danix-update` helper launches an agent (Pi) that reads
  this region, bumps each derivation to its latest upstream version, and
  refreshes the matching hash. The driving prompt lives at
  `modules/home-manager/dotfiles/nix-update-wrapped-prompt.md` — if you
  introduce a new fetcher type (e.g. `fetchCrate`, `fetchgit`), add a
  recipe there as well so future updates work without human intervention.
- Anything outside the WRAPPED PACKAGES region is considered out of scope
  for the updater. Flake inputs (davim, claude-code, fenix, obsidible,
  nixpkgs, …) update via `nix flake update` and don't belong in the region.

## Agentic helpers (`danix-add`, `danix-vim`, `danix-ask`, `danix-pi`)

Four Pi-driven helpers, each with its own system prompt under
`dotfiles/`:

- **`danix-add`** (`dotfiles/danix-add-prompt.md`) — makes a
  user-described change anywhere in this flake **except** under
  `./davim/`: adding a package, tweaking a `programs.*` block,
  editing a dotfile, etc. Validates with a dry-run
  `darwin-rebuild build`, commits on success. The user still runs
  `danix-switch`.
- **`danix-vim`** (`dotfiles/danix-vim-prompt.md`) — same shape as
  `danix-add`, but scoped to the neovim (nixvim) config under
  `./davim/`. Use this for plugin/keymap/LSP changes. Commits in
  this repo; user runs `danix-switch`.
- **`danix-ask`** (`dotfiles/danix-ask-prompt.md`) — **read-only**
  Q&A about the setup (what's installed, what keybindings exist,
  where something is configured). Does not edit, does not commit.
- **`danix-pi`** (`dotfiles/danix-pi-prompt.md`) — designs and adds
  Pi addons managed by this flake. Covers three shapes: a **skill**
  (`dotfiles/pi/skills/<name>/SKILL.md`), a **prompt template**
  (`dotfiles/pi/prompts/<name>.md`), or **general Pi config** (the
  `piSettings` attrset in `modules/home-manager/pi.nix`, e.g.
  `theme`, `defaultModel`, declarative `packages` list). Walks the
  user through design, writes files, dry-run-builds, commits. The
  user runs `danix-switch`. Pi *extensions* (TS files) and adding
  brand-new manually-wrapped packages are explicitly out of scope.

If you (a future agent or human) add a new convention to this file
or introduce a new "shape" of change one of these helpers should know
how to handle, also update the relevant prompt under `dotfiles/` so
the helper stays in sync. In particular: any new fact about *where*
config lives (a new dotfile, a new module, a new subtree) belongs in
`danix-ask-prompt.md` so the read-only helper can find it.

Adding a wholly new manually-wrapped package is explicitly out of
scope for `danix-add` (that ritual stays a human task; the
`danix-update` flow then maintains it). New nixvim plugins, by
contrast, *are* in scope for `danix-vim`.
