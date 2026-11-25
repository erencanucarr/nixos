{ pkgs, theme }:
let
  c = theme.colors;
in
(pkgs.formats.toml { }).generate "graphite.toml" {
  meta = {
    version = 1;
    name = "Graphite";
    description = "Graphite";
    variant = "dark";
    inherits = "vicinae-dark";
  };
  colors = {
    core = {
      background = c.ground;
      foreground = c.text;
      secondary_background = c.raised;
      border = c.line;
      accent = c.text;
      accent_foreground = c.ground;
    };
    accents = {
      inherit (c)
        blue
        green
        magenta
        purple
        cyan
        ;
      orange = c.warm;
      red = c.hot;
      yellow = c.warm;
    };
    main_window = {
      border = "colors.core.border";
      footer.background = "colors.core.secondary_background";
    };
    shortcut.border = "colors.core.border";
    text = {
      default = "colors.core.foreground";
      muted = c.dim;
      placeholder = c.dim;
      danger = c.hot;
      success = c.green;
      selection = {
        background = c.text;
        foreground = c.ground;
      };
    };
    input = {
      border = "colors.core.border";
      border_focus = c.warm;
      border_error = c.hot;
    };
    button.primary = {
      background = "colors.core.secondary_background";
      foreground = "colors.core.foreground";
      hover.background = c.hoverRaised;
      focus.outline = c.warm;
    };
    list.item = {
      hover = {
        background = c.hover;
        foreground = c.text;
        secondary_foreground = c.dim;
      };
      selection = {
        background = c.select;
        foreground = c.bright;
        secondary_background = c.select;
        secondary_foreground = c.dim;
      };
    };
    grid.item = {
      background = "colors.core.secondary_background";
      hover.outline = c.line;
      selection.outline = c.dim;
    };
    scrollbars.background = c.rule;
    loading = {
      bar = c.dim;
      spinner = c.text;
    };
  };
}
