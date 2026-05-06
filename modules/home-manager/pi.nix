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
  piSettings = { };

  settingsJson = builtins.toJSON piSettings;
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
