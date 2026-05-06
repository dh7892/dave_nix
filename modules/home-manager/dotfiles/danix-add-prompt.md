# Task: Make a change to the `dave_nix` flake

You are running at the root of the `dave_nix` repo (the working directory
is already set for you; treat all paths as repo-relative). The wrapper
that launched you has already verified that the git working tree is
clean, so any changes from this point on are yours.

The user wants to make some change to this flake — adding a package,
tweaking a config, editing a module, etc. Either:

- The user's request was passed as your initial message (start working
  on it immediately, asking clarifying questions only if genuinely
  ambiguous), **or**
- No initial message was passed, in which case your first action is to
  ask the user "What change would you like to make to dave_nix?" and
  wait for their reply.

## Step 1: apply the repo conventions

This repo's `CLAUDE.md` has already been loaded into your context
(Pi auto-discovers it). It is the single source of truth for the
conventions here — PII via `private.nix`, the WRAPPED PACKAGES
region, git-add-before-danix-switch, the no-`darwin-rebuild` rule, etc.
Apply those rules; do not re-`read` the file. You don't need to
restate them back to the user.

## Step 2: make the change

- Most "install tool X" requests resolve to adding a package to
  `home.packages` in `modules/home-manager/default.nix`. Prefer
  `pkgs.<name>` (stable nixpkgs) unless there's a clear reason to
  reach for `pkgs-unstable`.
- Config tweaks usually live under `programs.*` in the same file or
  in a dotfile under `modules/home-manager/dotfiles/`.
- System-level (nix-darwin) changes go in `modules/darwin/default.nix`.
- Personal/per-machine values go through `private.nix` — never inline
  them. If the change requires a new field, add it to
  `private.nix.example` with a placeholder, plumb it through, and tell
  the user to set the real value in their
  `~/.config/dave_nix/private.nix` before the next `danix-switch`.
- New files must be `git add`ed (Nix only sees git-tracked files in a
  flake).

## Step 3: scope guardrails

You are **in scope** for: adding a package, tweaking a `programs.*`
block, small module edits, adding/editing a dotfile, adding a single
shell alias, small `private.nix.example` additions.

You are **out of scope** for:

- Introducing a new manually-wrapped package inside the WRAPPED
  PACKAGES region (that's a human task — the hash-pinning ritual is
  finicky and the `danix-update` flow then owns keeping it fresh).
  If the user's request requires a new wrapped package, explain that
  briefly and stop without editing files.
- **Neovim / davim changes.** The neovim config lives in this repo
  under `./davim/` (a `path:./davim` flake input) and has its own
  dedicated helper, `danix-vim`, with conventions tuned for nixvim.
  If the user's request is about adding/configuring a nvim plugin,
  changing a nvim keymap, tweaking LSP/DAP/treesitter, etc., tell
  them to run `danix-vim` instead and stop without editing files.
  (Edits that touch *both* davim and the rest of dave_nix: do the
  non-davim half here and tell the user to run `danix-vim` for the
  rest.)

If the request is ambiguous or seems larger than one or two focused
edits, ask the user before charging ahead.

## Step 4: validate with a dry-run build

Before committing, run a dry-run build to catch evaluation, fetch, and
hash errors:

```
darwin-rebuild build --flake "$(cat ~/.config/dave_nix/repo-path)#default" --impure
```

This builds the system closure into `./result` **without** activating
it and **without** `sudo`. If `darwin-rebuild build` is unavailable on
this machine's nix-darwin, fall back to:

```
nix build "$(cat ~/.config/dave_nix/repo-path)#darwinConfigurations.default.system" --impure
```

If the build fails:
- Leave the working tree as-is (do **not** revert — the user may want
  to inspect or fix it).
- Do **not** commit.
- Print a clear summary of what broke (the relevant error lines, and
  which file/line they point at) so the user can take over.
- Stop.

If the build succeeds, delete the `./result` symlink (`rm -f result`)
to keep the tree tidy, then proceed to step 5.

## Step 4b: prefer ad-hoc `nix shell` for end-to-end testing

A passing dry-run build only proves the system *evaluates*. It does
not prove the new tool actually runs. **Do not** suggest the user
run `danix-switch` just to try the change — a full switch is slow,
can prompt for sudo / 1Password, and is risky on a git worktree or
mid-iteration. Instead, when the change is something the user can
actually exercise (a new CLI tool, a new wrapped package, a new
shell command), tell them how to spin it up in an isolated shell:

- nixpkgs package: `nix shell nixpkgs#<name>`
- package from this flake: `nix shell "$(cat ~/.config/dave_nix/repo-path)#<name>"`
- runnable app from this flake: `nix run "$(cat ~/.config/dave_nix/repo-path)#<app>" -- <args>`

If the thing under test needs secrets that are normally rendered
into the user's env by home-manager via 1Password (Pi, anything
reading `OPENAI_API_KEY` / `ANTHROPIC_API_KEY` / similar), wrap the
shell in `op run` so the secrets get injected:

```
op run --env-file=<file> -- nix shell "$(cat ~/.config/dave_nix/repo-path)#<name>" -c <cmd>
```

For changes that aren't directly runnable (a `programs.*` tweak, a
shell alias, a dotfile edit), skip this step — just note it can
only really be observed after `danix-switch`.

## Step 5: commit

On a successful build:

1. `git add` any new files (and any modified files you touched).
2. `git commit` with a concise, descriptive message in the imperative
   mood that reflects the **actual change**, not the user's literal
   request. e.g. user says "install ripgrep-all" → commit message
   `Add ripgrep-all to home.packages`.
3. Print a final summary:
   - one-line description of what changed,
   - the commit hash (`git rev-parse --short HEAD`),
   - if applicable, the `nix shell` (or `op run -- nix shell …`)
     one-liner the user can run *now* to try the change without
     committing to a full switch,
   - and the reminder: **"Run `danix-switch` once you're happy with it to make it permanent."**

## Hard rules

- **Do NOT run** `darwin-rebuild switch`, `danix-switch`, `danix-up`, or
  `nix flake update`. The user runs `danix-switch` themselves.
- **Do NOT commit on a failed build.**
- **Do NOT** touch files outside the scope of the requested change.
- **Do NOT** introduce a new manually-wrapped package (see Step 3).
