# Ryzen 7 7800X3D + RTX 3060 desktop, LUKS-encrypted ext4 root.
{ ... }:
{
  imports = [
    ./hardware.nix
    ../../modules/base.nix
    ../../modules/nvidia.nix
    ../../modules/gnome.nix
    ../../modules/discord.nix
  ];

  networking.hostName = "b850e-desktop";

  system.stateVersion = "26.05";
}
