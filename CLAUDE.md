# Dave's Core Development Environment (dave_nix)

This repository contains Dave's complete macOS development environment configuration using Nix Flakes. It provides a reproducible, declarative setup for Apple Silicon Macs with comprehensive development tooling and custom configurations.

## Repository Overview

**Purpose**: Personal development environment configuration using Nix ecosystem  
**Target Platform**: Apple Silicon macOS (aarch64-darwin)  
**Architecture**: Nix Flakes + nix-darwin + home-manager

## Core Components

### System Management
- **Nix Flakes**: Modern Nix configuration with dependency locking (`flake.nix`, `flake.lock`)
- **nix-darwin**: macOS system-level configuration (`modules/darwin/default.nix`)
- **home-manager**: User-level packages and dotfiles (`modules/home-manager/default.nix`)

### Development Stack

#### Programming Languages & Tools
- **Rust**: Complete toolchain (rustc, cargo, rust-analyzer, rustfmt, clippy)
- **Python**: Via pyenv for version management
- **Go**: Go compiler and tools
- **Node.js**: JavaScript runtime
- **AI Tools**: LLM CLI with local models (orca-mini-3b)

#### Terminal Environment
- **Shell**: Zsh (primary) with vi mode, auto-suggestions, syntax highlighting
- **Alternative Shell**: Nushell with custom theming
- **Terminal**: Kitty with MesloLGS Nerd Font
- **Multiplexer**: Tmux with vim-aware pane navigation
- **Prompt**: Starship cross-shell prompt

#### Development Utilities
- **File Management**: Yazi (terminal file manager), eza (enhanced ls)
- **Search Tools**: Ripgrep, fd, fzf
- **Git Tools**: Lazygit for TUI git operations
- **Text Processing**: Bat (cat replacement), glow (markdown viewer)
- **Shell History**: Atuin for enhanced history management

#### Applications & Services
- **Database**: DBeaver (GUI client)
- **Graphics**: GIMP, Inkscape, ImageMagick
- **Productivity**: Spotify, Raycast launcher
- **Security**: 1Password CLI integration

### Key Features

#### Custom Integrations
- **Vim Setup**: External Neovim configuration via davim flake
- **AI-Assisted Git**: Commit message generation using LLM
- **Secrets Management**: 1Password templates and CLI integration
- **Keyboard Customization**: Karabiner Elements (Caps Lock → Ctrl+B)

#### Shell Configuration Highlights
- **Auto-Tmux**: Automatic tmux session attachment on shell startup
- **AWS Integration**: SSO login aliases for production/staging
- **Vi Mode**: Comprehensive vim bindings in shell
- **Custom Aliases**: Optimized workflow commands

#### System Preferences
- **Finder**: Show all extensions, POSIX paths in titles
- **Dock**: Auto-hide enabled for screen real estate
- **Homebrew**: Managed declaratively via Nix

## File Structure

```
dave_nix/
├── README.md                           # Setup and usage instructions
├── flake.nix                          # Main Nix flake configuration
├── flake.lock                         # Locked dependency versions
└── modules/
    ├── darwin/default.nix             # macOS system configuration
    └── home-manager/
        ├── default.nix                # User packages and programs
        └── dotfiles/                  # Configuration files
            ├── zshrc                  # Zsh shell configuration
            ├── tmux.conf              # Tmux multiplexer config
            ├── config.nu              # Nushell configuration
            ├── karabiner/karabiner.json # Keyboard mappings
            ├── secrets                # 1Password template
            └── [other dotfiles]       # Additional configurations
```

## Usage Instructions

### Initial Setup
```bash
# Clone the repository
git clone [repo-url] ~/code/dave_nix
cd ~/code/dave_nix

# Apply the configuration (see README.md for detailed steps)
nix run nix-darwin -- switch --flake .
```

### Regular Operations
```bash
# Update system configuration
darwin-rebuild switch --flake ~/code/dave_nix

# Update dependencies
nix flake update

# Check configuration status
darwin-rebuild list-generations
```

## Important Notes for AI Assistants

**Nix System Commands**: Do not automatically run `darwin-rebuild switch`, `darwin-rebuild build`, or similar system-level Nix commands. These operations:
- Can take several minutes to complete
- May require user credentials or confirmation
- Should be initiated by the user manually

Instead, when configuration changes are made, ask the user to run the appropriate commands manually (e.g., "Please run `darwin-rebuild switch --flake ~/code/dave_nix` to apply these changes").

## Development Philosophy

This configuration prioritizes:
- **Reproducibility**: Declarative configuration with locked dependencies
- **Modern Tooling**: Latest development tools and utilities
- **Efficiency**: Vim-like navigation, keyboard-centric workflows
- **Integration**: Seamless tool interoperability and custom automations
- **Security**: 1Password integration for secrets management

## Maintenance Notes

- Configuration is actively maintained with regular updates
- Recent changes include Nushell addition and Claude CLI migration
- Uses external flakes for complex configurations (davim for Neovim)
- Homebrew packages managed declaratively through Nix

This environment provides a comprehensive, reproducible development setup optimized for productivity and modern development workflows on macOS.