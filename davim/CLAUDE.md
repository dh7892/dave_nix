# Neovim Configuration

This repository contains a neovim configuration managed as a Nix flake using nixvim.

## Structure

- `flake.nix` - Main flake entry point
- `config/` - Configuration modules
  - `default.nix` - Main config file (imports all modules)
  - Individual `.nix` files for complex plugin configurations

## Common Tasks

Typical requests will involve:
- Adding new plugins
- Configuring existing plugins
- Adding or modifying keybindings
- Explaining how to use configured features

## Testing Changes

```bash
nix run .        # Test configuration
nix flake check . # Verify configuration
```

## Key Details

- Leader key: `,` (comma)
- Colorscheme: Ayu
- All configuration is in Nix (with `extraConfigLua` for Lua snippets)
- Keybindings defined in `config/default.nix` keymaps array
