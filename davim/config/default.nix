{ pkgs, ... }:
let
  pounce = pkgs.callPackage ./pounce.nix { };
  venv-select = pkgs.callPackage ./venv-select.nix { };

in
{
  imports = [ ./avante.nix ./bufferline.nix ./dap.nix ./telescope.nix ./which-key.nix ./treesitter.nix ./lsp.nix ./copilot-vim.nix ./rustaceanvim.nix ];
  # Import all your configuration modules here
  config = {
    colorschemes.ayu = {
      enable = true;
      settings.overrides = {
        NonText = {
          fg = "#5C5C5C"; bg = "NONE"; italic = true;
        };
      };
    };
    globals.mapleader = ",";
    opts = {
      number = true;
      relativenumber = true;
      scrolloff = 5;
      sidescrolloff = 5;
    };
    extraPlugins = [ pounce venv-select ];
    extraConfigLua = ''
    -- Setup Venv Selector
    require('venv-selector').setup {name = ".venv"}
    vim.keymap.set('n', '<Leader>vs', '<cmd>VenvSelect<CR>')
    vim.keymap.set('n', '<Leader>vc', '<cmd>VenvSelectCached<CR>')

    -- Command to toggle inline diagnostics
  vim.api.nvim_create_user_command(
    'DiagnosticsToggleVirtualText',
    function()
      local current_value = vim.diagnostic.config().virtual_text
      if current_value then
        vim.diagnostic.config({virtual_text = false})
      else
        vim.diagnostic.config({virtual_text = true})
      end
    end,
    {}
  )

-- Terminal keymaps
vim.keymap.set('t', '<Esc>', '<C-\\><C-n>', {noremap = true})

  -- Pounce keymaps
vim.keymap.set('n', 's', '<cmd>Pounce<CR>')

  -- Debugging keymaps
vim.keymap.set('n', '<F5>', function() require('dap').continue() end)
vim.keymap.set('n', '<F10>', function() require('dap').step_over() end)
vim.keymap.set('n', '<F11>', function() require('dap').step_into() end)
vim.keymap.set('n', '<F12>', function() require('dap').step_out() end)
vim.keymap.set('n', '<Leader>b', function() require('dap').toggle_breakpoint() end)

  -- Command to toggle diagnostics
  vim.api.nvim_create_user_command(
    'DiagnosticsToggle',
    function()
      local current_value = vim.diagnostic.is_disabled()
      if current_value then
        vim.diagnostic.enable()
      else
        vim.diagnostic.disable()
      end
    end,
    {}
  )

  -- Telescope: Custom action to toggle hidden files
  local telescope_actions = require('telescope.actions')
  local telescope_action_state = require('telescope.actions.state')

  local toggle_hidden = function(prompt_bufnr)
    local picker = telescope_action_state.get_current_picker(prompt_bufnr)
    local finder = picker.finder

    -- Toggle the options
    finder.hidden = not finder.hidden
    finder.no_ignore = not finder.no_ignore

    -- Refresh the picker
    picker:refresh(finder, { reset_prompt = false })
  end

  require('telescope').setup({
    defaults = {
      mappings = {
        i = {
          ['<C-h>'] = toggle_hidden,
        },
        n = {
          ['<C-h>'] = toggle_hidden,
        },
      },
    },
  })
    '';
  keymaps = [
    {
      action = "<cmd>DiagnosticsToggle<CR>";
      key = "<leader>d";
      options = {
        silent = true;
        desc = "Toggle Diagnistic info";
      };
    }
    {
      action = "<cmd>DiagnosticsToggleVirtualText<CR>";
      key = "<leader>i";
      options = {
        silent = true;
        desc = "Toggle Inline Diagnistic text";
      };
    }
    {
      action = "<cmd>Lspsaga code_action<CR>";
      key = "<leader>c";
      options = {
        silent = true;
        desc = "Code actions (imports, match arms, etc)";
      };
    }
    {
      action = "function() require('telescope.builtin').find_files({ hidden = true, no_ignore = true }) end";
      key = "<leader>E";
      lua = true;
      options = {
        silent = true;
        desc = "Telescope find all files (including hidden/ignored)";
      };
    }
    {
      action = "<cmd>NvimTreeToggle<CR>";
      key = "<leader>t";
      options = {
        silent = true;
        desc = "Toggle File Tree";
      };
    }
    {
      action = "<cmd>bnext<CR>";
      key = "gt";
      options = {
        silent = true;
        desc = "Next buffer";
      };
    }
    {
      action = "<cmd>bprev<CR>";
      key = "gT";
      options = {
        silent = true;
        desc = "Previous buffer";
      };
    }
    {
      action = "<cmd>lua vim.lsp.buf.rename()<CR>";
      key = "<leader>r";
      options = {
        silent = true;
        desc = "Rename current symbol";
      };
    }
    {
      mode = "n";
      key = "<leader>h";
      action = "<cmd>lua local enabled = vim.lsp.inlay_hint.is_enabled(); vim.lsp.inlay_hint.enable(not enabled)<CR>";
      options = {
        desc = "Toggle inlay hints";
        silent = true;
      };
    }
    {
        mode = "n";
        key = "<F5>";
        action = "require('dap').continue";
        lua = true;
      }
      {
        mode = "n";
        key = "<F10>";
        action = "require('dap').step_over";
        lua = true;
      }
      {
        mode = "n";
        key = "<F11>";
        action = "require('dap').step_into";
        lua = true;
      }
      {
        mode = "n";
        key = "<F12>";
        action = "require('dap').step_out";
        lua = true;
      }
      {
        mode = "n";
        key = "<Leader>b";
        action = "require('dap').toggle_breakpoint";
        lua = true;
        options = {
          desc = "Toggle breakpoint";
        };
      }
      # Optional: Toggle DAP UI
      {
        mode = "n";
        key = "<Leader>u";
        action = "require('dapui').toggle";
        lua = true;
        options = {
          desc = "Toggle DAP UI";
        };
      }

  ];
  plugins = {
    web-devicons.enable = true;
    crates.enable = true;
    floaterm.enable = true;
    # tmux-navigator disabled in favour of zellij-nav.nvim (see zellij-nav.nix)
    # tmux-navigator.enable = true;
    toggleterm.enable = true;
    commentary.enable = true;
    lspsaga.enable = true;
    lspsaga.lightbulb.enable = false;
    # Possible plugins to try:
    #surround = extra motions for surrounding text
    #spider = moving by words works differently (e.g. sub-words)
    #statuscol = status column - I started some setup, but couldn't seem to get it working got a sub-module ready for it
    # neoscroll
    # noice
    nvim-tree = {
      enable = true;
      updateFocusedFile.enable = true;
      updateFocusedFile.updateRoot = true;
    };
    notify.enable = true;
    nix.enable = true;
    neoscroll.enable = true;
  };

  };
}
