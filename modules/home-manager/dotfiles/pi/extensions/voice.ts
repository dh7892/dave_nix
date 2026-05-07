/**
 * voice.ts — push-to-talk voice dictation for Pi.
 *
 * Tap ctrl+shift+space to start recording from the default microphone via
 * `sox`'s `rec`. Tap ctrl+shift+space again to stop, transcribe locally with
 * `whisper.cpp` (ggml-base.en, English), and paste the result into
 * Pi's editor at the cursor. Fully offline, no API keys.
 *
 * Wired up in Nix:
 *   - `whisper-cpp` and `sox` are in home-manager packages.
 *   - The model file is symlinked to
 *     `$HOME/.local/share/whisper-models/ggml-base.en.bin` by
 *     `home.file` (declarative, no manual download).
 *
 * Designed as a toggle (not literal press-and-hold) because Pi's
 * shortcut API doesn't expose key-up events. See
 * plan/tasks/completed/TASK-011-voice-dictation.md for the rationale.
 */

import { execFile, spawn, type ChildProcess } from "node:child_process";
import { promisify } from "node:util";
import { mkdtemp, rm, stat } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const execFileAsync = promisify(execFile);

const MODEL_PATH = `${process.env.HOME}/.local/share/whisper-models/ggml-base.en.bin`;
const HOTKEY = "ctrl+shift+space";

interface RecordingState {
	proc: ChildProcess;
	wavPath: string;
	tempDir: string;
	stderr: string;
	exited: Promise<number | null>;
	diedEarly: boolean;
}

export default function (pi: ExtensionAPI) {
	let state: RecordingState | null = null;

	pi.registerShortcut(HOTKEY, {
		description: "Voice dictation: tap to start, tap again to stop & transcribe",
		handler: async (ctx) => {
			if (state === null) {
				// Start recording.
				try {
					const tempDir = await mkdtemp(join(tmpdir(), "pi-voice-"));
					const wavPath = join(tempDir, "rec.wav");
					// `rec` (from sox) records until the process exits.
					// 16 kHz mono 16-bit PCM is whisper.cpp's native input.
					const proc = spawn(
						"rec",
						[
							"-q",
							"-r", "16000",
							"-c", "1",
							"-b", "16",
							wavPath,
						],
						{ stdio: ["ignore", "ignore", "pipe"] },
					);
					let stderr = "";
					proc.stderr?.on("data", (chunk: Buffer) => {
						stderr += chunk.toString();
					});
					const exited: Promise<number | null> = new Promise((resolve) => {
						proc.once("exit", (code) => resolve(code));
					});
					const recState: RecordingState = {
						proc,
						wavPath,
						tempDir,
						stderr,
						exited,
						diedEarly: false,
					};
					// Track whether rec exits on its own (mic-permission denial,
					// missing audio device, etc.). We surface the captured
					// stderr instead of the misleading "input file not found"
					// from whisper-cli.
					exited.then((code) => {
						recState.stderr = stderr;
						if (state === recState) {
							recState.diedEarly = true;
							ctx.ui.notify(
								`voice: recorder exited (code ${code}) before stop. ${stderr.trim() || "(no stderr — check microphone permission for the terminal hosting Pi)"}`,
								"error",
							);
							state = null;
							ctx.ui.setStatus("voice", undefined);
							rm(tempDir, { recursive: true, force: true }).catch(() => {});
						}
					});
					proc.on("error", (err) => {
						ctx.ui.notify(`voice: failed to start recorder: ${err.message}`, "error");
						state = null;
					});
					state = recState;
					ctx.ui.setStatus("voice", "🎙 recording — tap ctrl+shift+space to stop");
				} catch (err) {
					ctx.ui.notify(`voice: ${(err as Error).message}`, "error");
				}
				return;
			}

			// Stop recording, then transcribe.
			const current = state;
			const { proc, wavPath, tempDir, exited } = current;
			state = null;
			ctx.ui.setStatus("voice", "⏳ transcribing…");

			// Ask sox to finalize the WAV header (SIGINT is the polite
			// way; SIGTERM also works but may truncate the trailing
			// frames).
			try { proc.kill("SIGINT"); } catch {}
			await exited;

			// If rec never produced an output file, surface its stderr
			// directly — whisper's "input file not found" is a red herring.
			try {
				await stat(wavPath);
			} catch {
				ctx.ui.notify(
					`voice: recorder produced no output. ${current.stderr.trim() || "(no stderr — check microphone permission for the terminal hosting Pi: System Settings → Privacy & Security → Microphone)"}`,
					"error",
				);
				ctx.ui.setStatus("voice", undefined);
				await rm(tempDir, { recursive: true, force: true }).catch(() => {});
				return;
			}

			let transcript = "";
			try {
				const { stdout } = await execFileAsync(
					"whisper-cli",
					[
						"-m", MODEL_PATH,
						"-l", "en",
						"--no-prints",
						"--no-timestamps",
						"-f", wavPath,
					],
					{ maxBuffer: 8 * 1024 * 1024 },
				);
				transcript = stdout.trim();
			} catch (err) {
				const e = err as Error & { stderr?: string };
				ctx.ui.notify(
					`voice: whisper-cli failed: ${e.stderr?.trim() || e.message}`,
					"error",
				);
			} finally {
				await rm(tempDir, { recursive: true, force: true }).catch(() => {});
				ctx.ui.setStatus("voice", undefined);
			}

			if (transcript.length === 0) {
				ctx.ui.notify("voice: no speech detected", "warning");
				return;
			}

			// Insert at the cursor. `pasteToEditor` triggers Pi's normal
			// paste handling so collapse-large-content etc. behave
			// consistently.
			ctx.ui.pasteToEditor(transcript);
		},
	});

	// If the session ends mid-recording, don't leave `rec` running.
	pi.on("session_shutdown", async () => {
		if (state !== null) {
			const { proc, tempDir } = state;
			state = null;
			try { proc.kill("SIGINT"); } catch {}
			await rm(tempDir, { recursive: true, force: true }).catch(() => {});
		}
	});
}
