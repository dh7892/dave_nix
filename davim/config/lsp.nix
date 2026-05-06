{
  plugins.lsp = {
    enable = true;
    servers = {
      nixd.enable = true;
      pyright = {
  enable = true;
  settings = {
    python = {
      analysis = {
        autoSearchPaths = true;
        useLibraryCodeForTypes = true;
        diagnosticMode = "workspace";
          };
        };
      };
    };
      ruff.enable = true;
      rust_analyzer.enable = false;
      rust_analyzer.installCargo = true;
      rust_analyzer.installRustc = true;
      gopls.enable = true;
    };
    keymaps.lspBuf = {
      K = "hover";
      gD = "references";
      gd = "definition";
      gi = "implementation";
    };
  };
  plugins.lsp-format.enable = true;
  plugins.lsp-lines.enable = true;
}
