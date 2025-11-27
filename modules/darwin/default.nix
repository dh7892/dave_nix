{username, pkgs, ...}: 
  {

  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };
  # Here go the darwin preferences and config items
  programs.zsh.enable = true;
  
  # Enable Touch ID for sudo authentication  
  security.pam.enableSudoTouchIdAuth = true;
  environment = {
    systemPackages = with pkgs; [
      coreutils
      karabiner-elements
      pam-reattach
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
    activationScripts.pamReattach = {
      text = ''
        # Add pam_reattach for tmux Touch ID support
        if ! grep -q "pam_reattach.so" /etc/pam.d/sudo; then
          # Insert pam_reattach.so after the Touch ID line but before sudo_local
          sed '/pam_tid.so/a\
auth       optional       ${pkgs.pam-reattach}/lib/pam/pam_reattach.so ignore_ssh' /etc/pam.d/sudo > /tmp/sudo_pam_new && \
          sudo cp /tmp/sudo_pam_new /etc/pam.d/sudo && \
          rm /tmp/sudo_pam_new && \
          echo "Added pam_reattach to /etc/pam.d/sudo for tmux Touch ID support"
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
