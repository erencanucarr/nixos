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

  # The fonts and rendering xeome/dots uses (home/.config/fontconfig/fonts.conf).
  # GNOME's own UI takes its fonts from dconf (home/can.nix); everything else
  # (Firefox, Discord, Electron and Qt apps) asks fontconfig for "sans-serif"
  # and "monospace", which would otherwise be DejaVu.
  fonts.fontconfig = {
    defaultFonts = {
      sansSerif = [ "Inter" ];
      monospace = [ "JetBrainsMono Nerd Font" ];
    };
    antialias = true;
    # Grayscale, not subpixel: GTK 4 already renders grayscale.
    subpixel.rgba = "none";
    hinting = {
      enable = true;
      style = "slight";
      autohint = true;
    };
  };
}
