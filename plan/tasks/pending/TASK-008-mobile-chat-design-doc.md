# TASK-008 — Mobile / chat reach-out: design doc only

Status: pending
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
