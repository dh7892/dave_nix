{
  pkgs,
  davim,
  claude-code,
  mySystem,
  lib,
  ...
}:
    let
      op-pkg = pkgs.stdenv.mkDerivation rec {
        pname = "1password-cli";
        version = "2.30.3";  # Update this as needed
        
        src = pkgs.fetchurl {
          url = "https://cache.agilebits.com/dist/1P/op2/pkg/v${version}/op_darwin_arm64_v${version}.zip";
          sha256 = "sha256-BHITOgmgWWEZVDwO597ws8CGRjVEMlFqGNv+gx1TbIg=";
        };

        nativeBuildInputs = [ pkgs.unzip ];

        unpackPhase = ''
          unzip $src
        '';

        installPhase = ''
          mkdir -p $out/bin
          cp op $out/bin/
          chmod +x $out/bin/op

          # Add debug output during install
          echo "Installing op to $out/bin/op"
        '';

        meta = with lib; {
          description = "1Password CLI";
          homepage = "https://1password.com/";
          platforms = platforms.darwin;
        };
    };
      tmuxConfig = builtins.readFile ./dotfiles/tmux.conf;
      tpm = pkgs.fetchFromGitHub {
        owner = "tmux-plugins";
        repo = "tpm";
        rev = "v3.1.0";
        sha256 = "18i499hhxly1r2bnqp9wssh0p1v391cxf10aydxaa7mdmrd3vqh9";
      };
      myDavim = davim.packages.${mySystem}.default;
      claudeCodePkg = claude-code.packages.${mySystem}.default;
      myPackages = with pkgs; [dbeaver-bin gimp inkscape imagemagick lazygit raycast cargo git glow yazi spotify ripgrep fd curl less atuin lldb_18 rustc rust-analyzer rustfmt clippy darwin.apple_sdk.frameworks.CoreFoundation libiconv nushell];
    in
    {
  nixpkgs.config.allowUnfree = true;
  home = {
     file.".config/karabiner/karabiner.json" = {
    source =  ./dotfiles/karabiner/karabiner.json;
    onChange = ''
      /bin/launchctl kickstart -k gui/`id -u`/org.pqrs.karabiner.karabiner_console_user_server
    '';
  };
    stateVersion = "22.11";
      packages = myPackages ++ [myDavim op-pkg claudeCodePkg];
    sessionVariables = {
      PAGER = "less";
      EDITOR = "nvim";
    };
    file.".config/prompts/git-commit-prompt.txt".source = ./dotfiles/git-commit-prompt.txt;
    file.".inputrc".source = ./dotfiles/inputrc;
    file.".tmux/plugins/tpm" = {
      source = "${tpm}";
      recursive = true;
    };
    file.".secrets.template".source = ./dotfiles/secrets;
  };
  programs = {
    nushell = {
      enable = true;
      configFile.source = ./dotfiles/config.nu;
      envFile.source = ./dotfiles/env.nu;
    };
    tmux = {
      enable = true;
      plugins = with pkgs; [
        tmuxPlugins.better-mouse-mode
        tmuxPlugins.power-theme
      ];
      baseIndex = 1;
      extraConfig = ''
        ${tmuxConfig}
        set-option -g default-command "${pkgs.zsh}/bin/zsh"
      '';
    };
    bat.enable = true;
    bat.config.theme = "TwoDark";
    fzf.enable = true;
    fzf.enableZshIntegration = true;
    eza.enable = true;
    git.enable = true;
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      shellAliases = {
        ls = "ls --color=auto -F";
        nixswitch = "darwin-rebuild switch --flake ~/code/dave_nix/.#";
        nixup = "pushd ~/code/dave_nix; nix flake update; nixswitch";
        vi = "nvim";
      };
      initExtra = ''
        ${builtins.readFile ./dotfiles/zshrc}
      '';
    };
    starship.enable = true;
    starship.enableZshIntegration = true;

    kitty = {
      enable = true;
      font.name = "MesloLGS Nerd Font Mono";
      font.size = 16;
      keybindings = { };
      settings = {
        shell = "${pkgs.zsh}/bin/zsh";
      };
    };

    # wezterm = {
    #   enable = true;
    #   extraConfig = ''
    # local wezterm = require 'wezterm'
    # local config = {}
    
    # if wezterm.config_builder then
    #   config = wezterm.config_builder()
    # end

    # -- macOS specific settings
    # config.font = wezterm.font('MesloLGS Nerd Font Mono')
    # config.font_size = 13.0
    # config.native_macos_fullscreen_mode = true
    # config.window_decorations = "TITLE | RESIZE"
    
    # -- Try switching between these if you have graphics issues
    # config.front_end = "WebGpu"  -- or try "OpenGL"
    
    # -- Disable ligatures if they're causing display issues
    # config.harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' }
    # config.keys = {
    #     { key = "L", mods = "CMD|SHIFT", action = wezterm.action.ShowDebugOverlay },
    #     { key = "3", mods = "OPT", action = wezterm.action.SendString("#") }
    # }

    # return config
  # '';
# };
  };
}
