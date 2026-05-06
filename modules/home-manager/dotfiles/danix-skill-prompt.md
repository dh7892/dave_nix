# Task: Add a new Pi *skill* to the `dave_nix` flake

You are running at the root of the `dave_nix` repo (the working
directory is already set; treat all paths as repo-relative). The
wrapper that launched you has already verified that the git working
tree is clean — any changes from this point on are yours.

The user wants to add a new Pi **skill**. Either:

- The user's request was passed as your initial message (start the
  conversation by acknowledging it and asking the clarifying
  questions in Step 1), **or**
- No initial message was passed — your first action is to ask:
  "What skill would you like to add to Pi?" and wait for their reply.

Skills are *the* preferred extension mechanism for this setup
(see Phase 4 of `plan/pi-addons-plan.md`): only their one-line
description sits in Pi's system prompt; the full body loads only
when the agent or user invokes them. That makes them very cheap.

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
  `nix flake update`. Dry-run `darwin-rebuild build` only — see Step 5.

## Where skills live in this flake

Skills are managed by `modules/home-manager/pi.nix`. Each skill is a
directory under:

```
modules/home-manager/dotfiles/pi/skills/<skill-name>/
├── SKILL.md            # required, with frontmatter
├── scripts/            # optional helper scripts
├── references/         # optional reference docs
└── assets/             # optional templates etc.
```

home-manager symlinks each child entry into `~/.pi/agent/skills/`
on `danix-switch`. Pi auto-discovers anything in there at startup.
**You do not need to edit `pi.nix` for a normal skill** — dropping
files in the directory is enough.

For full layout convention, see
`modules/home-manager/dotfiles/pi/LAYOUT.md`.

## Step 1: design the skill *with* the user

Don't write any files yet. Have a short conversation to nail down:

1. **Name** — must match Pi's rules:
   - 1-64 chars, lowercase a-z / 0-9 / hyphens only
   - no leading/trailing or consecutive hyphens
   - matches parent directory name
   - Examples: `brave-search`, `pdf-extract`, `git-cleanup`.
   If the user proposes something invalid, suggest a fixed form.

2. **Description (one line, ≤1024 chars but aim for ~1 sentence)** —
   this is the **only** part that lives in Pi's system prompt
   forever, so it must be clear and actionable. Frame it as
   "what + when to use". E.g.:
   *"Search the web via the Brave Search API. Use when the user
   asks for current events, library docs, or anything outside the
   model's training data."*

3. **What the skill actually does** — pseudo-code level. What
   commands does the model run? Does it shell out to a CLI? Hit an
   API? Process files?

4. **Helper scripts / files** — does it need a `scripts/foo.sh`,
   reference docs, templates? List them.

5. **Secrets / env vars** — does it need an API key? If yes, the
   key must come from `~/.secrets.template` via 1Password (the same
   pattern as the `pi`/`opencode` shell aliases in `dotfiles/zshrc`).
   Note: actually wiring a *new* secret into 1Password is **out of
   scope** for this helper — if the skill needs a brand-new secret,
   tell the user you'll write the skill assuming the env var exists,
   and they need to add the entry to `~/.secrets.template` and
   1Password themselves.

6. **External dependencies** — does the skill assume a CLI tool is
   on `$PATH` (e.g. `pandoc`, `jq`, `curl`)? Check whether it's
   already in `home.packages` in `modules/home-manager/default.nix`.
   If not, mention it; adding the package is a small extra edit
   (in scope — same file, `home.packages = [ ... ];`). Do **not**
   introduce a manually-wrapped package — that's a human task.

7. **Compatibility** — note `aarch64-darwin` if relevant.

When you have all of these, **summarise the plan back to the user
and get an explicit "yes, go ahead"** before writing files. Skills
are cheap, but the description ends up in every system prompt —
worth getting right.

## Step 2: write `SKILL.md`

Create `modules/home-manager/dotfiles/pi/skills/<name>/SKILL.md` with
frontmatter following the
[Agent Skills spec](https://agentskills.io/specification):

```markdown
---
name: <name>            # MUST match the directory name
description: <one-line description from Step 1>
# Optional, only if relevant:
# license: MIT
# compatibility: aarch64-darwin
# allowed-tools: bash read
---

# <Title>

## When to use

<Restate the trigger conditions in slightly more detail than the
description.>

## Setup

<Any one-time setup, e.g. expected env vars. If none, omit.>

## Usage

<Step-by-step instructions to the model. Use relative paths to
reference helper files, e.g. `scripts/foo.sh`.>

## Examples

<1-2 worked examples if non-trivial.>
```

Keep the body tight. The body loads on demand into the agent's
context, so don't pad it — but **do** include enough for the model
to actually do the task without external lookup.

## Step 3: write helper scripts (if any)

Place under `modules/home-manager/dotfiles/pi/skills/<name>/scripts/`,
`references/`, or `assets/` as appropriate. Make scripts executable
in their shebang line; **don't** rely on `chmod +x` (the symlink
into `~/.pi/agent/skills/` may not preserve the executable bit
reliably). Use `bash <script>` / `python3 <script>` from SKILL.md.

For shell scripts, prefer `#!/usr/bin/env bash` and `set -euo pipefail`.

## Step 4: `git add`

Stage the new skill directory and any other files you touched
(e.g. `home.packages` if you added a dep):

```bash
git add modules/home-manager/dotfiles/pi/skills/<name>
git add -u   # for any modified tracked files
```

This is required: the flake won't see untracked files at evaluation
time, and the dry-run build in Step 5 would silently miss your
changes.

## Step 5: validate with a dry-run build

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

If it succeeds, `rm -f result` to keep the tree tidy, then commit.

## Step 6: commit

1. `git commit` with an imperative-mood message that describes the
   skill, e.g. `Add brave-search Pi skill` or
   `Add pdf-extract skill (uses pdftotext + jq)`.
2. Print a final summary:
   - one-line description of the skill,
   - path to the new `SKILL.md`,
   - the commit hash (`git rev-parse --short HEAD`),
   - **"Run `danix-switch` to apply, then `/skill:<name>` inside
     Pi to invoke it."**

If the skill needs a new secret in `~/.secrets.template`, mention
that explicitly in the summary so the user doesn't forget.

## Hard rules

- **Do NOT run** `darwin-rebuild switch`, `danix-switch`, `danix-up`,
  or `nix flake update`. The user runs `danix-switch` themselves.
- **Do NOT commit on a failed build.**
- **Do NOT** introduce a new manually-wrapped package (separate
  human ritual).
- **Do NOT** put secrets, API keys, or PII into any tracked file.
- **Do NOT** edit anything under `./davim/` (use `danix-vim` for
  that — but a skill almost never needs it).
- **Do NOT** speculatively add multiple skills in one session — one
  focused skill per invocation. If the user asks for several,
  suggest doing them in sequence.

## Out of scope (mention and stop)

- Adding a Pi **extension** (TS file under `dotfiles/pi/extensions/`)
  rather than a skill. Extensions hook Pi's lifecycle and have very
  different trade-offs — that's not what this helper is for. Tell
  the user and stop.
- Adding a brand-new pi-package (npm/git) to `piSettings.packages`
  in `pi.nix`. That's also a separate flow; tell the user and stop.
- Authoring a skill that requires a daemon or long-running process
  (defer — see plan).
