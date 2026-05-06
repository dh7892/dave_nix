# TASK-007 — Single-tool MCP bridge

Status: pending
Source: `plan/pi-addons-plan.md` Phase 2 item 6.
Fanout-suitable: **partly** — the bridge-evaluation phase wants
human discussion. The implementation phase, once a bridge is
chosen, is fanout-suitable.

## Goal

Give Pi access to MCP server functionality without paying MCP's
per-server, per-tool context tax. Steady-state system prompt
should grow by ~one tool description regardless of how many MCP
servers we configure.

## Initial server wishlist (drives bridge requirements)

- **context7** — up-to-date library docs on demand. Likely stdio.
- **Chrome / browser control MCP** — for live debugging of web
  apps Dave is building. Almost certainly stdio over CDP. Check
  `chrome-devtools-mcp` and `playwright-mcp` as candidates.
- (later) `serena` — LSP-backed semantic code tools. Free upgrade
  once this bridge ships, see TASK-010.

This list confirms **stdio support is required**. SSE is nice-to-have.

## Plan

### Phase A — choose the bridge (human-in-the-loop)

Evaluate candidates (one-shot CLI shape, structured JSON output,
stdio + ideally SSE):

- `mcporter`
- `mcp-cli` (Anthropic-ish reference CLI)
- `mcphost` (Go, talks stdio MCP, simple CLI)
- Roll our own thin TS shim using the official
  `@modelcontextprotocol/sdk` if nothing fits.

Selection criteria:
- Must run as a one-shot CLI (no daemon).
- Must support stdio MCP servers.
- Must produce structured JSON output.
- Bonus: SSE support; sane error reporting.

Output of Phase A: a recommendation in this task file (edit
in-place in the worker's branch). **Stop and ask the human**
before committing to a bridge if the choice is non-obvious.

### Phase B — implement

1. Wrap the chosen bridge as a Nix derivation in the
   `WRAPPED PACKAGES` region of
   `modules/home-manager/default.nix`, following existing
   conventions (`# update-source: <kind> <details>` comment,
   pinned version + hash).
2. Render MCP server config (which servers, transport, env)
   from a Nix attrset to the file shape the bridge expects.
   Keep the attrset in `modules/home-manager/pi.nix` next to
   the existing settings attrset.
3. Write **one** Pi extension at
   `modules/home-manager/dotfiles/pi/extensions/mcp.ts` that
   registers **one** tool, e.g. `mcp`, with parameters:
   ```
   { server: string,
     action: "list-tools" | "call",
     tool?: string,
     args?: object }
   ```
4. The tool's `promptSnippet` lists the **names** (not the tool
   catalogues) of available servers. Tool catalogues fetched
   on demand via `mcp list-tools <server>`.
5. Per-server secrets (e.g. context7 key if needed) come from
   1Password CLI templates as usual; new fields added to
   `private.nix.example`.
6. `git add`, dry-run-build, commit.

## Acceptance

- The agent can discover MCP tools via `mcp list-tools <server>`
  and call them via `mcp call ...`.
- The steady-state system prompt grows by ~one tool description
  + a short list of server names — irrespective of how many
  servers are configured.
- context7 and a Chrome control MCP are both reachable and
  produce useful output for representative queries.

## Out of scope

- Auto-discovery of MCP servers from a registry. Manual config.
- Daemonised bridges. We want one-shot CLI shape.
- `serena` integration as a deliverable here — it's a free
  follow-up once the bridge exists; see TASK-010.
