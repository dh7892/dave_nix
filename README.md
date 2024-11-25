# README

This is my nix config. It should allow me to re-create my preferred env in any machine.

For now, it only supports Mac with Apply silicon

## Setup

install the nix package manager

build this flake with `nix --extra-experimental-features "nix-command flakes" build .#darwinConfigurations.Davids-MacBook-Pro.system`

If the host name is not `Davids-MacBook-Pro`, you need to edit the flake to change the machine name to match

Once this has run successfully, you should have a results folder and can run:

`./result/sw/bin/darwin-rebuild switch --flake <path-to-this-folder>`

### 1 Password and secrets

This flake will install the 1password cli tools. However, for it to work, you will need to have installed the main 1pwd app and enabled CLI interaction (in the app, settings->developer->Integrate with CLI

In order to get secrets from 1pwd into our shell, we have a .secrets.template file (in home directory). You can run the following command to set up the secrets:

```shell
op inject --account <Account ID> "${HOME}/.secrets.template" -o "${HOME}/.secrets.sh"
```

Or, if you can't get 1pwd's CLI working, you can just manually copy the template over and edit the secret keys.

If the secrets file is place, it will be sourced by the shell so it should work in any new shells.


