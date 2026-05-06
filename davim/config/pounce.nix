{ pkgs }:

pkgs.vimUtils.buildVimPlugin {
  pname = "pounce";
  version = "2025-13-25";
  src = pkgs.fetchFromGitHub {
    owner = "rlane";
    repo = "pounce.nvim";
    rev = "2e36399ac09b517770c459f1a123e6b4b4c1c171";
    sha256 = "sha256-PTL0wwUE1sO6YlJNPnlNilKyR5kQDBYXiDM5gh6pkuM=";
  };
}
