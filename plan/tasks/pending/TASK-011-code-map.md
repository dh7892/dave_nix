# TASK-011 — `code_map` symbol-map tool (Pi)

Status: pending
Source: split out of TASK-010. See that task's "Notes" — the
explicit fallback was "ship `ast_grep` first, split `code_map`
into a follow-up." This is the follow-up.
Fanout-suitable: **yes** (independent of other Pi addons).

## Goal

Give Pi a cheap birds-eye view of an unfamiliar codebase: an
aider-style "repo map" — symbol declarations + a one-line
summary per file, scoped to a path glob.

## Why not in TASK-010?

TASK-010 added `ast_grep` (which covers most "where is X used?"
queries) and noted that `code_map` is non-trivial to build well.
Punting it kept that task small. Re-evaluate once `ast_grep` has
been used in anger — `code_map` is only worth building if the
agent still resorts to bulk `read` calls when orienting in a new
repo.

## Investigation, before writing code

1. **Stand-alone CLIs first.** Is there a small CLI that already
   produces an aider-shape map? Candidates to evaluate:
   - `aider --map-tokens <n>` — does it have a non-interactive
     "just print the map" mode?
   - `tree-sitter tags` (built into `tree-sitter-cli`) — emits
     ctags-format symbol tags using each grammar's `tags.scm`.
   - Universal `ctags -R --output-format=json` — pre-tree-sitter
     but battle-tested, already wraps many languages.
   - `ast-grep scan` with a custom rule set per language.
2. Pick the smallest thing that produces "for each file under
   <glob>: list of top-level symbol declarations with line
   numbers." A one-line file summary is nice-to-have, not
   required for v1.
3. Only fall back to writing a bespoke tree-sitter walker
   (Python or Node) if none of the above fit.

## Plan

1. Land the chosen backend as a Nix package in
   `modules/home-manager/default.nix` (likely
   `tree-sitter` / `universal-ctags`; both already in nixpkgs).
2. Extend
   `modules/home-manager/dotfiles/pi/extensions/code-knowledge.ts`
   with a `code_map` tool. Parameters:
   - `path` (string, required): file or glob to map.
   - `max_files` (int, optional): cap on files included.
3. `promptSnippet`: <2 lines. Something like
   `"code_map: symbol outline for a path; use to orient before
   reading."`
4. `git add`, dry-run-build, commit.

## Acceptance

- "Give me an outline of `src/`" prompts the agent to call
  `code_map` once, not `read` 30 files.
- Output fits comfortably in context for a medium-sized
  subdirectory (rule of thumb: <2k tokens for ~30 files).
- The `ast_grep` tool from TASK-010 is unaffected.

## Out of scope

- Vector embeddings / semantic search.
- A long-running indexer daemon. Each `code_map` call is allowed
  to re-walk; if that's too slow we add caching later.
- LSP-shaped queries (`find-references`, `go-to-def`) — those
  arrive via `serena` MCP once TASK-007 ships.
