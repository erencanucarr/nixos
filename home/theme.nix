{ lib, theme, ... }:
let
  c = theme.colors;
  shade = "rgba(0, 0, 0, 0.3)";
  border = "rgba(255, 255, 255, 0.08)";

  gtk = {
    window_bg_color = c.ground;
    window_fg_color = c.text;
    view_bg_color = c.panel;
    view_fg_color = c.text;
    headerbar_bg_color = c.ground;
    headerbar_fg_color = c.text;
    headerbar_border_color = border;
    headerbar_backdrop_color = c.ground;
    headerbar_shade_color = shade;
    headerbar_darker_shade_color = shade;
    sidebar_bg_color = c.ground;
    sidebar_fg_color = c.text;
    sidebar_backdrop_color = c.ground;
    sidebar_border_color = border;
    sidebar_shade_color = shade;
    secondary_sidebar_bg_color = c.ground;
    secondary_sidebar_fg_color = c.text;
    secondary_sidebar_backdrop_color = c.ground;
    secondary_sidebar_border_color = border;
    secondary_sidebar_shade_color = shade;
    card_bg_color = "rgba(255, 255, 255, 0.02)";
    card_fg_color = c.text;
    card_shade_color = shade;
    dialog_bg_color = c.raised;
    dialog_fg_color = c.text;
    popover_bg_color = c.raised;
    popover_fg_color = c.text;
    popover_shade_color = shade;
    thumbnail_bg_color = c.raised;
    thumbnail_fg_color = c.text;
    shade_color = shade;
    scrollbar_outline_color = shade;
    borders = border;
    unfocused_borders = border;
    accent_bg_color = c.text;
    accent_fg_color = c.ground;
    accent_color = c.text;
    destructive_bg_color = c.hot;
    destructive_fg_color = c.ground;
    destructive_color = c.hot;
    error_bg_color = c.hot;
    error_fg_color = c.ground;
    error_color = c.hot;
    warning_bg_color = c.warm;
    warning_fg_color = c.ground;
    warning_color = c.warm;
    success_bg_color = c.green;
    success_fg_color = c.ground;
    success_color = c.green;
    graphite_glow = "rgba(255, 255, 255, 0.05)";
    graphite_lift = "rgba(255, 255, 255, 0.05)";
    graphite_glow_panel_far = "rgba(255, 255, 255, 0.03)";
  };
in
{
  xdg.configFile = {
    "can-theme/palette.json".text = builtins.toJSON c;
    "can-theme/palette.lua".text = "return " + lib.generators.toLua { } c + "\n";
    "can-theme/hyprlock.conf".text = lib.concatStrings (
      lib.mapAttrsToList (n: v: "$" + "${n} = ${theme.bare v}\n") c
    );
    "can-theme/gtk.css".text = lib.concatStrings (
      lib.mapAttrsToList (n: v: "@define-color ${n} ${v};\n") gtk
    );
  };
}
