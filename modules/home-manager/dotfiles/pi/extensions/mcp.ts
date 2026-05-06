/**
 * MCP bridge — single-tool exposure of MCP servers to Pi.
 *
 * Why this exists (TASK-007): the obvious "register every MCP tool as a Pi
 * tool" approach blows up the system prompt. We register *one* tool, `mcp`,
 * with two actions: `list-tools` to discover a server's catalogue on demand,
 * and `call` to invoke a specific tool. Steady-state prompt growth is one
 * tool description plus a short list of configured server names, regardless
 * of how many MCP servers are wired up.
 *
 * Implementation: shell out to `mcporter` (a one-shot MCP CLI; wrapped as
 * `mcporter-pkg` in modules/home-manager/default.nix). Server config lives
 * in ~/.config/mcporter/mcporter.json, rendered from the `mcpServers`
 * attrset in modules/home-manager/pi.nix.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { StringEnum } from "@mariozechner/pi-ai";
import { Type } from "typebox";
import { spawn } from "node:child_process";
import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const MCP_CONFIG_PATH = join(homedir(), ".config", "mcporter", "mcporter.json");

function loadServerNames(): string[] {
	try {
		const raw = readFileSync(MCP_CONFIG_PATH, "utf8");
		const parsed = JSON.parse(raw) as { mcpServers?: Record<string, unknown> };
		return Object.keys(parsed.mcpServers ?? {}).sort();
	} catch {
		return [];
	}
}

interface RunResult {
	stdout: string;
	stderr: string;
	code: number | null;
}

function runMcporter(args: string[], signal?: AbortSignal): Promise<RunResult> {
	return new Promise((resolve, reject) => {
		const child = spawn("mcporter", ["--config", MCP_CONFIG_PATH, ...args], {
			stdio: ["ignore", "pipe", "pipe"],
		});
		let stdout = "";
		let stderr = "";
		child.stdout.on("data", (chunk) => {
			stdout += chunk.toString();
		});
		child.stderr.on("data", (chunk) => {
			stderr += chunk.toString();
		});
		const onAbort = () => child.kill("SIGTERM");
		signal?.addEventListener("abort", onAbort, { once: true });
		child.on("error", (err) => {
			signal?.removeEventListener("abort", onAbort);
			reject(err);
		});
		child.on("close", (code) => {
			signal?.removeEventListener("abort", onAbort);
			resolve({ stdout, stderr, code });
		});
	});
}

export default function (pi: ExtensionAPI) {
	const servers = loadServerNames();
	const serverList = servers.length > 0 ? servers.join(", ") : "(none configured)";

	pi.registerTool({
		name: "mcp",
		label: "MCP",
		description: [
			"Bridge to MCP (Model Context Protocol) servers via the local `mcporter` CLI.",
			"",
			`Configured servers: ${serverList}.`,
			"",
			"Use `action: \"list-tools\"` first to discover what a server exposes (returns",
			"each tool's name, description, and JSON-schema parameters). Then use",
			"`action: \"call\"` with the chosen `tool` and an `args` object matching that",
			"schema. Server config lives in ~/.config/mcporter/mcporter.json (managed by",
			"Nix in modules/home-manager/pi.nix). To add a new server, edit that file's",
			"`mcpServers` attrset and run `danix-switch`.",
		].join("\n"),
		promptSnippet: `Call MCP servers (${serverList}) — list-tools to discover, call to invoke`,
		parameters: Type.Object({
			server: Type.String({
				description: "Configured MCP server name (see system prompt for the list).",
			}),
			action: StringEnum(["list-tools", "call"] as const),
			tool: Type.Optional(
				Type.String({
					description: "Tool name on the server. Required when action is 'call'.",
				}),
			),
			args: Type.Optional(
				Type.Object(
					{},
					{
						additionalProperties: true,
						description:
							"JSON object of arguments for the tool. Shape per the tool's schema from list-tools.",
					},
				),
			),
		}),
		async execute(_toolCallId, params, signal) {
			const { server, action, tool, args } = params as {
				server: string;
				action: "list-tools" | "call";
				tool?: string;
				args?: Record<string, unknown>;
			};

			if (action === "list-tools") {
				const result = await runMcporter(["list", server, "--schema", "--json"], signal);
				if (result.code !== 0) {
					throw new Error(
						`mcporter list ${server} failed (exit ${result.code}):\n${result.stderr || result.stdout}`,
					);
				}
				return {
					content: [{ type: "text", text: result.stdout.trim() || "{}" }],
					details: { server, action },
				};
			}

			// action === "call"
			if (!tool) {
				throw new Error("`tool` is required when action is 'call'.");
			}
			const cliArgs = ["call", `${server}.${tool}`, "--output", "json"];
			if (args && Object.keys(args).length > 0) {
				cliArgs.push("--args", JSON.stringify(args));
			}
			const result = await runMcporter(cliArgs, signal);
			if (result.code !== 0) {
				throw new Error(
					`mcporter call ${server}.${tool} failed (exit ${result.code}):\n${result.stderr || result.stdout}`,
				);
			}
			return {
				content: [{ type: "text", text: result.stdout.trim() || "{}" }],
				details: { server, action, tool },
			};
		},
	});
}
