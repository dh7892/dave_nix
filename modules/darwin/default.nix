{username, pkgs, ...}:
  {

  system.primaryUser = username;

  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };
  # Here go the darwin preferences and config items
  programs.zsh.enable = true;
  
  # Enable Touch ID for sudo authentication
  security.pam.services.sudo_local.touchIdAuth = true;
  security.pam.services.sudo_local.reattach = true;
  environment = {
    systemPackages = with pkgs; [
      coreutils
      pam-reattach
    ];
    shells = [pkgs.bash pkgs.zsh ];
    systemPath = ["/opt/homebrew/bin"];
    pathsToLink = ["/Applications"];
  };



  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  fonts.packages = [ pkgs.nerd-fonts.meslo-lg ];

  system = {
    keyboard.enableKeyMapping = true;
    defaults = {
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
    # Keep brew-managed casks/brews up to date on every `danix-switch`.
    # Without this, nix-darwin only ensures they're installed, never upgraded,
    # which means casks like karabiner-elements drift behind upstream until
    # bumped by hand. Trade-off: rebuilds are slightly slower and any cask
    # can move under us on rebuild — acceptable for our small cask list.
    onActivation.upgrade = true;
    brews = [];
    casks = ["1password-cli" "cmux" "karabiner-elements"];
    taps = ["manaflow-ai/cmux"];
  };
}
