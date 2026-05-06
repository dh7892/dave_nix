# TASK-011 — Voice dictation into Pi via `whisper.cpp`

Status: pending
Source: `plan/pi-addons-plan.md` Phase 2.5 item 10.
Fanout-suitable: **partly** — the hotkey choice and integration
test want Dave-in-the-loop. The rest is fanout-friendly.

## Goal

Press-and-hold a hotkey inside Pi to record speech; release to
transcribe locally via `whisper.cpp`; the resulting text drops
into Pi's editor. Local-only, English-only, no API keys.

## Decisions already taken

- Engine: **`whisper.cpp`** (local, Apple-Silicon-fast, packageable
  in Nix).
- Integration shape: **Pi-native extension**, using
  `ctx.ui.setEditorText()` to drop the transcript into Pi's
  editor directly.
- Scope: push-to-talk only. No always-on listening. No
  system-wide dictation (use macOS built-in or a paid GUI for
  that, separately).

## Decisions taken at pickup

**Hotkey: `alt+space`, toggle behaviour.**

Reasoning:
- `Cmd+T` (Dave's first instinct) isn't usable — Pi only knows
  `ctrl/shift/alt` modifiers, and macOS terminals don't forward
  Cmd to TUIs anyway.
- `ctrl+t` is taken by `app.thinking.toggle`.
- `alt+space` is unbound in Pi, easy to chord one-handed when
  sitting back from the keyboard, and Kitty (Dave's terminal)
  forwards Option as Meta cleanly.

**"Any other key to stop"** isn't achievable through
`pi.registerShortcut` (it registers a specific chord, not a
"next-keypress" listener). Instead, the same key toggles:
tap `alt+space` to start recording, tap `alt+space` again to
stop and transcribe. Dave OK'd this fallback.

**Recording tool: `sox`** (using its `rec` front-end). 16 kHz mono
16-bit PCM — whisper.cpp's native input format.

**Model: `ggml-base.en.bin`** (~142 MB), fetched declaratively
via `pkgs.fetchurl` and symlinked under
`$HOME/.local/share/whisper-models/`. Marked
`# update-source: skip` in the WRAPPED PACKAGES region because
upstream blobs on Hugging Face don't get re-published; the
`danix-update` prompt was extended with a recipe for the
`skip` hint.

## Plan

1. Choose hotkey (above). Note the choice here.
2. Add `whisper-cpp` (or the appropriate nixpkgs name —
   `openai-whisper-cpp` last I looked) to home-manager
   packages. Confirm the model file (e.g.
   `ggml-base.en.bin`) is fetched declaratively via Nix —
   *no manual downloads*.
3. Write `modules/home-manager/dotfiles/pi/extensions/voice.ts`
   that:
   - Registers a Pi keybinding for the chosen hotkey.
   - On press: starts an audio recording to a tempfile (use
     `sox` or `ffmpeg` — pick one and add to packages).
   - On release: stops recording, runs `whisper.cpp`
     synchronously on the tempfile, captures stdout.
   - Calls `ctx.ui.setEditorText(<existing-text> + transcript)`
     to insert the result at the cursor (or append if cursor
     manipulation isn't exposed).
   - Cleans up the tempfile.
4. Test end-to-end. Note any latency / quality issues in this
   file.
5. `git add`, dry-run-build, commit.

## Acceptance

- Inside Pi, holding the chosen hotkey and speaking, then
  releasing, results in the spoken text appearing in the
  editor within a couple of seconds for a short utterance.
- Works fully offline (test with Wi-Fi off).
- No API keys required, no cloud calls.

## Out of scope

- System-wide dictation (use macOS fn-fn or Wispr Flow as
  personal choice).
- Multi-language support — English-only is fine.
- Real-time streaming transcription — push-to-talk only.
- Voice commands (e.g. "send", "newline"). Plain dictation.
