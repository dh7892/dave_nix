/**
 * code-knowledge
 *
 * Tools for navigating large codebases without dumping huge swaths of
 * source into context.
 *
 * Currently registers:
 *   - ast_grep: thin wrapper around the `ast-grep` CLI for tree-sitter
 *     structural search. Cheaper than `read`-ing whole files when you
 *     want call sites, definitions, or pattern matches.
 *
 * `code_map` (aider-style symbol map) is intentionally deferred to a
 * follow-up task — see plan/tasks/pending/TASK-011-code-map.md. The
 * lower-context options (ripgrep, ast_grep) cover most navigation needs;
 * LSP-shaped queries will arrive via `serena` once TASK-007 lands the
 * MCP bridge.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { spawn } from "node:child_process";
import { Type } from "typebox";

const AST_GREP_PARAMS = Type.Object({
	pattern: Type.String({
		description:
			"ast-grep pattern. Meta-variables like $NAME, $$$ARGS match identifiers and lists. Example: 'fn $NAME($$$) { $$$ }' for Rust function defs.",
	}),
	language: Type.Optional(
		Type.String({
			description:
				"Optional language hint (rust, typescript, tsx, python, go, etc.). If omitted ast-grep infers from file extensions.",
		}),
	),
	path: Type.Optional(
		Type.String({
			description:
				"Optional path or glob to search under. Defaults to the current working directory. Honours .gitignore.",
		}),
	),
	max_results: Type.Optional(
		Type.Integer({
			description: "Cap on lines of output returned to the model. Defaults to 200.",
			minimum: 1,
		}),
	),
});

interface SpawnResult {
	stdout: string;
	stderr: string;
	code: number | null;
}

function runAstGrep(args: string[], signal?: AbortSignal): Promise<SpawnResult> {
	return new Promise((resolve, reject) => {
		const child = spawn("ast-grep", args, { signal });
		let stdout = "";
		let stderr = "";
		child.stdout.on("data", (chunk) => {
			stdout += chunk.toString();
		});
		child.stderr.on("data", (chunk) => {
			stderr += chunk.toString();
		});
		child.on("error", reject);
		child.on("close", (code) => {
			resolve({ stdout, stderr, code });
		});
	});
}

export default function codeKnowledgeExtension(pi: ExtensionAPI) {
	pi.registerTool({
		name: "ast_grep",
		label: "AST Grep",
		description:
			"Structural code search via ast-grep (tree-sitter patterns). Prefer this over reading many files when looking for definitions, call sites, or syntactic patterns. Cheaper than `read`, more precise than ripgrep for code-shaped queries.",
		promptSnippet:
			"ast_grep: tree-sitter structural search; use for code-shaped queries (defs, call sites) before reading whole files.",
		promptGuidelines: [
			"Prefer ast_grep or grep over reading multiple files when locating definitions or usages of a symbol.",
		],
		parameters: AST_GREP_PARAMS,
		async execute(_toolCallId, params, signal) {
			const args: string[] = ["run", "--pattern", params.pattern];
			if (params.language) {
				args.push("--lang", params.language);
			}
			if (params.path) {
				args.push(params.path);
			}

			let result: SpawnResult;
			try {
				result = await runAstGrep(args, signal);
			} catch (err) {
				const msg = err instanceof Error ? err.message : String(err);
				return {
					content: [{ type: "text", text: `ast-grep failed to start: ${msg}` }],
					isError: true,
					details: { args },
				};
			}

			const max = params.max_results ?? 200;
			const stdoutLines = result.stdout.split("\n");
			const truncated = stdoutLines.length > max;
			const shown = truncated ? stdoutLines.slice(0, max).join("\n") : result.stdout;

			const parts: string[] = [];
			if (shown.trim().length > 0) {
				parts.push(shown.trimEnd());
			} else if (result.code === 0) {
				parts.push("(no matches)");
			}
			if (truncated) {
				parts.push(`… truncated to ${max} lines (of ${stdoutLines.length}). Narrow the pattern or path.`);
			}
			if (result.stderr.trim().length > 0) {
				parts.push(`stderr:\n${result.stderr.trimEnd()}`);
			}
			if (result.code !== 0 && result.code !== null) {
				parts.push(`ast-grep exited with code ${result.code}`);
			}

			return {
				content: [{ type: "text", text: parts.join("\n\n") }],
				isError: result.code !== 0 && result.code !== null && result.stdout.length === 0,
				details: {
					args,
					exitCode: result.code,
					matchLines: stdoutLines.length,
					truncated,
				},
			};
		},
	});
}
