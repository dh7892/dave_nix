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
    # davim (neovim/nixvim config) lives in this same repo at ./davim and
    # is consumed as a path subflake. It still works standalone — anyone
    # else can use `github:dh7892/dave_nix?dir=davim`.
    davim.url = "path:./davim";
    
    # Claude Code with fast updates
    claude-code.url = "github:sadjow/claude-code-nix";

    # Rust toolchain
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Obsidible: convert/transport between Obsidian and reMarkable
    obsidible.url = "github:dh7892/obsidible";
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
    ...
  }:
  let
    mySystem = "aarch64-darwin";

    # Per-machine private config (PII / username). Lives outside the repo
    # at ~/.config/dave_nix/private.nix. See ./private.nix.example for the
    # schema. Reading $HOME requires --impure (handled by the `danix-switch`
    # helper and documented in the README bootstrap steps).
    #
    # Prefer $SUDO_USER (so `sudo darwin-rebuild` finds the invoking user's
    # home rather than /var/root); fall back to $HOME for non-sudo runs.
    sudoUser = builtins.getEnv "SUDO_USER";
    homeDir =
      if sudoUser != ""
      then "/Users/${sudoUser}"
      else builtins.getEnv "HOME";
    privatePath = "${homeDir}/.config/dave_nix/private.nix";
    private =
      if builtins.pathExists privatePath
      then import privatePath
      else throw ''

        Missing per-machine config: ${privatePath}

        Create that file before building. Schema:

          {
            username  = "your-mac-short-username";
            fullName  = "Your Name";
            email     = "you@example.com";
            opAccount = "my.1password.com";
          }

        A template lives at ./private.nix.example in this repo. The
        `danix-switch` helper will auto-copy it for you on subsequent runs.
        On first bootstrap, create the file by hand (or paste from
        1Password) before invoking darwin-rebuild.
      '';
    username = private.username;

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
            extraSpecialArgs = {inherit davim claude-code fenix obsidible mySystem pkgs-unstable private;};
            users.${username}.imports = [./modules/home-manager];
          };
        }
      ];
    };
  };
}
