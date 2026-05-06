# Pi addons — proposal & plan

Status: **draft for review**. Once agreed, each numbered item below becomes a
`TASK-XXX-*.md` under `plan/tasks/pending/` and we work them in order.

## Ground rules (non-negotiable)

1. **Everything goes through Nix.** No `pi install` invocations that mutate
   state outside the flake. Extensions, skills, prompt templates, themes,
   and `settings.json` are all materialised from this repo into
   `~/.pi/agent/` (or `.pi/` for project-local) by home-manager.
   - TS extension files live in `modules/home-manager/dotfiles/pi/extensions/`
     and are linked into `~/.pi/agent/extensions/` via `home.file`.
   - Skills live in `modules/home-manager/dotfiles/pi/skills/<name>/SKILL.md`,
     linked into `~/.pi/agent/skills/`.
   - `settings.json` is generated from a Nix attrset (so the `packages` list
     of npm/git pi-packages is declarative). Pi auto-installs missing
     packages on startup, so a fresh machine just works after `danix-switch`.
   - Anything that needs `npm install` inside an extension directory is
     wrapped as a derivation with pinned version + hash, in the
     `WRAPPED PACKAGES` region of `modules/home-manager/default.nix`,
     following the existing convention.

2. **Lean into Pi's USP: a tiny, clean context window.** Every addition gets
   evaluated against this. Concretely:
   - Prefer **skills** (loaded on demand, only name+description in the
     system prompt) over extensions that inject text every turn.
   - Prefer **one bridge tool** that shells out to a CLI (e.g. one `mcp`
     tool, one `web_search` tool) over many auto-registered tools.
   - Avoid extensions that add `before_agent_start` system-prompt
     injections unless strictly necessary.
   - Anything that adds always-on text to the prompt must justify itself
     in its TASK file.

3. **Portability.** All config must work on a freshly-imaged
   aarch64-darwin machine after a single `danix-switch`. No manual steps,
   no hidden state in `~/.pi` that isn't reproducible.

4. **Per-machine / personal data** (API keys, webhook URLs, phone
   numbers, Slack tokens) goes through `~/.config/dave_nix/private.nix`
   and 1Password CLI, **not** into tracked files. Add new fields to
   `private.nix.example` as we go.

---

## Phase 0 — plumbing (do this first, everything else depends on it)

### TASK: pi-nix-skeleton
Create the directory layout and home-manager wiring so that any future
addon is a one-liner:

- `modules/home-manager/pi.nix` — new module, imported from `default.nix`.
- Generates `~/.pi/agent/settings.json` from a Nix attrset.
- Symlinks `modules/home-manager/dotfiles/pi/extensions/*` →
  `~/.pi/agent/extensions/`.
- Symlinks `modules/home-manager/dotfiles/pi/skills/*` →
  `~/.pi/agent/skills/`.
- Symlinks `modules/home-manager/dotfiles/pi/prompts/*` →
  `~/.pi/agent/prompts/` (for prompt templates).
- Adds a `CLAUDE.md`-style note explaining the layout for future agents.

Acceptance: `pi --list-extensions` (or equivalent) shows zero addons but
the directories exist and are writable-via-flake.

---

## Phase 1 — quick wins (small, high-value, low context cost)

### 0. Subagents (promoted from Phase 3 by Dave's request)
Bundled `subagent/` example. Subagents have their **own** context
window, so the main session stays tiny — strongest possible fit for
Pi's USP. Pattern: "go research X / refactor Y / scan the repo for Z"
is delegated to a subagent that returns a summary, not its full
working memory.

**Plan:** vendor `subagent/` from examples, configure which model it
uses (probably a cheaper/faster model than the main one), and add a
`promptGuidelines` bullet so the LLM knows when to delegate.
Acceptance: a research-style prompt does not bloat the main context
with dozens of `read`/`grep` results.


### 1. Better question UI (your ask #1)
Pi already ships two example extensions that do exactly this:
`questionnaire.ts` (multi-question with tab navigation + selectable
options + free-text "other") and `question.ts` (single question).
The LLM calls a normal tool, the TUI renders selectable options.
**Plan:** copy `questionnaire.ts` into our extensions dir, set
`promptSnippet`/`promptGuidelines` so the model naturally uses it when
it would otherwise ask a wall of questions. No prompt bloat — one tool
description.

### 2. Idle notifications (foundation for your ask #4)
Adopt `notify.ts` — native terminal/OS notification when the agent
finishes and is waiting for input. Works with Ghostty/iTerm2/WezTerm
(OSC 777) and Kitty (OSC 99). Zero context cost.

### 3. Guardrails (no context cost — pure event hooks)
Adopt these example extensions wholesale:
- `confirm-destructive.ts` — confirm `rm -rf`, `sudo`, etc.
- `protected-paths.ts` — block writes to `.env`, `node_modules/`, etc.
  Add our own list: `~/.config/dave_nix/private.nix`, `secrets/`, `*.age`.
- `dirty-repo-guard.ts` — warn before starting work on a dirty repo.
- `git-checkpoint.ts` — auto-stash per turn, easy revert on bad turn.

### 4. Session quality of life
- `session-name.ts` — auto-name sessions from first prompt (better
  `/resume` UX).
- `bash-spawn-hook.ts` — source `~/.profile` for bash tool calls so the
  agent sees the same env we do (zsh aliases, mise, etc.). Worth
  checking it actually helps under our nushell+zsh setup.

---

## Phase 2 — capabilities (your asks #2, #3, #4)

### 5. Web search (your ask #2) — provider-native, command-gated

**Decision (revised):** do *not* ship a Brave skill. Use Anthropic's
provider-native `web_search` tool, gated behind an explicit
user command so it costs **zero context** when not in use.

Background: the bundled `pi-ai` SDK already knows about
Anthropic's `WebSearchTool` / `WebSearchPremiumTool` and Google's
`googleSearch` grounding. These are activated by adding a tool
block to the outgoing request payload — they are not Pi-registered
tools, so they don't appear in the system prompt's tool list.

**Plan:** small Pi extension (`pi-research`) that:
1. Registers `/research <query>` — one-shot: arms a flag for the
   next turn, then `sendUserMessage(query)`.
2. Registers `/research-mode on|off` — sticky toggle for
   multi-turn investigation.
3. Hooks `before_provider_request` — when the flag is set, splices
   Anthropic's `web_search` tool block into `payload.tools` for
   that single request. One-shot flag auto-clears in `turn_end`;
   sticky mode persists until toggled off.
4. Calls `ctx.ui.setStatus("web", "🌐 web search ON")` while
   active, clears it on deactivation.
5. Provider-detection: only injects the tool block when
   `ctx.model.provider === "anthropic"`. For other providers,
   the command surfaces a notify saying "web search not wired up
   for <provider> yet" and exits.

**Cost:** Anthropic charges ~$0.01 per search on top of tokens.
No extra API keys, no Brave/Tavily account. Provider-independent
fallback (Brave skill) is parked as a future option if Dave
ever moves off Anthropic.

**Sub-task — verify SDK access:** before writing the extension,
confirm that `before_provider_request` actually exposes the
Anthropic-shaped payload (i.e. that `pi-ai` hasn't already
normalised it into a provider-agnostic shape that strips unknown
tool types). If it has, fall back to using the SDK's documented
tool-config surface instead of payload mutation.

Acceptance: `/research what's new in Bevy 0.15?` triggers a turn
in which Claude actually fetches live results and cites them;
running a normal prompt straight afterwards uses no web search
and has no extra tokens in the system prompt.

Pi does **not** browse the web by default. The official
`badlogic/pi-skills` repo has a `brave-search` skill that's exactly the
shape we want: a `SKILL.md` plus a `search.js`/`content.js`. It's a
*skill*, not an extension — meaning only its one-line description sits
in the system prompt; the body only loads when the agent decides to
search. Perfect USP fit.

**Plan:**
- Vendor the `brave-search` skill into `dotfiles/pi/skills/brave-search/`
  (or install it as a pi-package via `settings.json`).
- API key via 1Password (`BRAVE_API_KEY` in the existing secrets template).
- Optionally add a second skill `web-fetch` (curl + readability extract)
  for grabbing a specific URL the user pasted.

### 6. MCP via a single CLI bridge tool (your ask #3) — bridge TBD
Goal: keep MCP's power without paying its context tax. None of MCP's
per-server tool descriptions sit in the system prompt.

**Plan:**
- Pick an MCP CLI bridge. Dave is open to alternatives. Candidates
  to evaluate (research task, do this before writing the extension):
  - `mcporter`
  - `mcp-cli` (Anthropic-ish reference CLI)
  - `mcphost` (Go-based, talks stdio MCP, exposes simple CLI)
  - Roll our own thin shim in TS using the official `@modelcontextprotocol/sdk`
    if no existing CLI fits the "one tool, list/call" shape we want.
  Selection criteria: must run as a one-shot CLI (no daemon), must
  support stdio + SSE servers, must produce structured JSON output.

**Initial server wishlist** (Dave's, drives bridge requirements):
- **context7** — up-to-date library docs on demand. Probably stdio.
- **Chrome / browser control MCP** — for live debugging of web apps
  Dave is working on. Almost certainly stdio over a Chrome
  DevTools Protocol bridge; check `chrome-devtools-mcp` or
  `playwright-mcp` as the underlying server.
- (later) `serena` — see item 9. Free upgrade once the bridge ships.

This list confirms we need **stdio** support at minimum; SSE is
nice-to-have but not blocking.
- Wrap as a Nix derivation in the WRAPPED PACKAGES region.
- Write **one** Pi extension that registers **one** tool, e.g. `mcp`,
  with parameters `{ server: string, action: "list-tools"|"call",
  tool?: string, args?: object }`.
- The tool's `promptSnippet` lists the *names* of available servers
  (cheap), but tool catalogues are fetched on demand via
  `mcp list-tools <server>`.
- MCP server config (which servers exist, transport, env) declared in
  Nix and rendered to a config file the bridge reads.

Acceptance: agent can discover and call MCP tools, but the steady-state
system prompt only grows by ~one tool description regardless of how
many MCP servers are configured.

### 7. Mobile / chat reach-out (your ask #4) — **needs detailed exploration**

Dave wants a longer design discussion before we commit. Park this as
a **research task** that produces a follow-up design doc, not code.

Topics to cover in that doc:
- Outbound (Slack webhook, ntfy.sh + iOS Shortcut → WhatsApp, Twilio
  WhatsApp Business, plain APNs/Pushover, Telegram bot).
- Inbound steering via Pi's RPC (`docs/rpc.md`) — what's the
  always-on surface? launchd? Tailscale Funnel? Cloudflare Tunnel?
- Security model — anyone on Slack DMing the bot can drive the
  agent on your laptop; what's the auth story?
- Cost / privacy trade-offs per channel.

No code in this phase. Output: `plan/pi-mobile-notifications-design.md`.

---

## Phase 2.5 — developer-experience tooling (new asks)

### 8. Rich diff viewer for proposed edits (Dave's ask)

Goal: when Pi proposes an `edit` or `write`, optionally pop open a
proper side-by-side GUI diff (Meld-style) for review *before* the
change is applied. Bonus: LLM-annotated diff hunks.

**Plan:**
- Add a Pi extension that hooks `tool_call` for `edit`/`write` and,
  when a `--review-diffs` flag (or `/review on` toggle) is active,
  writes the proposed change to a tempfile and opens a GUI diff
  viewer, blocking the tool call until the user accepts/rejects.
- GUI viewer candidates (pick one, declare it via Nix/Homebrew):
  - **Meld** — classic, cross-platform, free, runs on macOS via
    homebrew (`brew install --cask meld`). Probably the default.
  - **Kaleidoscope 3** — paid, gorgeous, native macOS. Skip unless
    Dave already owns it.
  - **`git difftool` → VS Code / Zed** — works but feels heavier.
  - **`delta` + tmux pane** — terminal-only, fails the "pop up a
    proper UI" bar.
- Terminal-side default: **`difftastic`** (`difft`) — Dave's
  pick. Tree-sitter-aware structural diffs in the terminal,
  available in nixpkgs as `difftastic`. Wire it as the default
  diff renderer for Pi (e.g. via `GIT_EXTERNAL_DIFF` and a
  `tool_result` renderer hook for `edit`/`write`).
- LLM-annotated diffs (the "extra marks" goal): build a small
  `/explain-diff` command that takes the current pending diff,
  asks a fast model (Haiku/Flash) to annotate each hunk with a
  one-line semantic summary, and renders it inline above the diff.
  This is custom — no off-the-shelf tool does exactly this today
  that I'm aware of.

Acceptance: `pi --review-diffs` (or `/review on`) causes Meld to
pop up before each `edit` is applied; user can accept/reject; the
tool call proceeds or is blocked accordingly. `/explain-diff`
annotates pending changes with semantic summaries.

### 9. "Know the codebase" — semantic code search (Dave's ask)

Goal: improve Pi's ability to navigate large codebases without
dumping huge swaths of source into the context window.

**Recommendation:** *don't* default to vector RAG. Vector RAG
adds: an embedding model, an index that drifts from disk,
latency, and noisy retrieval. It's the wrong shape for Pi's USP.

**Preferred stack** (in order of context-cost):

1. **Better grep**: `ripgrep` is already there; ensure it is.
2. **Structural search**: `ast-grep` (`sg`) — tree-sitter-based,
   pattern-matching by AST. Add via Nix.
3. **Symbol map**: aider-style repo-map. Tree-sitter walks the
   repo, extracts symbol declarations + a single-line summary per
   file, exposes a `code_map` tool that returns the map for a
   path glob. Cheap, deterministic, no embeddings.
4. **LSP-backed semantic tools**: [`serena`](https://github.com/oraios/serena)
   is an existing MCP server that wraps language-server APIs
   (find-references, go-to-definition, rename) into agent tools.
   When item 6 (MCP bridge) lands, `serena` becomes a free
   upgrade — point the bridge at it.
5. **Vector RAG**: only if 1–4 prove insufficient. Then evaluate
   `lancedb` (embedded, no daemon) over `chroma`/`qdrant` for the
   no-extra-process win. Defer.

**Plan for this task:** ship items 1–3 as a Pi extension that
registers a `code_map` tool plus `ast_grep` tool, both of which
shell out to local binaries declared in Nix. Item 4 is unlocked
automatically by the MCP bridge (task 6). Item 5 stays a future
option.

### 10. Voice dictation into Pi (Dave's ask)

Goal: speak instead of type into Pi's editor.

**Options surveyed:**
- **Built-in macOS dictation** (fn fn). Free, OK quality, system-wide.
  Not Pi-specific but works in any text field including Pi's TUI.
  Zero-effort baseline.
- **Wispr Flow / Superwhisper / MacWhisper** — polished paid GUIs,
  push-to-talk, system-wide insert. Outside Nix's reach (App Store
  / direct downloads), can't be declaratively managed.
- **`whisper.cpp`** — local, fast on Apple Silicon, packageable in
  Nix. Pair with a hotkey daemon (`skhd` or aerospace) that records
  to a tempfile, transcribes, and types the result into the focused
  app. Fully Nix-managed.
- **Pi-native integration**: a Pi extension that registers a
  shortcut, records via the OS, calls `whisper.cpp` locally, and
  uses `ctx.ui.setEditorText()` to drop the transcript directly
  into Pi's editor. Cleanest UX, fully Nix-managed, zero context
  cost.

**Recommendation:** ship the Pi-native integration on top of
`whisper.cpp`. Keep it scoped: push-to-talk only, English only,
local model only (no API keys). System-wide dictation is a
separate concern — leave it to macOS built-in or a paid GUI as a
personal choice.

Acceptance: a chosen hotkey inside Pi records audio while held,
releases to transcribe locally, drops the text into Pi's editor.

**Note:** specific hotkey choice is **deferred to when this task
is picked up** — Dave's call. Candidates to consider then:
function key (F13–F19 if you have them mapped), Hyper-key chord
via aerospace, or a less-used Ctrl combo. Avoid `Ctrl+Space`
(clashes with too many TUIs).

---

## Phase 3 — nice-to-haves (consider after Phase 1/2 land)

These are bundled examples that pattern-match useful things from other
agentic tools (Claude Code, Aider, Cursor):

- `plan-mode/` — explicit plan-then-execute mode (Claude Code parity).
- `todo.ts` — built-in todo tool. Could integrate with our existing
  `plan/tasks/` convention rather than duplicate it. Probably skip
  unless integration is clean.
- `summarize.ts` / `custom-compaction.ts` — better `/compact` behaviour.
- `auto-commit-on-exit.ts` — auto-commit at session end. Risky;
  probably skip in favour of explicit `git-checkpoint`.
- `bookmark.ts` + `setLabel` — mark important turns for `/tree` nav.
- `model-status.ts` / `custom-footer.ts` / `status-line.ts` — small TUI
  polish (current model, cost, context %).

---

## Phase 4 — skills pattern (your ask "skills: not yet, but pattern")

Decision: **don't author skills speculatively.** Establish the pattern
in Phase 0 (directory + symlink) and in Phase 2 step 5 (vendor
`brave-search`). When a real need arises:

1. Create `modules/home-manager/dotfiles/pi/skills/<name>/SKILL.md`.
2. Add helper scripts alongside it.
3. `git add` (Nix won't see it otherwise — see CLAUDE.md).
4. `danix-switch` — symlink appears in `~/.pi/agent/skills/`.

Skills automatically register as `/skill:<name>` and only their
descriptions sit in context. This is the cheapest possible way to
extend Pi's capabilities and is the **default choice** for anything
that's "a workflow + some scripts" rather than "a hook into Pi's
lifecycle".

For sharing/portability: any skill we like enough can later be
extracted into its own pi-package repo and consumed from Nix via
`packages = ["git:github.com/dh7892/<name>"]` in `settings.json`.

---

## Things explicitly out of scope (for now)

- Custom theme — current TUI is fine.
- Custom provider extensions — happy with default Anthropic/OpenAI.
- Author our own skills before we have a concrete need.
- Anything that requires a long-running daemon (defer until 7b).

---

## Suggested order

1. Phase 0 (skeleton).
2. Phase 1 in one batch — including subagents (item 0), which Dave
   has prioritised. All bundled, all zero-context.
3. Item 5 (web search via `brave-search` skill, free tier).
4. Item 9 (code-knowledge tools: ripgrep + ast-grep + repo-map).
5. Item 8 (rich diff viewer + `/explain-diff`).
6. Item 10 (voice dictation via `whisper.cpp`).
7. Item 6 (MCP bridge) — biggest design exercise; unlocks `serena`
   for free as a follow-up to item 9.
8. Item 7 (mobile/chat) — **research first**, produce a design doc,
   then re-plan.
9. Re-evaluate Phase 3 list with real usage data.
10. Re-check `oh-my-pi` upstream for anything we missed (Dave
    asked to defer this until search etc. is in).

---

## Resolved with Dave

- Web search: **Brave**, free tier.
- MCP bridge: open to alternatives — first sub-task in item 6 is to
  evaluate candidates.
- Mobile/chat: **needs detailed exploration** — research task only,
  produces a design doc.
- Subagents: **promoted** to Phase 1 item 0.
- `oh-my-pi`: defer until after web search etc. is in; revisit at
  step 10 of the suggested order.

## Resolved (round 2)

- **Web search:** provider-native via Anthropic, gated behind
  `/research` and `/research-mode` commands (no skill, no Brave
  account). Zero steady-state context cost.
- **MCP servers wishlist (initial):** `context7` and a Chrome
  control MCP. Drives stdio-must-work for the bridge.
- **Diff tool:** `difftastic` confirmed as the default.
- **Voice hotkey:** decision deferred to when item 10 is picked
  up; noted on the task.

## Still open

Nothing blocking. Plan is ready to split into TASK files on Dave's
go-ahead.
