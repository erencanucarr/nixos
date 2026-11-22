{ theme, ... }:
let
  c = theme.colors;
in
{
  programs.zathura = {
    enable = true;
    options = {
      default-bg = c.ground;
      default-fg = c.text;
      statusbar-bg = c.panel;
      statusbar-fg = c.dim;
      inputbar-bg = c.panel;
      inputbar-fg = c.text;
      notification-bg = c.raised;
      notification-fg = c.text;
      notification-error-bg = c.raised;
      notification-error-fg = c.hot;
      notification-warning-bg = c.raised;
      notification-warning-fg = c.warm;
      highlight-color = theme.rgba c.warm "0.35";
      highlight-active-color = theme.rgba c.warm "0.6";
      completion-bg = c.raised;
      completion-fg = c.text;
      completion-highlight-bg = c.rule;
      completion-highlight-fg = c.bright;
      recolor-lightcolor = c.ground;
      recolor-darkcolor = c.text;
      font = "Inter 11";
      selection-clipboard = "clipboard";
      adjust-open = "width";
    };
  };

  programs.imv = {
    enable = true;
    settings.options = {
      background = theme.bare c.ground;
      overlay_font = "Inter:11";
      overlay_text_color = theme.bare c.text;
      overlay_background_color = theme.bare c.raised;
      overlay_background_alpha = "d9";
    };
  };
}
