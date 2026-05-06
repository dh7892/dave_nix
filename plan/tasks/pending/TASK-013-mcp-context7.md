# TASK-013 — Wire up context7 MCP server

Status: pending
Depends on: TASK-007 (MCP bridge must be in place).
Source: split off from TASK-007 wishlist.

## Goal

Make context7 — Upstash's "fresh upstream library docs on demand"
MCP server — reachable from Pi via the existing `mcp` tool.

After this lands, Pi can do
`mcp { server: "context7", action: "list-tools" }` to discover the
catalogue and `mcp { server: "context7", action: "call", tool: ..., args: ... }`
to fetch docs.

## Plan

1. Decide on the transport. Upstream ships both an npx stdio server
   (`npx -y @upstash/context7-mcp`) and a hosted HTTP endpoint.
   Default to stdio — keeps everything local, no extra DNS/auth
   surface.
2. Add an entry to `mcpServers` in `modules/home-manager/pi.nix`:
   ```nix
   context7 = {
     command = "npx";
     args = [ "-y" "@upstash/context7-mcp" ];
     # env.CONTEXT7_API_KEY = "..."; # only if a key is needed
   };
   ```
3. If a key turns out to be required (free tier may not need one):
   - Add `context7ApiKey` to `private.nix.example` with a placeholder
     and a comment.
   - Read it via the `private` arg in `pi.nix` and inject into
     `mcpServers.context7.env`.
4. Smoke-test from Pi:
   - `mcp { server: "context7", action: "list-tools" }` returns a
     non-empty tool list.
   - `mcp { server: "context7", action: "call", tool: "<...>", args: { ... } }`
     returns sensible content for a representative library lookup
     (e.g. "show me the latest `bevy` 0.14 docs on `Query`").
5. `git add`, dry-run-build, commit.

## Acceptance

- context7 appears in the `mcp` tool's `promptSnippet` server list
  after `danix-switch`.
- Both `list-tools` and at least one real `call` succeed end to end
  in a Pi session.
- No secrets committed; any key flows through `private.nix` /
  1Password as usual.

## Out of scope

- Caching context7 responses locally.
- Switching to context7's HTTP transport (revisit if stdio proves
  flaky).
