# TASK-006 — Provider-native web search behind `/research`

Status: pending
Source: `plan/pi-addons-plan.md` Phase 2 item 5 (revised).
Fanout-suitable: **yes**, but read the source-material check
first — there's a small upfront SDK investigation that wants
human-in-the-loop attention.

## Goal

Give Pi the ability to search the live web, but **only when
explicitly invoked**, so the steady-state system prompt stays
unchanged and we pay no tokens for the capability when we're
not using it.

Decision (already taken in plan): use Anthropic's
provider-native `web_search` tool (not Brave, not a custom
skill). Activated by splicing a tool block into the outgoing
request payload for one turn at a time.

## Plan

### Phase A — verify the SDK surface (do first)

Before writing the extension, confirm:

1. The bundled `pi-ai` SDK does expose
   `before_provider_request` (or the equivalent hook) **with
   the Anthropic-shaped payload still intact**, i.e. that it
   hasn't been normalised into a provider-agnostic shape that
   strips unknown tool types.
2. `ctx.model.provider` (or equivalent) is reliably set so we
   can branch on Anthropic vs others.
3. Pi/`pi-ai` doesn't already provide a documented surface for
   "add a provider-native tool to this turn" — if it does, use
   that instead of payload mutation.

Output of Phase A: a one-paragraph note in this task file (edit
in place, in the worker's branch) saying which approach we're
using and why. **Stop and ask the human if Phase A reveals
something unexpected** — don't soldier on with payload mutation
if there's a cleaner path.

### Phase B — implement

1. Write `modules/home-manager/dotfiles/pi/extensions/research.ts`
   that:
   - Registers `/research <query>` — one-shot: arms a flag for
     the next turn, then calls `sendUserMessage(query)`.
   - Registers `/research-mode on|off` — sticky multi-turn
     toggle.
   - Hooks `before_provider_request` (or whatever Phase A
     identified) — when the flag is set, splices Anthropic's
     `web_search` tool block into the payload for that one
     request. One-shot flag clears in `turn_end`; sticky
     persists.
   - Calls `ctx.ui.setStatus("web", "🌐 web search ON")` while
     active, clears it on deactivation.
   - **Provider-detection:** only acts when
     `ctx.model.provider === "anthropic"`. For others, surface
     a notify "web search not wired up for <provider> yet" and
     exit.
2. `git add`, dry-run-build, commit.

## Acceptance

- `/research what's new in Bevy 0.15?` triggers a turn in
  which Claude actually fetches live results and cites them.
- Running a normal prompt straight afterwards uses no web
  search and has no extra tokens in the system prompt for it.
- `/research-mode on` then a normal prompt → web search runs.
  `/research-mode off` → it stops.
- Switching to a non-Anthropic model and trying `/research`
  produces a clean "not wired up" message rather than a crash.

## Cost note

Anthropic charges ~$0.01 per search on top of token costs. No
extra API keys, no Brave/Tavily account.

## Out of scope

- Brave/Tavily fallback for non-Anthropic providers. Parked
  unless Dave changes provider.
- A Pi-managed search-result cache. Defer.
- Rendering search results in any custom way — let Anthropic's
  default citation rendering through unchanged.
