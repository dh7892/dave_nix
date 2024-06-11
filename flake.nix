{
  description = "Config for Dave";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable"; # nixos-22.11
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    darwin.url = "github:LnL7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    # Nvim from zmre
    # pwnvim.url = "github:zmre/pwnvim";
    davim.url = "github:dh7892/davim";
  };
  outputs = inputs @ {
    nixpkgs,
    home-manager,
    darwin,
    davim,
    ...
  }: 
  let
    mySystem = "aarch64-darwin";
    myMachine = "Davids-MacBook-Pro";
  in
  {
    darwinConfigurations.${myMachine} = darwin.lib.darwinSystem {
      system = mySystem;
      pkgs = import nixpkgs {
        system = mySystem;
        config.allowUnfree = true;
      };
      modules = [
        ./modules/darwin
        home-manager.darwinModules.home-manager
        {
          home-manager = {
            backupFileExtension = "backup";
            useGlobalPkgs = true;
            # Although people seem to recommend this option, it caused problems for me.
            # Be wary of enabling it without having a way to get a clean shell as a backup!
            # useUserPackages = true;
            extraSpecialArgs = {inherit davim mySystem;};
            users.dhills.imports = [./modules/home-manager];
          };
        }
      ];
    };
  };
}
