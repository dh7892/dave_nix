/**
 * Bash spawn hook — source ~/.profile before every bash tool call.
 *
 * Adapted from Pi's bundled `bash-spawn-hook.ts` example.
 *
 * Why we keep this on Dave's setup: Pi's `bash` tool spawns a
 * non-interactive, non-login bash, which does *not* read `~/.profile`,
 * `~/.zshrc`, or any of nushell's config. Most of Dave's interactive
 * PATH already comes from nix-darwin / home-manager and is therefore
 * inherited via Pi's own environment, but a few things only live in
 * `~/.profile` — notably:
 *   - `~/.cargo/env` (puts `~/.cargo/bin` on PATH → cargo, rustc,
 *     plus any cargo-installed tools)
 *   - `JAVA_HOME` (Coursier-managed JDK)
 *   - Coursier's install dir on PATH
 *
 * Without this hook, `bash -c 'cargo --version'` from inside Pi
 * fails even though `cargo` works fine in Ghostty. With it, Pi's
 * shell sees the same toolchain Dave does.
 *
 * Things this hook does *not* fix (because they aren't in
 * `~/.profile` either): mise, direnv, fnm. None of those are
 * currently installed for this user, so that's fine; if any get
 * adopted later, add their init lines to `~/.profile` (or extend
 * this hook) so Pi keeps seeing the same env as the terminal.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { createBashTool } from "@mariozechner/pi-coding-agent";

export default function (pi: ExtensionAPI) {
	const cwd = process.cwd();

	const bashTool = createBashTool(cwd, {
		spawnHook: ({ command, cwd, env }) => ({
			// `[ -f ~/.profile ] && . ~/.profile` keeps this safe on
			// machines without one; the marker var is handy for
			// debugging ("did the hook actually run?").
			command: `[ -f "$HOME/.profile" ] && . "$HOME/.profile"\n${command}`,
			cwd,
			env: { ...env, PI_SPAWN_HOOK: "1" },
		}),
	});

	pi.registerTool({
		...bashTool,
		execute: async (id, params, signal, onUpdate, _ctx) => {
			return bashTool.execute(id, params, signal, onUpdate);
		},
	});
}
