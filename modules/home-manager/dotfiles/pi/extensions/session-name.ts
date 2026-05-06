/**
 * Session naming — auto + manual.
 *
 * Adapted from Pi's bundled `session-name.ts` example. The upstream
 * version only ships the `/session-name` slash command. We extend it
 * here so that, if a session has no name when the first user message
 * is sent, we derive one automatically from that message — so
 * `/resume` shows meaningful labels instead of UUIDs.
 *
 * Manual override: `/session-name [new name]` (unchanged).
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const MAX_LEN = 60;

function deriveName(text: string): string | null {
	// Collapse whitespace, strip leading slash-commands and code fences,
	// then truncate.
	const cleaned = text
		.replace(/```[\s\S]*?```/g, " ")
		.replace(/\s+/g, " ")
		.trim();
	if (!cleaned) return null;
	if (cleaned.length <= MAX_LEN) return cleaned;
	return cleaned.slice(0, MAX_LEN).trimEnd() + "…";
}

export default function (pi: ExtensionAPI) {
	pi.registerCommand("session-name", {
		description: "Set or show session name (usage: /session-name [new name])",
		handler: async (args, ctx) => {
			const name = args.trim();

			if (name) {
				pi.setSessionName(name);
				ctx.ui.notify(`Session named: ${name}`, "info");
			} else {
				const current = pi.getSessionName();
				ctx.ui.notify(current ? `Session: ${current}` : "No session name set", "info");
			}
		},
	});

	// Auto-name the session from the first real user input, if no
	// name has been set yet. Skip extension-injected input so other
	// extensions can't accidentally claim the title.
	pi.on("input", async (event) => {
		if (event.source === "extension") return { action: "continue" };
		if (pi.getSessionName()) return { action: "continue" };

		const name = deriveName(event.text);
		if (name) pi.setSessionName(name);
		return { action: "continue" };
	});
}
