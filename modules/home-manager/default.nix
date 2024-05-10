{
  pkgs,
  pwnvim,
  ...
}: {
  home = {
    stateVersion = "22.11";
    packages = with pkgs; [ripgrep fd curl less pwnvim.packages."aarch64-darwin".default];
    sessionVariables = {
      PAGER = "less";
      EDITOR = "nvim";
    };
    file.".inputrc".source = ./dotfiles/inputrc;
  };
  programs = {
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
      };
    };
    starship.enable = true;
    starship.enableZshIntegration = true;
    kitty = {
      enable = true;
      font.name = "MesloLGS Nerd Font Mono";
      font.size = 16;
    };
  };
}
