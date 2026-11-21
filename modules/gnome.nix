# GNOME on Wayland with a macOS look: WhiteSur theme, icons and cursors,
# a bottom dock and blurred panels. The settings themselves are per user,
# in home/can.nix.
{ pkgs, unstable, ... }:
{
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    epiphany
  ];

  environment.systemPackages = with pkgs; [
    gnome-tweaks
    gnome-extension-manager
    dconf-editor

    (import ../pkgs/whitesur.nix { inherit unstable; })
    whitesur-icon-theme
    whitesur-cursors

    gnomeExtensions.user-themes
    gnomeExtensions.dash-to-dock
    gnomeExtensions.blur-my-shell
    gnomeExtensions.appindicator
  ];

  # Tray icons for the appindicator extension.
  services.udev.packages = [ pkgs.gnome-settings-daemon ];

  fonts.packages = with pkgs; [
    inter
    nerd-fonts.jetbrains-mono
  ];
}
