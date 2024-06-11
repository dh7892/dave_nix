{
  pkgs,
  davim,
  mySystem,
  ...
}:
    let
      tmuxConfig = builtins.readFile ./dotfiles/tmux.conf;
      myDavim = [davim.packages.${mySystem}.default];
      myPackages = with pkgs; [spotify ripgrep fd curl less atuin];
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
    file.".inputrc".source = ./dotfiles/inputrc;
  };
  programs = {
    tmux = {
      enable = true;
      plugins = with pkgs; [
        tmuxPlugins.better-mouse-mode
      ];
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
