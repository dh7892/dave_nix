# TASK-010 — "Know the codebase" tools (no vector RAG)

Status: pending
Source: `plan/pi-addons-plan.md` Phase 2.5 item 9.
Fanout-suitable: **yes**.

## Goal

Improve Pi's ability to navigate large codebases without dumping
huge swaths of source into the context window. **Explicitly
not** vector RAG — see plan doc for rationale (drift, latency,
noisy retrieval, wrong shape for Pi's USP).

## Stack (in order of context-cost, cheapest first)

1. **ripgrep** — already installed. Sanity-check.
2. **`ast-grep` (`sg`)** — tree-sitter structural search. Add via
   Nix (`nixpkgs.ast-grep`).
3. **Symbol map** — aider-style repo-map. Tree-sitter walks the
   repo, extracts symbol declarations + a single-line summary
   per file, exposes a `code_map` tool returning the map for a
   path glob.
4. *(unlocked by TASK-007 MCP bridge — not part of this task.)*
   `serena` MCP server gives LSP-backed `find-references`,
   `go-to-definition`, `rename`, etc. Becomes free once the
   bridge ships.
5. **Vector RAG** — out of scope. Re-evaluate only if 1–4 prove
   insufficient.

## Plan

1. Add `ast-grep` to home-manager packages.
2. Write a Pi extension at
   `modules/home-manager/dotfiles/pi/extensions/code-knowledge.ts`
   registering two tools:
   - `ast_grep` — thin wrapper around `sg` CLI. Parameters:
     pattern, optional language, optional path glob. Returns
     match list with file:line:context.
   - `code_map` — generates a symbol map for a path glob.
     Implementation: shell out to a small helper script (could
     be Python or Node) that uses tree-sitter bindings, or use
     existing tools like `aider --map-tokens`-equivalent if
     we can find a stand-alone CLI shape. Investigate before
     writing — don't reinvent if a small CLI exists.
3. `promptSnippet` for both tools: short, <2 lines each. Just
   enough so the model knows when to reach for them.
4. **Don't** add an `lsp` tool here — that comes free via
   `serena` once TASK-007 ships.
5. `git add`, dry-run-build, commit.

## Acceptance

- Asking the agent "where is the `compute_grid` function used?"
  causes it to invoke `ast_grep` (or `code_map` then `read`)
  rather than `read`-ing 30 files.
- The system prompt grows by ~two short tool descriptions, no
  more.

## Out of scope

- Vector embeddings, lancedb, chroma.
- An always-running indexer daemon.
- LSP tooling — deferred to `serena` post-TASK-007.

## Notes

- If `code_map` ends up being non-trivial to build, ship just
  `ast_grep` first and split `code_map` into a follow-up task.
  Don't gold-plate.
