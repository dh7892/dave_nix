{username, pkgs, ...}: 
  {

  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };
  # Here go the darwin preferences and config items
  programs.zsh.enable = true;
  environment = {
    systemPackages = with pkgs; [
      coreutils
      karabiner-elements
    ];
    shells = [pkgs.bash pkgs.zsh ];
    systemPath = ["/opt/homebrew/bin"];
    pathsToLink = ["/Applications"];
  };



  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  # fonts.packages = [(pkgs.nerdfonts.override {fonts = ["Meslo"];})];
  services.nix-daemon.enable = true;
  services.karabiner-elements.enable = true;
  system = {
    keyboard.enableKeyMapping = true;
    defaults = {
      finder.AppleShowAllExtensions = true;
      finder._FXShowPosixPathInTitle = true;
      dock.autohide = true;
      NSGlobalDomain.AppleShowAllExtensions = true;
    };
    stateVersion = 4;
    activationScripts.llmPlugin = {
      text = ''
        if ! llm plugin list | grep -q llm-gpt4all; then
          llm install llm-gpt4all
        fi
      '';
    };
  };
  homebrew = {
    enable = true;
    caskArgs.no_quarantine = true;
    global.brewfile = true;
    masApps = {};
    brews = ["llm"];
    # taps = [];
  };
}
