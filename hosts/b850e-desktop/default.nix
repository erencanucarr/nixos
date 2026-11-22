{ ... }:
{
  imports = [
    ./hardware.nix
    ../../modules/core/base.nix
    ../../modules/core/nvidia.nix
    ../../modules/core/audio.nix
    ../../modules/core/dns.nix
    ../../modules/core/tailscale.nix
    ../../modules/desktop/desktop.nix
    ../../modules/apps/discord.nix
    ../../modules/apps/firefox.nix
    ../../modules/desktop/hyprland.nix
  ];

  networking.hostName = "b850e-desktop";

  system.stateVersion = "26.05";
}
