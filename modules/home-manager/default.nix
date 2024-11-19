{
  pkgs,
  davim,
  mySystem,
  ...
}:
    let
      tmuxConfig = builtins.readFile ./dotfiles/tmux.conf;
      tpm = pkgs.fetchFromGitHub {
        owner = "tmux-plugins";
        repo = "tpm";
        rev = "v3.1.0";
        sha256 = "18i499hhxly1r2bnqp9wssh0p1v391cxf10aydxaa7mdmrd3vqh9";
      };
      myDavim = [davim.packages.${mySystem}.default];
      myPackages = with pkgs; [raycast cargo git glow yazi spotify ripgrep fd curl less atuin];
    in
    {
  nixpkgs.config.allowUnfree = true;
  home = {
    stateVersion = "22.11";
      packages = myPackages ++ myDavim;
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
  };
  programs = {
    tmux = {
      enable = true;
      plugins = with pkgs; [
        tmuxPlugins.better-mouse-mode
        tmuxPlugins.power-theme
      ];
      baseIndex = 1;
      extraConfig = tmuxConfig;
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
