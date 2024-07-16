{
  pkgs,
  davim,
  mySystem,
  ...
}:
    let
      tmuxConfig = builtins.readFile ./dotfiles/tmux.conf;
      myDavim = [davim.packages.${mySystem}.default];
      myPackages = with pkgs; [glow yazi spotify ripgrep fd curl less atuin];
      weechat_overlay = final: prev:
    {
      weechat = prev.weechat.override {
        configure = { availablePlugins, ... }: {
          scripts = with prev.weechatScripts; [
            weechat-otr
            wee-slack
          ];
          # Darwin does not support php
          plugins = builtins.attrValues (builtins.removeAttrs availablePlugins [ "php" ]);
        };
      };
    };
    in
    {
  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [weechat_overlay];
  home = {
    stateVersion = "22.11";
      packages = myPackages ++ myDavim;
    sessionVariables = {
      PAGER = "less";
      EDITOR = "nvim";
    };
    file.".inputrc".source = ./dotfiles/inputrc;
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
      initExtra = builtins.readFile ./dotfiles/zshrc;
    };
    starship.enable = true;
    starship.enableZshIntegration = true;
    kitty = {
      enable = true;
      font.name = "MesloLGS Nerd Font Mono";
      font.size = 16;
      keybindings = { };
    };
  };
}
