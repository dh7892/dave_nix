# TASK-014 — Wire up a Chrome control MCP server

Status: pending
Depends on: TASK-007 (MCP bridge must be in place).
Source: split off from TASK-007 wishlist.

## Goal

Give Pi the ability to drive a Chrome browser for live debugging of
web apps Dave is building (DOM inspection, console log reading,
network tracing, simple navigation). Reached through the existing
`mcp` tool, no new prompt budget.

## Plan

### Phase A — pick the server

Two main candidates, both stdio over CDP:

- **`chrome-devtools-mcp`** — lighter-weight, uses an existing
  Chrome instance via the DevTools Protocol. Good fit if we just
  want "look at what's already running".
- **`playwright-mcp`** — heavier, ships its own browser-driver
  layer. Better if we want headless automation, multiple contexts,
  scripted flows.

Default: `chrome-devtools-mcp`. Switch to playwright-mcp if it
turns out we want full automation.

Stop and ask the human if the choice is non-obvious by the time
you're packaging it.

### Phase B — implement

1. Add an entry to `mcpServers` in `modules/home-manager/pi.nix`,
   e.g.:
   ```nix
   chrome = {
     command = "npx";
     args = [ "-y" "chrome-devtools-mcp" ];
     # env.CHROME_DEBUGGING_PORT = "9222";  # if we want a fixed port
   };
   ```
2. Document the prerequisite (Chrome launched with
   `--remote-debugging-port=9222`, or whatever the chosen server
   needs) in a short note — likely in `LAYOUT.md` under "MCP
   servers" or in this task's completion notes.
3. If a launcher wrapper helps (e.g. a `danix-chrome-debug` shell
   alias that boots Chrome with the right flags), add it to
   `dotfiles/zshrc` or as a `writeShellApplication` in
   `default.nix` — outside the WRAPPED PACKAGES region.
4. Smoke-test from Pi:
   - `mcp { server: "chrome", action: "list-tools" }` returns the
     server's tool catalogue.
   - At least one real interaction works against a page Dave is
     debugging (e.g. read console logs from `localhost:5173`).
5. `git add`, dry-run-build, commit.

## Acceptance

- `chrome` (or whatever name we settle on) shows up in the `mcp`
  tool's server list after `danix-switch`.
- `list-tools` succeeds and the catalogue makes sense.
- A representative debugging interaction succeeds end to end.
- Any required setup steps (launching Chrome with debug flags) are
  documented somewhere discoverable.

## Out of scope

- Full browser automation suite if we picked the lightweight
  candidate — that's a separate decision to revisit later.
- Recording/replay, screenshots-as-artifacts pipelines, etc.
