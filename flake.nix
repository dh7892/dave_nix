{
  description = "Config for Dave";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-24.11-darwin";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";  # Changed from master to release-24.11
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # My vim setup
    davim.url = "github:dh7892/davim";
    
    # Claude Code with fast updates
    claude-code.url = "github:sadjow/claude-code-nix";
  };
  outputs = inputs @ {
    nixpkgs,
    home-manager,
    darwin,
    davim,
    claude-code,
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
        overlays = [
          # Add the karabiner overlay here
          (self: super: {
            karabiner-elements = super.karabiner-elements.overrideAttrs (old: {
              version = "14.13.0";
              src = super.fetchurl {
                inherit (old.src) url;
                hash = "sha256-gmJwoht/Tfm5qMecmq1N6PSAIfWOqsvuHU8VDJY8bLw=";
              };
              postInstall = ''
              # Ensure driver components match the main version
              mkdir -p $out/Library/Application\ Support/org.pqrs
              cp -r ./src/scripts/uninstaller.applescript $out/scripts/
              cp -r ./src/scripts/relaunch.applescript $out/scripts/
            '';
            });
          })
        ];
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
            extraSpecialArgs = {inherit davim claude-code mySystem;};
            users.${username}.imports = [./modules/home-manager];
          };
        }
      ];
    };
  };
}
