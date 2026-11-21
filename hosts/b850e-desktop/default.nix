# Ryzen 7 7800X3D + RTX 3060 desktop, LUKS-encrypted ext4 root.
{ ... }:
{
  imports = [
    ./hardware.nix
    ../../modules/core/base.nix
    ../../modules/core/nvidia.nix
    ../../modules/core/audio.nix
    ../../modules/desktop/desktop.nix
    ../../modules/apps/discord.nix
    ../../modules/desktop/hyprland.nix
  ];

  networking.hostName = "b850e-desktop";

  system.stateVersion = "26.05";
}
