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

### 3. Create your `private.nix`

This flake reads per-machine PII (your macOS short username, git
identity) from a file outside the repo:

```
~/.config/dave_nix/private.nix
```

See [`private.nix.example`](./private.nix.example) for the schema.
Create the file however you like — paste contents from a 1Password
Secure Note (web UI works fine on a fresh machine), AirDrop from
another box, or just type it in. It's only a few fields.

```bash
mkdir -p ~/.config/dave_nix
$EDITOR ~/.config/dave_nix/private.nix
```

After the first build, the `nixswitch` alias will auto-copy the
template into place if the file is ever missing.

### 4. Build and Apply

No need to clone the repo. Nix fetches it directly. `--impure` is
required because the flake reads `~/.config/dave_nix/private.nix`:

```bash
nix run nix-darwin/nix-darwin-24.11#darwin-rebuild -- switch \
  --flake github:dh7892/dave_nix#default --impure
```

This single command installs all packages, configures the shell, deploys
dotfiles, sets macOS system preferences, and installs Homebrew casks.

### 5. Post-Setup

**Clone the repo** (for future config edits):

```bash
git clone git@github.com:dh7892/dave_nix.git ~/code/dave_nix
```

**1Password secrets**: Install the 1Password desktop app, enable CLI
integration (Settings > Developer > "Integrate with CLI"), and sign in.
That's it — tools that need API keys (`pi`, `opencode`, ...) are wrapped
with `op run` and pull their keys from 1Password on every invocation. No
plaintext `~/.secrets.sh` step.

The `op run` wrapper uses `private.opAccount` from your
`~/.config/dave_nix/private.nix` to pick which 1Password account to
query. Make sure that field is set.

## Personal info / per-machine config

This repo is public, so it deliberately contains **no** personal
information — no real name, email, macOS username, or any other PII.
All such values live in a single per-machine file:

```
~/.config/dave_nix/private.nix
```

The flake imports it at evaluation time (which is why `--impure` is
required — see step 4 above) and threads the values into the relevant
modules. The schema is documented in
[`private.nix.example`](./private.nix.example).

**To add a new piece of personal/per-machine config:**

1. Add the field (with a placeholder) to `private.nix.example`.
2. Reference it from the relevant Nix module via the `private` arg
   (e.g. `private.fullName`, `private.email`).
3. Add the real value to your own `~/.config/dave_nix/private.nix`
   on every machine before the next `nixswitch`.

Never commit names, emails, usernames, hostnames, tokens, or similar
to any tracked file in this repo. Runtime credentials (API keys, etc.)
are a separate concern: tools that need them are wrapped with `op run`
so keys are fetched from 1Password on each invocation. The 1Password
references live in `~/.secrets.template` (managed by home-manager) and
the account shorthand comes from `private.opAccount`.

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
