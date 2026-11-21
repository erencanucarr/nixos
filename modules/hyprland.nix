# Hyprland, the desktop (modules/desktop.nix has the login screen and the rest).
# Its config, the Quickshell bar, the lock screen and notifications live in
# home/hyprland/ and home/quickshell/, linked into place by home/hyprland.nix.
#
# hypridle, mako and the polkit agent are started by Hyprland itself
# (hyprland.lua), not as user services: those would also start on the login
# screen, and outside Hyprland.
{ lib, pkgs, ... }:
let
  # The agent ships in libexec, off PATH.
  polkitAgent = pkgs.writeShellScriptBin "hyprpolkitagent" ''
    exec ${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent "$@"
  '';
in
{
  # The session entry, xdg-desktop-portal-hyprland (screen sharing), polkit.
  programs.hyprland.enable = true;
  # hyprlock with its PAM entry, so it can check the password.
  programs.hyprlock.enable = true;
  # programs.hyprlock turns on hypridle's user service, which would also start
  # on the login screen; hyprland.lua starts hypridle instead.
  services.hypridle.enable = lib.mkForce false;
  # blueman-applet and blueman-manager for bluetooth, from the tray.
  services.blueman.enable = true;

  environment.systemPackages = with pkgs; [
    quickshell # the bar, app drawer and power menu
    hypridle # lock and screens off when idle
    hyprsunset # warm screen (blue-light filter), set with `hyprsunset 0-100`
    mako # notifications
    libnotify # notify-send
    polkitAgent
    networkmanagerapplet # nm-applet, the network tray icon
    pavucontrol # the volume mixer
    playerctl # media keys
    grim # screenshots
    slurp # pick the screenshot's area
    vips # Shot cuts the frozen frame with it (home/quickshell/Shot.qml)
    jq
    xdg-user-dirs
  ];
}
