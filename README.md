# dave_nix

Personal macOS development environment for Apple Silicon, managed
declaratively with Nix Flakes, nix-darwin, and home-manager.

## Bootstrap a New Machine

### 1. Install Nix

Using the Determinate Systems installer (enables flakes by default):

```bash
curl --proto '=https' --tlsv1.2 -sSf -L \
  https://install.determinate.systems/nix | sh -s -- install
```

### 2. Install Homebrew

nix-darwin manages Homebrew packages declaratively but does not install
Homebrew itself:

```bash
/bin/bash -c "$(curl -fsSL \
  https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 3. Build and Apply

No need to clone the repo. Nix fetches it directly:

```bash
nix run nix-darwin/nix-darwin-24.11#darwin-rebuild -- switch \
  --flake github:dh7892/dave_nix#default
```

This single command installs all packages, configures the shell, deploys
dotfiles, sets macOS system preferences, and installs Homebrew casks.

### 4. Post-Setup

**Clone the repo** (for future config edits):

```bash
git clone git@github.com:dh7892/dave_nix.git ~/code/dave_nix
```

**1Password secrets**: Install the 1Password desktop app, enable CLI
integration (Settings > Developer > "Integrate with CLI"), then:

```bash
op inject --account <Account-ID> \
  "${HOME}/.secrets.template" -o "${HOME}/.secrets.sh"
```

If you can't use the 1Password CLI, copy `~/.secrets.template` to
`~/.secrets.sh` and fill in values manually. The file is auto-sourced
by zsh on startup.

## Ongoing Use

| Alias       | Description                                          |
|-------------|------------------------------------------------------|
| `nixswitch` | Apply config changes from `~/code/dave_nix`          |
| `nixup`     | Update all flake inputs and rebuild                  |

## Notes

- **Platform**: Apple Silicon macOS only (`aarch64-darwin`)
- **Neovim**: Managed via the [davim](https://github.com/dh7892/davim) flake
- **Shells**: Zsh (primary, vi mode, auto-tmux) and Nushell
- **Repo location**: Must be at `~/code/dave_nix` for shell aliases to work
