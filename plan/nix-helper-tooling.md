# Nix helper tooling

Follow-up tasks spun out of the portability audit (now archived). Two
related-but-independent ideas to make day-to-day Nix config changes
faster and to corral the growing pile of `nix*` helper aliases.

---

## TASK-001: `danix-add` — agentic "make a nix change" helper

**Status:** COMPLETE

**Goal:** A one-shot helper that takes a free-form description of a
desired change to this flake (e.g. "install ripgrep-all", "switch
starship to the gruvbox preset", "bump my git aliases to add `git
lol`") and drives a Pi session through making, validating, and
committing the change. Mirrors the structure of `nixupdate-wrapped`
but is initiated from a free-form prompt rather than running a fixed
recipe.

**User flow:**
1. User runs `danix-add` (from anywhere, inside zellij).
2. A zellij **floating pane** opens with a prompt asking what change
   they want to make. (For v1 this can just be the Pi TUI itself,
   started with no initial prompt; the user types their request as
   the first message. v2 could pre-prompt with `read` in a wrapper
   and then hand the captured string off to Pi as the initial user
   message — TBD which is nicer.)
3. Pi runs with a system prompt that:
   - Tells it where the repo is (`~/.config/dave_nix/repo-path`,
     same mechanism `_nixupdate_wrapped_run` uses).
   - Lists the conventions: PII goes through `private.nix`,
     manually-wrapped packages live in the WRAPPED PACKAGES region,
     `home.packages` is the usual place for a new tool, etc. (Crib
     from `dave_nix/CLAUDE.md` rather than restating.)
   - Tells it to validate the change with a dry-run build *before*
     declaring success — see "Validation" below.
   - Forbids running `darwin-rebuild switch` / `nixswitch` itself
     (same rule as `nixupdate-wrapped`); the user runs `nixswitch`.
   - On success, instructs it to `git add` any new files and produce
     a `git commit` with a sensible message describing the change.
   - On failure, leaves the working tree as-is and reports clearly
     what broke so the user can intervene.
4. Final terminal output: a short summary of what was changed, the
   commit hash (or "no commit — build failed"), and a prompt to run
   `nixswitch`.

**Validation (dry-run nixswitch equivalent):**
The `nixswitch` alias today runs
`sudo darwin-rebuild switch --flake ${repoPath}#default --impure`.
For dry-run we want to *evaluate and build* the new system without
activating it and without `sudo`. Options to investigate, in
preference order:
- `darwin-rebuild build --flake ${repoPath}#default --impure` — builds
  the system closure into `./result` without activating. Closest
  analogue to `nixos-rebuild build`. **Verify this subcommand exists
  on the version of nix-darwin we're pinned to** before relying on it.
- `nix build ${repoPath}#darwinConfigurations.default.system --impure`
  — fallback if `darwin-rebuild build` isn't available; same effect.
- `darwin-rebuild check` / `--dry-run` — only evaluates, doesn't
  build. Cheaper but won't catch fetch/hash failures, so prefer a
  real build.

The agent should run whichever of these we settle on, parse the
exit code, and only proceed to the commit step on success. The
floating pane should stay open long enough for the user to read the
result.

**Implementation sketch:**
- New shell alias `danix-add` in `modules/home-manager/default.nix`
  `shellAliases`, modelled on `nixupdate-wrapped`:
  - If inside zellij: `zellij run --floating --name danix-add -- zsh -ic _danix_add_run`.
  - Otherwise: run `_danix_add_run` inline.
- New worker function `_danix_add_run` in `dotfiles/zshrc`, modelled
  on `_nixupdate_wrapped_run`:
  - `cd` to `repo-path`, `op run` to inject `ANTHROPIC_API_KEY`,
    invoke `pi --thinking medium "$(cat
    ~/.config/dave_nix/danix-add-prompt.md)"`.
- New prompt file `dotfiles/danix-add-prompt.md` deployed to
  `~/.config/dave_nix/danix-add-prompt.md` via `home.file` (same
  pattern as `nix-update-wrapped-prompt.md`). Contents per "Pi runs
  with a system prompt that..." above. Crucially, it must instruct
  the agent to **read the user's request from stdin / next message**
  rather than embedding a fixed task.
- Remember to `git add` the new prompt file before the first
  `nixswitch` (per repo rules in `CLAUDE.md`).

**Open questions:**
- Should v1 take the change description as a CLI argument
  (`danix-add "install ripgrep-all"`) and pass it as the initial
  user message to Pi, or always drop into an interactive Pi session?
  Argument form is faster for one-liners; interactive is friendlier
  for vague requests. Possibly support both: positional arg ⇒
  initial message, no arg ⇒ interactive.
- Commit policy: always commit on success, or stage-only and let the
  user review? Lean towards commit, since the user can always
  `git reset --soft HEAD^` if they dislike the message. The diff
  will already have been reviewed implicitly via the dry-run build
  output and the fact that they're about to run `nixswitch`.
- How big a change is in scope? Keep it to "things that fit in one
  Pi turn or two": adding a package, tweaking config, simple module
  edits. Not: introducing a whole new manually-wrapped package
  (that's still a human job, and `nixupdate-wrapped` then maintains
  it). The prompt should say so.

---

## TASK-002: `danix` launcher TUI + rename existing helpers

**Status:** PENDING

**Goal:** One muscle-memory command (`danix`) that lists the
nix-related helpers and runs the chosen one. Plus, rename the
existing helpers so they share a common `danix-*` prefix and drop
incidental suffixes like `-wrapped`.

**Proposed renames:**

| Today              | Proposed         | Notes |
|--------------------|------------------|-------|
| `nixswitch`        | `danix-switch`   | The big one — used constantly. Keep `nixswitch` as an alias for a transition period? Probably yes for a release or two, then drop. |
| `nixup`            | `danix-up`       | `flake update` + switch. |
| `nixupdate-wrapped`| `danix-update`   | Drops `-wrapped`; the "wrapped packages" framing is internal jargon. The thing the user cares about is "update my pinned tools". |
| (new, TASK-001)    | `danix-add`      | Already named this way in TASK-001. |
| (new, this task)   | `danix`          | Top-level launcher. |

**Launcher behaviour (`danix` with no args):**
- Pop a menu of available subcommands with one-line descriptions.
- Selecting one runs it in the current shell (so `danix-switch` can
  still prompt for sudo, `danix-add` can still spawn its zellij
  floating pane, etc.).
- Implementation candidates, cheapest-first:
  - **`fzf` menu**: a small zsh function that pipes a hand-curated
    list of `name<TAB>description` lines into `fzf --with-nth=1
    --delimiter=$'\t'` and execs the chosen name. ~10 lines, no new
    deps (fzf is already enabled). Probably the right answer.
  - **`gum choose`** (charmbracelet) — prettier, but adds a package
    just for this.
  - A bespoke Pi-style TUI — overkill.
- `danix <name>` with an arg should skip the menu and run that
  subcommand directly, so it composes with shell history.

**Implementation notes:**
- Define the menu list in **one** place — likely as a zsh
  associative array in `dotfiles/zshrc` keyed by subcommand name,
  values are descriptions. The `danix` function reads from this
  array; adding a new helper means adding one line.
- Each `danix-*` helper stays a separate `shellAliases` entry (or
  function, where aliases are too constrained — see `nixswitch`'s
  multi-line body today). The launcher just dispatches by name via
  `eval` or by invoking the alias in a fresh `zsh -ic` (TBD which
  preserves sudo / interactive-ness best; `nixswitch` needs to be
  able to prompt for the sudo password).

**Migration / compatibility:**
- Keep the old names (`nixswitch`, `nixup`, `nixupdate-wrapped`) as
  thin aliases pointing at the new ones for at least one
  `nixswitch` cycle. Add a one-line deprecation echo to each so the
  user retrains muscle memory. Remove after a couple of weeks of
  not tripping over them.
- Update README + `CLAUDE.md` references (`CLAUDE.md` mentions
  `nixswitch` and `nixupdate-wrapped` in several places — grep
  before merging).
- Update `dotfiles/nix-update-wrapped-prompt.md`: the file name can
  stay (internal), but any user-facing strings in it that say
  "`nixupdate-wrapped`" or "`nixswitch`" should be updated to the
  new names.

**Dependency on TASK-001:**
None, strictly — but if TASK-001 lands first under the name
`danix-add`, this task picks it up for free. If TASK-002 lands
first, TASK-001 should be implemented under the new naming
scheme directly. Either order is fine.

**Open questions:**
- Bikeshed: `danix` vs `dnix` vs `dn`? `danix` is the most
  searchable / least likely to collide with anything. Sticking
  with it unless someone has a strong objection.
- Do we want the launcher to also surface non-`danix-*` nix-y
  things (e.g. `nix flake update`, `nix-collect-garbage -d`)?
  Probably not in v1 — keep it scoped to "things I wrote", let
  upstream Nix commands stay upstream.
