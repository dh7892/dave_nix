{
  description = "Config for Dave";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable"; # nixos-22.11
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    darwin.url = "github:LnL7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    # My vim setup
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
    myMachine = "K001-DavidH";
    username = "dhills";
  in
  {
    darwinConfigurations.${myMachine} = darwin.lib.darwinSystem {
      system = mySystem;
      pkgs = import nixpkgs {
        system = mySystem;
        config.allowUnfree = true;
      };
      specialArgs = { inherit username; };
      modules = [
        ./modules/darwin
        home-manager.darwinModules.home-manager
        {
          home-manager = {
            backupFileExtension = "backup";
            useGlobalPkgs = false;
            # Although people seem to recommend this option, it caused problems for me.
            # Be wary of enabling it without having a way to get a clean shell as a backup!
            # useUserPackages = true;
            extraSpecialArgs = {inherit davim mySystem;};
            users.${username}.imports = [./modules/home-manager];
          };
        }
      ];
    };
  };
}
