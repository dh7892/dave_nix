# Task: Make a change to the Neovim (davim) config

You are running at the root of the `dave_nix` repo. The neovim
configuration lives in the `./davim/` subtree as a `path:./davim`
flake input — i.e. it is part of *this* repo, no second clone, no
`nix flake update` round-trip. Edits to files under `./davim/` are
picked up directly by the next `darwin-rebuild build`.

The wrapper that launched you has already verified that the git
working tree is clean, so any changes from this point on are yours.

The user wants to make some change to neovim — adding a plugin,
tweaking a keymap, configuring an LSP, etc. Either:

- The user's request was passed as your initial message (start
  working on it immediately, asking clarifying questions only if
  genuinely ambiguous), **or**
- No initial message was passed, in which case your first action is
  to ask the user "What change would you like to make to the neovim
  config?" and wait for their reply.

## Step 1: orient yourself in davim

`davim/CLAUDE.md` and `davim/README.md` describe its layout. Quick
map:

- `davim/flake.nix` — flake entry, builds nixvim.
- `davim/config/default.nix` — main config: leader key (`,`),
  colorscheme, top-level `keymaps`, imports of plugin modules.
- `davim/config/<plugin>.nix` — per-plugin config (telescope, lsp,
  treesitter, dap, avante, …).
- All config is Nix (nixvim DSL), with `extraConfigLua` for raw Lua
  snippets when needed.

Also load `dave_nix`'s top-level `CLAUDE.md` conventions (PII via
`private.nix`, git-add-before-switch, no-`darwin-rebuild-switch`,
etc.) — they apply here too.

## Step 2: scope guardrails

You are **in scope** for edits under `./davim/` only:

- Adding/removing/configuring nixvim plugins.
- Adding/changing keymaps.
- LSP / DAP / treesitter / formatter tweaks.
- Small Lua snippets via `extraConfigLua`.

You are **out of scope** for:

- Edits outside `./davim/` (use `danix-add` for those).
- Bumping `davim/flake.lock` inputs (that's a `nix flake update`
  job, not yours).
- Anything that would require a new manually-wrapped package in
  `dave_nix`'s WRAPPED PACKAGES region (human task).

If the request straddles davim and the rest of dave_nix, do the
davim part here and tell the user to run `danix-add` for the rest.

## Step 3: make the change

- Prefer the nixvim DSL over raw Lua when an option exists for it.
- Match the existing style of neighbouring plugin files
  (`davim/config/telescope.nix`, `which-key.nix`, etc.).
- For new plugins, check whether nixvim has first-class support
  (`programs.nixvim.plugins.<name>.enable = true;`) before falling
  back to `extraPlugins`.
- New keymaps go in the `keymaps` list in `davim/config/default.nix`
  unless they're tightly coupled to a specific plugin module.
- New files under `davim/` must be `git add`ed (Nix only sees
  git-tracked files in a flake).

## Step 4: validate with a dry-run build

Build the whole system closure — this exercises davim end-to-end as
the system actually consumes it (no separate `nix build ./davim`
needed):

```
darwin-rebuild build --flake "$(cat ~/.config/dave_nix/repo-path)#default" --impure
```

Fallback if `darwin-rebuild build` is unavailable:

```
nix build "$(cat ~/.config/dave_nix/repo-path)#darwinConfigurations.default.system" --impure
```

If the build fails:
- Leave the working tree as-is (do **not** revert).
- Do **not** commit.
- Print a clear summary of what broke (relevant error lines, file
  and line they point at) so the user can take over.
- Stop.

If it succeeds, `rm -f result` to keep the tree tidy, then proceed.

## Step 4b: prefer ad-hoc `nix shell` for end-to-end testing

A passing dry-run build only proves the config *evaluates*; it does
not prove neovim actually starts and the plugin/keymap behaves.
**Do not** suggest the user run `danix-switch` just to try the
change — a full switch is slow, can prompt for sudo / 1Password,
and is risky on a git worktree. Instead, point them at an isolated
shell that runs the freshly-built davim:

```
nix run "$(cat ~/.config/dave_nix/repo-path)#davim"
```

or, equivalently:

```
nix shell "$(cat ~/.config/dave_nix/repo-path)#davim" -c nvim
```

If the change under test depends on env vars rendered by
home-manager via 1Password (e.g. an LSP / AI plugin reading
`OPENAI_API_KEY` / `ANTHROPIC_API_KEY`), wrap the invocation in
`op run` so secrets get injected:

```
op run --env-file=<file> -- nix run "$(cat ~/.config/dave_nix/repo-path)#davim"
```

## Step 5: commit

On a successful build, from the `dave_nix` repo root:

1. `git add` any new files and modified files you touched
   (everything is in *this* repo now, including `./davim/`).
2. `git commit` with a concise, descriptive message in the
   imperative mood that reflects the **actual change**, not the
   user's literal request. Prefix with `davim:` to make the
   subtree affiliation obvious. e.g.
   - "install telescope-fzf-native" → `davim: add telescope-fzf-native plugin`
   - "make ,gs open lazygit" → `davim: bind ,gs to lazygit`
3. Print a final summary:
   - one-line description of what changed,
   - the commit hash (`git rev-parse --short HEAD`),
   - the `nix run …#davim` (or `op run -- nix run …#davim`)
     one-liner the user can use to try it *now* without committing
     to a full switch,
   - the reminder: **"Run `danix-switch` once you're happy with it to make it permanent."**

## Hard rules

- **Do NOT run** `darwin-rebuild switch`, `danix-switch`, `danix-up`,
  or `nix flake update`. The user runs `danix-switch` themselves.
- **Do NOT commit on a failed build.**
- **Do NOT** edit files outside `./davim/`.
- **Do NOT** modify `davim/flake.lock`.
