{ lib, pkgs, ... }:
{
  services.displayManager.ly = {
    enable = true;
    settings = {
      bg = "0x000a0a0c";
      fg = "0x00e6e7ea";
      border_fg = "0x00232427";
      error_fg = "0x01e2715a";
      clock = "%H:%M  %d.%m.%Y";
      bigclock = "en";
      animation = "none";
    };
  };
  services.displayManager.defaultSession = "hyprland";

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.ly.enableGnomeKeyring = true;
  programs.dconf.enable = true;
  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-archive-plugin
      thunar-volman
    ];
  };
  services.tumbler.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  xdg.mime.defaultApplications = {
    "inode/directory" = "thunar.desktop";
    "application/pdf" = "org.pwmt.zathura.desktop";
    "text/plain" = "org.xfce.mousepad.desktop";
  }
  // lib.genAttrs [
    "image/png"
    "image/jpeg"
    "image/gif"
    "image/webp"
    "image/bmp"
    "image/svg+xml"
    "image/avif"
    "image/tiff"
  ] (_: "imv.desktop");
  services.power-profiles-daemon.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  environment.systemPackages = with pkgs; [
    mousepad
    xarchiver

    adw-gtk3
    (papirus-icon-theme.override { color = "grey"; })
    bibata-cursors
  ];

  fonts.packages = with pkgs; [
    inter
    nerd-fonts.jetbrains-mono
  ];

  fonts.fontconfig = {
    defaultFonts = {
      sansSerif = [ "Inter" ];
      monospace = [ "JetBrainsMono Nerd Font" ];
    };
    antialias = true;
    subpixel.rgba = "none";
    hinting = {
      enable = true;
      style = "slight";
      autohint = true;
    };
  };
}
