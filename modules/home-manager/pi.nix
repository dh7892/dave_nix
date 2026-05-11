# Pi (the coding agent) — Nix-managed config surface.
#
# Everything Pi-related on this machine flows through this module:
# extensions, skills, prompt templates, and the global settings.json
# under `~/.pi/agent/`. See `dotfiles/pi/LAYOUT.md` for the full
# convention.
#
# Ground rule: no `pi install` outside the flake. Add addons by
# dropping files into `dotfiles/pi/{extensions,skills,prompts}/`, or
# by listing pi-packages in `piSettings.packages` below. Then run
# `danix-switch`.
{ config, lib, pkgs, ... }:

let
  # ----------------------------------------------------------------
  # Managed Pi settings.
  #
  # This attrset is the source of truth for any setting we want Nix
  # to control. It gets merged *over* whatever Pi has already
  # written to ~/.pi/agent/settings.json (so Pi-owned keys like
  # `lastChangelogVersion` survive). Managed keys always win.
  #
  # Skeleton (TASK-000): intentionally empty. Subsequent tasks add
  # `packages`, `theme`, `defaultProvider`, etc. as needed.
  # ----------------------------------------------------------------
  # Declarative pi-package list. `pi` resolves these on startup and
  # installs anything missing (npm:* via `npm install -g`, git:*
  # via clone under ~/.pi/agent/git/...). Don't `pi install` by
  # hand — add the spec here and run `danix-switch`.
  #
  # Note: any npm package added here is loaded by the Node on PATH,
  # which is pinned to `nodejs_22` in default.nix's myPackages.
  # Several Pi-ecosystem packages require Node ≥ 20, so don't drop
  # that dependency without a replacement.
  #
  # Parked: `npm:whatsapp-pi` (TASK-008) — worked but was the wrong
  # shape for "drive Pi from phone" (self-message gap, Baileys ToS).
  # If we revisit the mobile-reach-out story, `npm:@llblab/pi-telegram`
  # is the better-fitting candidate.
  piSettings = {
    packages = [ ];
  };

  settingsJson = builtins.toJSON piSettings;

  # ----------------------------------------------------------------
  # MCP bridge config (TASK-007).
  #
  # We give Pi access to MCP servers via a *single* tool registered
  # by `dotfiles/pi/extensions/mcp.ts`, which shells out to the
  # `mcporter` CLI (wrapped in modules/home-manager/default.nix).
  # The agent's system prompt grows by ~one tool description plus
  # the list of server names below — not by every MCP tool.
  #
  # Add a server here as e.g.:
  #
  #   context7 = {
  #     command = "npx";
  #     args = [ "-y" "@upstash/context7-mcp" ];
  #     env = { CONTEXT7_API_KEY = "..."; };  # 1Password template, see secrets/
  #   };
  #
  # The shape matches mcporter's mcpServers config (the de-facto
  # MCP client config schema). Default empty: see TASK-013
  # (context7) and TASK-014 (Chrome) for follow-ups that populate it.
  # ----------------------------------------------------------------
  mcpServers = { };

  mcpConfigJson = builtins.toJSON { mcpServers = mcpServers; };
  mcpConfigPath = ".config/mcporter/mcporter.json";
in
{
  # Each entry inside dotfiles/pi/{extensions,skills,prompts} is
  # symlinked individually into ~/.pi/agent/... thanks to
  # `recursive = true`. The parent dirs themselves stay writable,
  # but we never write into them outside the flake.
  home.file = {
    ".pi/agent/extensions" = {
      source = ./dotfiles/pi/extensions;
      recursive = true;
    };
    ".pi/agent/skills" = {
      source = ./dotfiles/pi/skills;
      recursive = true;
    };
    ".pi/agent/prompts" = {
      source = ./dotfiles/pi/prompts;
      recursive = true;
    };
    # Layout doc, also exposed under ~/.config/dave_nix/ next to the
    # other agentic helper prompts so it's easy to point an agent at.
    ".config/dave_nix/pi-LAYOUT.md".source = ./dotfiles/pi/LAYOUT.md;

    # mcporter config rendered from the `mcpServers` attrset above.
    # The `mcp` Pi extension reads this file at load time to discover
    # available server names (for the system-prompt snippet) and
    # passes its absolute path to `mcporter --config` at call time.
    ${mcpConfigPath}.text = mcpConfigJson;
  };

  # settings.json is *not* a symlink: Pi mutates it at runtime
  # (e.g. lastChangelogVersion). At activation time we merge our
  # managed keys over whatever's on disk. jq's `*` deep-merges with
  # right-hand-side winning, so managed keys overwrite Pi's view of
  # those keys but leave everything else alone.
  home.activation.piSettings =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      PI_DIR="$HOME/.pi/agent"
      SETTINGS="$PI_DIR/settings.json"
      MANAGED=${lib.escapeShellArg settingsJson}

      $DRY_RUN_CMD mkdir -p "$PI_DIR"

      # Old symlink from a previous experiment? Replace with a
      # regular file so Pi can write to it.
      if [ -L "$SETTINGS" ]; then
        $DRY_RUN_CMD rm -f "$SETTINGS"
      fi

      existing='{}'
      if [ -f "$SETTINGS" ]; then
        existing=$(${pkgs.coreutils}/bin/cat "$SETTINGS")
      fi

      tmp=$(${pkgs.coreutils}/bin/mktemp)
      printf '%s' "$existing" \
        | ${pkgs.jq}/bin/jq --argjson managed "$MANAGED" '. * $managed' \
        > "$tmp"
      $DRY_RUN_CMD mv "$tmp" "$SETTINGS"
    '';
}
