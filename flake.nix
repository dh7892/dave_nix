{
  description = "Config for Dave";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.05-darwin";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # My vim setup
    davim.url = "github:dh7892/davim";
    
    # Claude Code with fast updates
    claude-code.url = "github:sadjow/claude-code-nix";

    # Rust toolchain
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Obsidible: convert/transport between Obsidian and reMarkable
    obsidible.url = "github:dh7892/obsidible";

    # Pi agentic coding tool
    coding-agents.url = "github:kissgyorgy/coding-agents";
  };
  outputs = inputs @ {
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    darwin,
    davim,
    claude-code,
    fenix,
    obsidible,
    coding-agents,
    ...
  }:
  let
    mySystem = "aarch64-darwin";
    username = "dhills";
    pkgs-unstable = import nixpkgs-unstable {
      system = mySystem;
      config.allowUnfree = true;
    };
  in
  {
    darwinConfigurations.default = darwin.lib.darwinSystem {
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
            useGlobalPkgs = true;
            extraSpecialArgs = {inherit davim claude-code fenix obsidible coding-agents mySystem pkgs-unstable;};
            users.${username}.imports = [./modules/home-manager];
          };
        }
      ];
    };
  };
}
