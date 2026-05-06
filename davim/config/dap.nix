{
  plugins.dap = {
    enable = true;
      extensions.dap-python.enable = true;
      extensions.dap-ui.enable = true;
      extensions.dap-virtual-text.enable = true;
      signs = {
          dapBreakpoint = {
            text = "🔴";  # or "🔴" or "⬤" or "⭘"
            texthl = "DapBreakpoint";
          };
          dapBreakpointCondition = {
            text = "🔶";  # or "🔶" or "♦"
            texthl = "DapBreakpointCondition";
          };
          dapLogPoint = {
            text = "◆";
            texthl = "DapLogPoint";
          };
          dapStopped = {
            text = "▶";  # or "→" or "⯈"
            texthl = "DapStopped";
          };
        };
  };
}
