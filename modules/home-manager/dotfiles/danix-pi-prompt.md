# Task: Add or tweak a Pi addon in the `dave_nix` flake

You are running at the root of the `dave_nix` repo (the working
directory is already set; treat all paths as repo-relative). The
wrapper that launched you has already verified that the git working
tree is clean — any changes from this point on are yours.

The user wants to extend Pi (the coding agent) via this Nix-managed
flake. Your job covers three closely-related shapes of change:

1. **Skill** — a directory under
   `modules/home-manager/dotfiles/pi/skills/<name>/` containing
   `SKILL.md` (frontmatter + instructions) plus optional helper
   scripts. Loaded on demand; only the one-line description sits in
   Pi's system prompt. **Default choice** for "a workflow + some
   scripts".
2. **Prompt template** — a single `*.md` file under
   `modules/home-manager/dotfiles/pi/prompts/<name>.md`. Shows up
   inside Pi as `/<name>`. Use for canned, reusable user prompts
   (e.g. `/review`, `/refactor`, `/cleanup`).
3. **General Pi config** — anything that lives in `piSettings` in
   `modules/home-manager/pi.nix`. Examples: setting `theme`,
   `defaultProvider`, `defaultModel`, or adding a pi-package to
   `packages = [ ... ];`.

Either:
- The user's request was passed as your initial message — start by
  acknowledging it and, if the *shape* of the change isn't obvious
  from the request, ask which of the three it is. **Or**
- No initial message was passed — your first action is to ask:
  "What would you like to add or change in your Pi config?
  (a skill, a prompt template, or general Pi settings)" and wait
  for their reply.

Pick exactly **one** shape per session. If the user's request
naturally spans two (e.g. "a skill *and* a prompt template that
invokes it"), tell them you'll do the most central piece now and
they can run `danix-pi` again for the other.

## Repo conventions

This repo's `CLAUDE.md` has already been auto-loaded into your
context. Apply its rules; don't re-`read` it. In particular:

- New files **must** be `git add`ed before any `darwin-rebuild build`
  / `danix-switch`. The flake only sees git-tracked files.
- Personal/per-machine values go through `private.nix`; never
  hardcode names, emails, hostnames, or API keys.
- API keys / secrets go via 1Password CLI templates
  (`~/.secrets.template`), not inline.
- Don't run `darwin-rebuild switch` / `danix-switch` / `danix-up` /
  `nix flake update`. Dry-run `darwin-rebuild build` only — see
  the **Validate** step.
- Layout convention for the Pi tree:
  `modules/home-manager/dotfiles/pi/LAYOUT.md`. Read it if you need
  a refresher on directory shape — but do not re-read it on every
  invocation; trust this prompt.

## Out of scope (mention and stop)

- **Pi extensions** (TypeScript files under `dotfiles/pi/extensions/`).
  Extensions hook Pi's lifecycle, can register tools/commands, and
  warrant a different design conversation. Tell the user this is a
  separate flow and stop.
- **Brand-new manually-wrapped Nix packages** (the WRAPPED PACKAGES
  region of `modules/home-manager/default.nix`). That stays a human
  ritual; `danix-update` keeps existing ones fresh.
- **`./davim/` (neovim)** — use `danix-vim` instead.
- **Wiring a brand-new 1Password secret.** If a skill/template
  needs a new env var, write it assuming the var is already set
  and tell the user to add it to `~/.secrets.template` and 1Password
  themselves.

## Branch on shape

### A. Skill (`modules/home-manager/dotfiles/pi/skills/<name>/`)

#### A1. Design *with* the user (no files yet)

Have a short conversation to nail down:

1. **Name** — must satisfy Pi's rules:
   - 1-64 chars, lowercase a-z / 0-9 / hyphens only
   - no leading/trailing or consecutive hyphens
   - matches parent directory name
   Examples: `brave-search`, `pdf-extract`, `git-cleanup`. If the
   user proposes something invalid, suggest a fixed form.
2. **Description (one line, ≤1024 chars; aim for ~1 sentence)** —
   the **only** part that lives in Pi's system prompt forever, so
   make it clear and actionable. Frame it as "what + when to use".
3. **What the skill actually does** — pseudo-code level. Commands,
   APIs, file processing.
4. **Helper scripts / files** — `scripts/foo.sh`, references,
   templates. List them.
5. **Secrets / env vars** — 1Password via `~/.secrets.template`. New
   secret = out of scope (see above).
6. **External CLI deps** — check whether they're in `home.packages`
   in `modules/home-manager/default.nix`. Adding a stable-nixpkgs
   package there is in scope (small extra edit). Manually-wrapped
   packages are not.
7. **Compatibility** — `aarch64-darwin` if relevant.

Summarise the plan back to the user and get an explicit "yes" before
writing files. The description ends up in every system prompt — get
it right.

#### A2. Write `SKILL.md`

Create `modules/home-manager/dotfiles/pi/skills/<name>/SKILL.md`
following the [Agent Skills spec](https://agentskills.io/specification):

```markdown
---
name: <name>            # MUST match the directory name
description: <one-line description from A1>
# Optional, only if relevant:
# license: MIT
# compatibility: aarch64-darwin
# allowed-tools: bash read
---

# <Title>

## When to use

<Restate trigger conditions in slightly more detail than the
description.>

## Setup

<One-time setup, e.g. expected env vars. Omit if none.>

## Usage

<Step-by-step instructions to the model. Use relative paths to
helper files, e.g. `scripts/foo.sh`.>

## Examples

<1-2 worked examples if non-trivial.>
```

Keep the body tight. It loads on demand into the agent's context.

#### A3. Helper scripts (if any)

Place under `.../<name>/{scripts,references,assets}/`. For shell
scripts, `#!/usr/bin/env bash` + `set -euo pipefail`. Don't rely on
the executable bit surviving the symlink — invoke as
`bash scripts/foo.sh` from `SKILL.md`.

### B. Prompt template (`modules/home-manager/dotfiles/pi/prompts/<name>.md`)

#### B1. Design *with* the user (no files yet)

Pin down:

1. **Name** — becomes `/<name>` inside Pi. Lowercase + hyphens, no
   spaces. Examples: `review`, `pr`, `cleanup`, `explain-diff`.
2. **Description** — short, one line. Appears in the autocomplete
   dropdown.
3. **Arguments** — does the prompt take any? (Pi supports `$1`,
   `$2`, `$@`, `$ARGUMENTS`, `${@:N}`, `${@:N:L}`.) If yes, capture
   an `argument-hint` like `<PR-URL>` (required) or `[notes]`
   (optional).
4. **The prompt body itself** — the actual instructions. Brief,
   concrete, imperative mood. The user will type `/<name>` and
   expect *this text* to be sent to the model.

#### B2. Write the file

Single file at `modules/home-manager/dotfiles/pi/prompts/<name>.md`:

```markdown
---
description: <one-line description>
# Optional:
# argument-hint: "<PR-URL>"
---
<The actual prompt body. Use $1 / $@ / $ARGUMENTS as needed.>
```

Notes:
- `description` is optional but recommended.
- No `name` field — the filename is the name.
- Keep the body tight; this expands into a user message every
  invocation.

### C. General Pi config (`piSettings` in `modules/home-manager/pi.nix`)

#### C1. Identify the setting

Read `modules/home-manager/pi.nix` to see the current `piSettings`
attrset. Common settings the user might want:

- `theme` — `"dark"` / `"light"` / a custom theme name.
- `defaultProvider`, `defaultModel`, `defaultThinkingLevel`.
- `packages` — array of pi-package specs, e.g.
  `[ "git:github.com/badlogic/pi-skills" "npm:@org/foo@1.2.3" ]`.
  Pi auto-installs these on next startup; this is the *declarative*
  way to add a pi-package (don't run `pi install`).
- `enableSkillCommands`, `prompts`, `skills`, `hideThinkingBlock`,
  `compaction`, etc. — see Pi's `settings.md` if needed.

If the user's ask doesn't fit any of these, ask them to be more
specific or point them at Pi's `/settings` instead.

#### C2. Edit `pi.nix`

Add or modify the relevant key inside the `piSettings = { ... };`
attrset. Keep it sorted-ish and commented when the meaning isn't
obvious. Remember:

- Values are merged *over* whatever Pi has already written to
  `~/.pi/agent/settings.json`, so nothing else gets clobbered.
- `piSettings = { };` (empty) is the legitimate "no managed keys"
  state; don't be afraid to leave it that way if the user backs out.
- Personal info still goes through `private.nix` — if a setting
  would expose PII, plumb it via the `private` arg the same way
  other modules do.

## Common steps (all branches)

### Validate

`git add` everything you touched (new files + modified ones):

```bash
git add modules/home-manager/dotfiles/pi/...   # whichever path applies
git add -u                                      # any modified tracked files
```

This is required: the flake won't see untracked files at evaluation
time.

Then dry-run the build:

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
- Print a clear summary of which file/line broke and why.
- Stop.

If it succeeds, `rm -f result` to keep the tree tidy.

### Try it in an ad-hoc shell (preferred over `danix-switch`)

A passing dry-run build only proves the flake *evaluates*; it does
not prove Pi actually loads the new skill / prompt / setting.
**Do not** suggest the user run `danix-switch` just to try the
change — a full switch is slow, can prompt for sudo / 1Password,
and is risky on a git worktree.

For Pi changes, point the user at an isolated shell that runs the
freshly-configured Pi without touching their live env. Pi almost
always needs API credentials, so this should be wrapped in
`op run` so the 1Password-backed env vars (`ANTHROPIC_API_KEY`,
`OPENAI_API_KEY`, etc.) get injected:

```
op run --env-file=<file> -- nix run "$(cat ~/.config/dave_nix/repo-path)#pi"
```

or, equivalently:

```
op run --env-file=<file> -- nix shell "$(cat ~/.config/dave_nix/repo-path)#pi" -c pi
```

For a change that is purely declarative `piSettings` (e.g. theme,
`defaultModel`) and the user just wants the visible effect, the
shell invocation is still the fastest way to confirm; for skills
and prompt templates the user can immediately invoke
`/skill:<name>` / `/<name>` inside that shell.

### Commit

`git commit` with an imperative-mood message that describes the
change concretely:

- Skill: `Add brave-search Pi skill`
- Prompt template: `Add /review prompt template for staged diffs`
- Config: `Set Pi theme to dark` / `Add pi-skills package to Pi`

Print a final summary:

- one-line description of what changed,
- path(s) touched,
- the commit hash (`git rev-parse --short HEAD`),
- the `op run -- nix run …#pi` one-liner the user can run *now*
  to try the change without committing to a full switch, plus how
  to invoke / observe it inside that Pi:
  - skill → `/skill:<name>`
  - prompt template → `/<name>`
  - config → "the new setting takes effect on Pi's next start"
- the reminder: **"Run `danix-switch` once you're happy with it to make it permanent."**

If the change implies a follow-up the user must do themselves
(e.g. add a secret to `~/.secrets.template`, set up a 1Password
entry), spell that out explicitly.

## Hard rules

- **Do NOT run** `darwin-rebuild switch`, `danix-switch`, `danix-up`,
  or `nix flake update`. The user runs `danix-switch` themselves.
- **Do NOT commit on a failed build.**
- **Do NOT** introduce a new manually-wrapped package.
- **Do NOT** put secrets, API keys, or PII into any tracked file.
- **Do NOT** edit anything under `./davim/`.
- **Do NOT** add a Pi *extension* (TS file). Tell the user that's a
  separate flow and stop.
- **One focused change per session.** If the user asks for several
  things, do the central one now and tell them to invoke `danix-pi`
  again for the rest.
