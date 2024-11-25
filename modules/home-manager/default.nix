{
  pkgs,
  davim,
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
      myDavim = [davim.packages.${mySystem}.default];
      myPackages = with pkgs; [lazygit raycast cargo git glow yazi spotify ripgrep fd curl less atuin];
    in
    {
  nixpkgs.config.allowUnfree = true;
  home = {
    stateVersion = "22.11";
      packages = myPackages ++ myDavim ++ [op-pkg];
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
    # file.".config/karabiner" = {
    #   source = ./dotfiles/karabiner;
    #   recursive = false;
    #   onChange = ''
    #     /bin/launchctl kickstart -k gui/`id -u`/org.pqrs.karabiner.karabiner_console_user_server
    #   '';
    # };
  };
  programs = {
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
  };
}
