{ lib, pkgs, ... }:
let
  polkitAgent = pkgs.writeShellScriptBin "hyprpolkitagent" ''
    exec ${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent "$@"
  '';
in
{
  programs.hyprland.enable = true;
  programs.hyprlock.enable = true;
  services.hypridle.enable = lib.mkForce false;
  services.blueman.enable = true;

  environment.systemPackages = with pkgs; [
    quickshell
    hypridle
    hyprsunset
    libnotify
    polkitAgent
    networkmanagerapplet
    pavucontrol
    playerctl
    grim
    slurp
    vips
    jq
    xdg-user-dirs
  ];
}
