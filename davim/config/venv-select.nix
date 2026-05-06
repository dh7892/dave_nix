{ pkgs }:

pkgs.vimUtils.buildVimPlugin {
  pname = "venv-select";
  version = "2024-05-01";
  src = pkgs.fetchFromGitHub {
    owner = "linux-cultist";
    repo = "venv-selector.nvim";
    rev = "e82594274bf7b54387f9a2abe65f74909ac66e97";
    sha256 = "sha256-XY4hHvslNginl+FxT7owjobInmyhRDwPtNaWOAPpOO0=";
  };
}
