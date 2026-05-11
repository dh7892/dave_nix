# TASK-008 — Mobile / chat reach-out: design doc only

Status: parked (2026-05-11) — tried `whatsapp-pi`, wrong shape;
likely next attempt is `@llblab/pi-telegram` once Dave has
Telegram installed on his Android phone.

## What happened

1. Tried [`whatsapp-pi`](https://pi.dev/packages/whatsapp-pi)
   (npm: `whatsapp-pi`, gh: `RaphaCastelloes/whatsapp-pi`, MIT)
   as a quick MVP for the mobile-reach-out story.
2. Got it installed: added `npm:whatsapp-pi` to
   `piSettings.packages`, fixed a Node version issue (a stale
   `/usr/local/bin/node` v18.16.1 from 2023 was shadowing
   everything; resolved by adding `nodejs_22` to
   `myPackages` in `modules/home-manager/default.nix`).
3. Paired the laptop as a WhatsApp companion device via the
   `/whatsapp` menu and QR code.
4. Realised the design fit was poor for Dave's actual goal
   ("drive my running Pi session from my phone"):
   - `whatsapp-pi` links the laptop as a *companion device on
     Dave's own WhatsApp account*. There is no separate "bot
     account". So to send a prompt "to Pi", you have to either
     (a) message yourself from a second number / second account,
     or (b) route through a group containing yourself plus
     someone allow-listed. The mental model is awkward.
   - Baileys is unofficial and against WhatsApp ToS, so any
     bot-like behaviour carries a (small but real) account-ban
     risk.
   - Chat-bubble UI flattens the rich Pi TUI (diff viewer,
     syntax highlighting, etc.) into text — OK for nudging,
     bad for actual review.
5. Removed `npm:whatsapp-pi` from `piSettings.packages` and
   parked the task. **Kept** the `nodejs_22` addition in
   `default.nix` — several other Pi-ecosystem packages also
   require Node ≥ 20, and the stale `/usr/local/bin/node`
   would have bitten us regardless.

## Better-fitting candidates for next attempt

Not started; recorded here so we don't re-do the survey:

- **`@llblab/pi-telegram`** (npm, MIT, ~4.7K dl/mo) — purpose-built
  Telegram bot adapter for Pi. Real bot account via @BotFather
  (no self-message gap), first user to `/start` becomes exclusive
  owner (clean auth), official Telegram API (no ToS risk), works
  fine on Android. Likely the right next thing to try **once
  Dave has Telegram installed on his phone**.
- **SSH + tmux/zellij + Tailscale** — different shape entirely:
  put the real Pi TUI on the phone via Termux/Termius. Best for
  "I want to *see* the session", not just chat to it. Considered
  but not started.

Neither has been actioned. When the task is unparked, pick one
(or both) deliberately rather than defaulting to the previous
WhatsApp path.

## Cleanup left behind from the whatsapp-pi experiment

Low-priority, do whenever convenient:

- `~/.npm-global/lib/node_modules/whatsapp-pi` (the npm install
  pi did under the hood) is still present and will sit unused
  until removed. `rm -rf ~/.npm-global/lib/node_modules/whatsapp-pi`
  cleans it.
- `~/.pi/whatsapp-pi/` holds the linked-device credentials. The
  laptop will still appear as a linked device on Dave's WhatsApp
  account until either that directory is removed *and* the
  device is unlinked from the WhatsApp app (Settings → Linked
  Devices → tap the entry → Log Out). Worth doing for hygiene.
- The stale `/usr/local/bin/node` (Node 18.16.1, June 2023) is
  still on disk, just shadowed by `nodejs_22` from Nix. Optional
  cleanup: `sudo rm /usr/local/bin/{node,npm,npx}` (or the
  nodejs.org uninstaller if it left one).

## Follow-ups (deferred until unparked)

- Decide between Telegram bot vs. SSH-into-real-TUI (or both).
- For whichever path: design the always-on story (launchd?
  zellij session that survives logout? Tailscale on by default?).
- Allow-list / auth policy review for whichever channel.

---

# Original task brief (preserved for context)

Source: `plan/pi-addons-plan.md` Phase 2 item 7.
Fanout-suitable: **NO**. This is a research task whose output is a
design doc; it requires extended back-and-forth with Dave. Do not
fan out — work it interactively in a normal Pi session.

## Goal

Produce a written design proposal for "Pi can reach out to Dave on a
mobile-accessible channel when something needs attention, and Dave
can reply to steer the agent". **No code in this task.** Output is
`plan/pi-mobile-notifications-design.md`.

## Topics the doc must cover

### 1. Outbound channels

For each, summarise: cost, setup complexity, latency, message richness,
whether it's Nix-manageable, and how it fares under the "everything
through Nix" rule.

- Slack incoming webhook.
- ntfy.sh (self-hosted or public) + iOS Shortcut → WhatsApp/SMS.
- Twilio WhatsApp Business API.
- Plain APNs / Pushover / Bark (iOS push services).
- Telegram bot.
- Email / SMTP (low-tech baseline).

### 2. Inbound steering surface

How does a reply on the mobile channel actually drive the agent on
Dave's laptop?

- Pi's RPC mode (see `docs/rpc.md` in the pi-coding-agent docs) —
  what's the always-on listener look like?
- launchd agent? Systemd-flavour for darwin via nix-darwin services?
- Network exposure options: Tailscale Funnel, Cloudflare Tunnel,
  ngrok-free, none-at-all-and-poll-instead.

### 3. Security model

This is the hard part. Cover:

- Who can send messages to the bot, and what are they authorised
  to do? (Anyone who DMs the Slack bot? Anyone with the ntfy
  topic name? Pre-shared HMAC?)
- How is the listener authenticated to *Pi* — i.e. what stops a
  rogue HTTP request from running arbitrary commands on Dave's
  laptop?
- What happens if the laptop is asleep / locked / offline?
- Audit trail: where do incoming commands get logged?

### 4. Cost / privacy trade-offs

Per channel:

- Does the message body pass through a third-party server in
  plaintext? (Slack: yes. Telegram: yes. ntfy self-hosted: no.
  Twilio: yes.)
- What's the monthly floor?
- Vendor lock-in / portability if Dave changes phone/OS.

### 5. Recommendation

Pick a primary outbound + inbound combo. Justify against the
above axes. Identify the smallest end-to-end MVP that proves
the security model is sound.

## Process

This is interactive work. Plan to:

1. Draft section by section, asking Dave clarifying questions
   (which iOS/Mac he uses, whether he already has a Tailscale
   tailnet, whether Slack DMs are acceptable for a private-team
   bot, whether he wants outbound-only first as a v0).
2. Land the design doc.
3. Spin out a follow-up TASK-008b once Dave has agreed the
   recommendation.

## Acceptance

- `plan/pi-mobile-notifications-design.md` exists, covers all
  five sections above, and ends with a concrete recommended
  MVP that Dave has signed off on.
- A follow-up implementation task (TASK-008b or similar) is
  drafted but **not** yet started.

## Notes

- New per-machine fields the design might require (phone numbers,
  webhook URLs, bot tokens) must be planned through
  `~/.config/dave_nix/private.nix`. Schema additions go in
  `private.nix.example`.
- Resist scope creep into voice / Siri / Shortcut-in-from-Watch
  during this round. Keep the doc to text channels first.
