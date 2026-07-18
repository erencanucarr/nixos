{ config, lib, pkgs, ... }:

{
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [ alacritty ];
  };

  programs.thunar = {
    enable = true;
    plugins = with pkgs; [ thunar-volman thunar-archive-plugin ];
  };

  services.gvfs.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
      xdg-desktop-portal-gtk
    ];
    config.sway = {
      default = [ "gtk" ];
      "org.freedesktop.impl.portal.Screenshot" = "wlr";
      "org.freedesktop.impl.portal.ScreenCast" = "wlr";
    };
    wlr = {
      enable = true;
      settings = {
        screencast = {
          chooser_type = "simple";
          chooser_cmd = "${pkgs.slurp}/bin/slurp -f '%o' -or";
        };
      };
    };
  };
}
