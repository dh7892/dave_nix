{
  config,
  pkgs,
  pkgs-unstable,
  davim,
  claude-code,
  fenix,
  obsidible,
  mySystem,
  private,
  lib,
  ...
}:
    let
      # ============================================================
      # WRAPPED PACKAGES — BEGIN
      #
      # Every derivation between the BEGIN and END markers is manually
      # pinned (version + hash) and therefore needs periodic updates.
      # The `danix-update` helper launches an agent that reads this
      # region, detects the fetcher used by each `src = ...`, and bumps
      # `version`/`rev` plus the corresponding hash.
      #
      # To add a new manually-pinned package: define it inside this
      # region and prefix it with a `# update-source:` comment that
      # tells the agent where to look for the latest version. Anything
      # outside this region is considered out of scope for the updater.
      # ============================================================

      # update-source: github-release anomalyco/opencode (asset: opencode-darwin-arm64.zip)
      opencode-pkg = pkgs.stdenv.mkDerivation rec {
        pname = "opencode";
        version = "1.14.38";

        src = pkgs.fetchurl {
          url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-darwin-arm64.zip";
          sha256 = "0p0ykc10xyqx1b76s64s5sfmkzlzh5ap3135b50wk9v0y2g3v6jl";
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

      # update-source: github-release badlogic/pi-mono (asset: pi-darwin-arm64.tar.gz)
      pi-pkg = pkgs.stdenv.mkDerivation rec {
        pname = "pi-coding-agent";
        version = "0.73.0";

        src = pkgs.fetchurl {
          url = "https://github.com/badlogic/pi-mono/releases/download/v${version}/pi-darwin-arm64.tar.gz";
          sha256 = "0c1d1mw7gbk0n58xlhgwahrfakhqf42lqj6kwsx5dgyf7pww630v";
        };

        unpackPhase = ''
          tar -xzf $src
        '';

        installPhase = ''
          # Install everything into lib/ so the Bun binary can find package.json,
          # wasm files, themes, and export-html assets relative to itself.
          mkdir -p $out/lib/pi-coding-agent $out/bin
          cp -r pi/. $out/lib/pi-coding-agent/
          chmod +x $out/lib/pi-coding-agent/pi
          ln -s $out/lib/pi-coding-agent/pi $out/bin/pi
        '';

        meta = with lib; {
          description = "Pi — minimal terminal coding agent with TUI";
          homepage = "https://github.com/badlogic/pi-mono";
          platforms = platforms.darwin;
        };
    };

      # update-source: github-tag tmux-plugins/tpm (rev pinned to a release tag)
      tpm = pkgs.fetchFromGitHub {
        owner = "tmux-plugins";
        repo = "tpm";
        rev = "v3.1.0";
        sha256 = "18i499hhxly1r2bnqp9wssh0p1v391cxf10aydxaa7mdmrd3vqh9";
      };

      # update-source: pypi rmc
      # Note: rmc 0.3.0 pins rmscene >=0.6.0,<0.7.0 but works fine with 0.5.0;
      # if a future release relaxes this, the `pythonRelaxDeps` line may be
      # removable — flag for human review rather than editing it automatically.
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

      # ============================================================
      # WRAPPED PACKAGES — END
      # ============================================================

      # pi-fanout — fan out task .md files to parallel `pi` sessions,
      # each in its own git worktree and Zellij tab. See
      # plan/tasks/pending/TASK-001-pi-fanout.md for the design.
      # NOT a danix-* helper: it's repo-agnostic and might travel.
      pi-fanout = pkgs.writeShellApplication {
        name = "pi-fanout";
        runtimeInputs = with pkgs; [ git gum zellij coreutils gnused gnugrep findutils pi-pkg ];
        text = builtins.readFile ./dotfiles/pi-fanout.sh;
      };

      tmuxConfig = builtins.readFile ./dotfiles/tmux.conf;
      myDavim = davim.packages.${mySystem}.default;
      claudeCodePkg = claude-code.packages.${mySystem}.default;
      obsidiblePkg = obsidible.packages.${mySystem}.default;

      # Complete stable Rust toolchain via fenix
      rustToolchain = fenix.packages.${mySystem}.stable.withComponents [
        "cargo"
        "clippy"
        "rustc"
        "rustfmt"
        "rust-analyzer"
      ];

      myPackages = [ pi-fanout ] ++ (with pkgs; [
        # General tools
        aerospace
        bacon
        zellij
        curl
        dbeaver-bin
        fd
        gimp
        git
        glow
        gum
        httpie
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
        # Document tools
        librsvg
        poppler_utils
        pkgs-unstable.rmapi
        # Python tooling (pyenv managed via programs.pyenv)
        # Rust toolchain (stable, via fenix)
        rustToolchain
      ]);
    in
    {
  imports = [
    ./pi.nix
  ];
  home = {
    stateVersion = "25.05";
      packages = myPackages ++ [myDavim opencode-pkg claudeCodePkg obsidiblePkg pi-pkg];
    sessionVariables = {
      PAGER = "less";
      EDITOR = "nvim";
    };
    sessionPath = [
      "$HOME/go/bin"
      "$HOME/.npm-global/bin"
    ];
    file.".tmux/plugins/tpm" = {
      source = "${tpm}";
      recursive = true;
    };
    file.".secrets.template".source = ./dotfiles/secrets;
    # zellij.kdl is templated: `@HOME@` is replaced with the user's home dir
    # because zellij's `Run` action doesn't expand ~ or $HOME at runtime.
    file.".config/zellij/config.kdl".text =
      builtins.replaceStrings
        [ "@HOME@" ]
        [ config.home.homeDirectory ]
        (builtins.readFile ./dotfiles/zellij.kdl);
    file.".config/zellij/cheatsheet.txt".source = ./dotfiles/zellij-cheatsheet.txt;
    file.".config/karabiner/karabiner.json" = {
      source = ./dotfiles/karabiner/karabiner.json;
      force = true;
    };
    file.".aerospace.toml".source = ./dotfiles/aerospace.toml;
    file.".config/dave_nix/nix-update-wrapped-prompt.md".source = ./dotfiles/nix-update-wrapped-prompt.md;
    file.".config/dave_nix/danix-add-prompt.md".source = ./dotfiles/danix-add-prompt.md;
    file.".config/dave_nix/danix-ask-prompt.md".source = ./dotfiles/danix-ask-prompt.md;
    file.".config/dave_nix/danix-vim-prompt.md".source = ./dotfiles/danix-vim-prompt.md;
    file.".config/dave_nix/danix-pi-prompt.md".source = ./dotfiles/danix-pi-prompt.md;
    # Plain-text 1Password account shorthand, written from `private.opAccount`,
    # so non-interactive shells (e.g. the `_nixupdate_wrapped_run` worker) can
    # read it without going through zsh aliases.
    file.".config/dave_nix/op-account".text = private.opAccount + "\n";
    # Absolute path to this repo's local clone. Read by shell helpers
    # (e.g. `_nixupdate_wrapped_run` in zshrc) that need to cd into
    # the repo without hardcoding the path.
    file.".config/dave_nix/repo-path".text = private.repoPath + "\n";
  };
  programs = {
    atuin = {
      enable = true;
      enableZshIntegration = true;
    };
    pyenv = {
      enable = true;
      enableZshIntegration = true;
    };
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
    git = {
      enable = true;
      userName = private.fullName;
      userEmail = private.email;
      aliases = {
        hist = ''!git --no-pager log --pretty=format:"%h %ad | %s%d [%an]" --graph --date=short'';
        co = "checkout";
      };
      extraConfig = {
        push.autoSetupRemote = true;
        rerere.enabled = true;
      };
    };
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      shellAliases = {
        ls = "ls --color=auto -F";
        lg = "lazygit";
        # The real implementations of `danix-switch`, `danix-up`, `danix-update`,
        # `danix-add`, and the `danix` launcher itself live as functions in
        # dotfiles/zshrc. The shell aliases below are short-lived deprecation
        # shims for the old `nix*` names; remove after a transition period.
        nixswitch = "echo '(deprecated: use danix-switch)' >&2; danix-switch";
        nixup = "echo '(deprecated: use danix-up)' >&2; danix-up";
        nixupdate-wrapped = "echo '(deprecated: use danix-update)' >&2; danix-update";
        vi = "nvim";
        # API-key-bearing tools are wrapped with `op run` so the key is pulled
        # fresh from 1Password each invocation; nothing sensitive lands on disk.
        # Requires the 1Password desktop app installed and CLI integration enabled.
        opencode = "op run --account=${private.opAccount} --env-file ~/.secrets.template --no-masking -- opencode";
        pi = "op run --account=${private.opAccount} --env-file ~/.secrets.template --no-masking -- pi";
      };
      defaultKeymap = "viins";
      initContent = ''
        ${builtins.readFile ./dotfiles/zshrc}
      '';
    };
    starship.enable = true;
    starship.enableZshIntegration = true;

    kitty = {
      enable = true;
      font.name = "MesloLGS Nerd Font Mono";
      font.size = 16;
      settings = {
        shell = "${pkgs.zsh}/bin/zsh";
      };
    };
  };
}
