# What the desktop needs besides Hyprland (modules/hyprland.nix): the login
# screen, the pieces GNOME used to bring along, a few GNOME apps, and the look
# GTK apps read (adw-gtk3, WhiteSur icons and cursors, Inter and JetBrains
# Mono). The per-user settings are in home/can.nix.
{ pkgs, ... }:
{
  # GDM as the login screen, straight into Hyprland.
  services.displayManager.gdm.enable = true;
  services.displayManager.defaultSession = "hyprland";

  # Saved passwords (Wi-Fi, Firefox, 1Password), unlocked at login by GDM.
  services.gnome.gnome-keyring.enable = true;
  # The settings store GTK apps and home/can.nix's dconf.settings use.
  programs.dconf.enable = true;
  # Trash, network places and phones in Nautilus; USB drives mounting.
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  # Power profiles for the bar's power menu (performance, balanced, power
  # saver); on amd-pstate-epp it sets the CPU's energy preference.
  services.power-profiles-daemon.enable = true;
  # File pickers and the light/dark setting for apps, next to Hyprland's own
  # portal (screen sharing).
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  environment.systemPackages = with pkgs; [
    nautilus # files
    loupe # images
    papers # PDFs
    gnome-calculator
    gnome-text-editor
    file-roller # archives
    dconf-editor

    adw-gtk3
    whitesur-icon-theme
    whitesur-cursors
  ];

  fonts.packages = with pkgs; [
    inter
    nerd-fonts.jetbrains-mono
  ];

  # The fonts and rendering xeome/dots uses (home/.config/fontconfig/fonts.conf).
  # GTK apps take their fonts from dconf (home/can.nix); everything else
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
