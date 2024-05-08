# README

This is my nix config. It should allow me to re-create my preferred env in any machine.

For now, it only supports Mac with Apply silicon

## Setup

install the nix package manager

build this flake with `nix --extra-experimental-features "nix-command flakes" build .#darwinConfigurations.Davids-MacBook-Pro.system`

If the host name is not `Davids-MacBook-Pro`, you need to edit the flake to change the machine name to match

Once this has run successfully, you should have a results folder and can run:

`./result/sw/bin/darwin-rebuild switch --flake <path-to-this-folder>`


