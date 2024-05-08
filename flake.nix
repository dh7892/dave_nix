{
  description = "Config for Dave";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable"; # nixos-22.11
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    darwin.url = "github:LnL7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = inputs: {
    darwinConfigurations.Davids-MacBook-Pro = inputs.darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      pkgs = import inputs.nixpkgs {system = "aarch64-darwin";};
      modules = [
        ({pkgs, ...}: {
          users.users.dhills = {
            name = "dhills";
            home = "/Users/dhills";
          };
          # Here go the darwin preferences and config items
          programs.zsh.enable = true;
          environment.shells = [pkgs.bash pkgs.zsh];
          environment.loginShell = pkgs.zsh;
          nix.extraOptions = ''
            experimental-features = nix-command flakes
          '';
          environment.systemPackages = [pkgs.coreutils];
          system.keyboard.enableKeyMapping = true;
          fonts.fontDir.enable = true;
          fonts.fonts = [(pkgs.nerdfonts.override {fonts = ["Meslo"];})];
          services.nix-daemon.enable = true;
          system.defaults.finder.AppleShowAllExtensions = true;
          system.defaults.finder._FXShowPosixPathInTitle = true;
          system.defaults.dock.autohide = true;
          system.defaults.NSGlobalDomain.AppleShowAllExtensions = true;
          system.stateVersion = 4;
        })

        inputs.home-manager.darwinModules.home-manager
        {
          home-manager = {
            backupFileExtension = "backup";
            useGlobalPkgs = true;
            users.dhills.imports = [
              ({pkgs, ...}: {
                home.stateVersion = "22.11";
                # Specify Home manager config items
                home.packages = [pkgs.ripgrep pkgs.fd pkgs.curl pkgs.less];
                home.sessionVariables = {
                  PAGER = "less";
                  EDITOR = "nvim";
                };
                programs.bat.enable = true;
                programs.bat.config.theme = "TwoDark";
                programs.fzf.enable = true;
                programs.fzf.enableZshIntegration = true;
                programs.eza.enable = true;
                programs.git.enable = true;
                programs.zsh.enable = true;
                programs.zsh.enableCompletion = true;
                programs.zsh.autosuggestion.enable = true;
                programs.zsh.syntaxHighlighting.enable = true;
                programs.zsh.shellAliases = {ls = "ls --color=auto -F";};
                programs.starship.enable = true;
                programs.starship.enableZshIntegration = true;
                programs.alacritty = {
                  enable = true;
                  settings.font.normal.family = "MesloLGS Nerd Font Mono";
                  settings.font.size = 16;
                };
              })
            ];
          };
        }
      ];
    };
  };
}
