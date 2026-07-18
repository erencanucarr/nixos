{ config, pkgs, lib, ... }: {
  wayland.windowManager.sway.config.startup = [
    { command = "${pkgs.swaybg}/bin/swaybg -i ${config.stylix.image} -m fill > /dev/null 2>&1"; }
    { command = "swaync > /dev/null 2>&1"; }
    { command = "swayosd-server > /dev/null 2>&1"; }
    { command = "ags > /dev/null 2>&1 &"; }
    { command = "swaymsg workspace number 1"; }
    { command = "nm-applet"; }
    { command = "blueman-applet"; }
    { command = "wl-paste --type text --watch cliphist store"; }
    { command = "wl-paste --type image --watch cliphist store"; }
  ];
}
