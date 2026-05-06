{ pkgs, ... }:
{
  plugins.rustaceanvim = {
    enable = true;
    settings = {
      dap = {
        adapter = {
          type = "executable";
          name = "lldb";
          command = "${pkgs.lldb_18}/bin/lldb-dap";
        };
      };
      server = {
        cmd = ["rust-analyzer"];
        default_settings = {
          "rust-analyzer" = {
            inlayHints = {
              enable = true;
              bindingModeHints.enable = true;
              closureReturnTypeHints.enable = "always";
              discriminantHints.enable = "always";
              expressionAdjustmentHints.enable = "always";
              lifetimeElisionHints.enable = "always";
              parameterHints.enable = true;
              typeHints.enable = true;
              chainingHints.enable = true;
            };

          };
        };
      };
    };
  };
}
