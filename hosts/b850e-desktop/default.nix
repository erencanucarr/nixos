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
    ../../modules/desktop/screenshot.nix
    ../../modules/apps/discord.nix
    ../../modules/apps/firefox.nix
    ../../modules/apps/headset.nix
    ../../modules/apps/taildrop.nix
    ../../modules/desktop/hyprland.nix
  ];

  ecu.screenshot.enable = true;
  ecu.taildrop.enable = true;
  ecu.headset.enable = true;

  networking.hostName = "b850e-desktop";

  system.stateVersion = "26.05";
}
