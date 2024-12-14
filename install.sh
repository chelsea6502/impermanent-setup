#!/bin/sh

curl https://raw.githubusercontent.com/chelsea6502/impermanent-setup/main/final/disko.nix -o /tmp/disko.nix

sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko /tmp/disko.nix --arg device '"/dev/nvme0n1"'

sudo nixos-generate-config --no-filesystems --root /mnt

cd /mnt/etc/nixos/

sudo rm configuration.nix

sudo nix --experimental-features "nix-command flakes" flake init --template github:chelsea6502/impermanent-setup

nixos-install --root /mnt --flake /mnt/etc/nixos#nixos
