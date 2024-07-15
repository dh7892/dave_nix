{pkgs, ...}: {
  users.users.dhills = {
    name = "dhills";
    home = "/Users/dhills";
  };
  # Here go the darwin preferences and config items
  programs.zsh.enable = true;
  environment = {
    shells = [pkgs.bash pkgs.zsh];
    loginShell = pkgs.zsh;
    systemPath = ["/opt/homebrew/bin"];
    pathsToLink = ["/Applications"];
  };
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  environment.systemPackages = [pkgs.coreutils];
  fonts.packages = [(pkgs.nerdfonts.override {fonts = ["Meslo"];})];
  services.nix-daemon.enable = true;
  system = {
    keyboard.enableKeyMapping = true;
    defaults = {
      finder.AppleShowAllExtensions = true;
      finder._FXShowPosixPathInTitle = true;
      dock.autohide = true;
      NSGlobalDomain.AppleShowAllExtensions = true;
    };
    stateVersion = 4;
  };
  homebrew = {
    enable = true;
    caskArgs.no_quarantine = true;
    global.brewfile = true;
    masApps = {};
    casks = ["raycast"];
    # taps = [];
    # brews = [];
  };
}
