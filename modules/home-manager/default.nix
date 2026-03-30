{
  pkgs,
  pkgs-unstable,
  davim,
  claude-code,
  obsidible,
  mySystem,
  lib,
  ...
}:
    let
      # To update: bump version, then run:
      #   nix-prefetch-url https://github.com/anomalyco/opencode/releases/download/v<NEW_VERSION>/opencode-darwin-arm64.zip
      # and replace the sha256 with the output.
      opencode-pkg = pkgs.stdenv.mkDerivation rec {
        pname = "opencode";
        version = "1.1.25";

        src = pkgs.fetchurl {
          url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-darwin-arm64.zip";
          sha256 = "00adyjcri52n9y8xwlcx2mgzij420ayqr9aqk865iv0ynv9991j1";
        };

        nativeBuildInputs = [ pkgs.unzip ];

        unpackPhase = ''
          unzip $src
        '';

        installPhase = ''
          mkdir -p $out/bin
          cp opencode $out/bin/
          chmod +x $out/bin/opencode
        '';

        meta = with lib; {
          description = "OpenCode AI coding agent";
          homepage = "https://opencode.ai/";
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
      obsidiblePkg = obsidible.packages.${mySystem}.default;

      # rmc: convert reMarkable .rm files to SVG/PDF/markdown (not in nixpkgs)
      # Note: rmc 0.3.0 pins rmscene >=0.6.0,<0.7.0 but works fine with 0.5.0
      rmc = pkgs.python3Packages.buildPythonApplication {
        pname = "rmc";
        version = "0.3.0";
        format = "pyproject";
        src = pkgs.fetchPypi {
          pname = "rmc";
          version = "0.3.0";
          hash = "sha256-V6/hTVZpQIW2o4KqK5O3uG6yHpPnILFqgpkKoNZRPcs=";
        };
        build-system = [ pkgs.python3Packages.poetry-core ];
        dependencies = with pkgs.python3Packages; [ click rmscene ];
        pythonRelaxDeps = [ "rmscene" ];
      };

      myPackages = with pkgs; [
        # General tools
        atuin
        bacon
        curl
        dbeaver-bin
        fd
        gimp
        git
        glow
        imagemagick
        inkscape
        lazygit
        less
        libiconv
        lldb_18
        nushell
        raycast
        ripgrep
        rmc
        spotify
        typst
        yazi
        # Frameworks
        darwin.apple_sdk.frameworks.CoreFoundation
        # Document tools
        librsvg
        poppler_utils
        pkgs-unstable.rmapi
        # Python tooling
        pkgs-unstable.pyenv
        # Rust toolchain from unstable for latest versions
        pkgs-unstable.cargo
        pkgs-unstable.rustc
        pkgs-unstable.rust-analyzer
        pkgs-unstable.rustfmt
        pkgs-unstable.clippy
      ];
    in
    {
  nixpkgs.config.allowUnfree = true;
  home = {
    stateVersion = "24.11";
      packages = myPackages ++ [myDavim opencode-pkg claudeCodePkg obsidiblePkg];
    sessionVariables = {
      PAGER = "less";
      EDITOR = "nvim";
    };
    file.".config/prompts/git-commit-prompt.txt".source = ./dotfiles/git-commit-prompt.txt;
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
        nixswitch = "darwin-rebuild switch --flake ~/code/dave_nix#default";
        nixup = "pushd ~/code/dave_nix; nix flake update; nixswitch";
        vi = "nvim";
        opencode = "op run --account=my.1password.eu --env-file ~/.secrets.template --no-masking -- opencode";
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
  };
}
