{ ... }:
{
  programs.zathura = {
    enable = true;
    options = {
      default-bg = "#0a0a0c";
      default-fg = "#e6e7ea";
      statusbar-bg = "#0e0e10";
      statusbar-fg = "#8a8f98";
      inputbar-bg = "#0e0e10";
      inputbar-fg = "#e6e7ea";
      notification-bg = "#151618";
      notification-fg = "#e6e7ea";
      notification-error-bg = "#151618";
      notification-error-fg = "#e2715a";
      notification-warning-bg = "#151618";
      notification-warning-fg = "#e5ae52";
      highlight-color = "rgba(229,174,82,0.35)";
      highlight-active-color = "rgba(229,174,82,0.6)";
      completion-bg = "#151618";
      completion-fg = "#e6e7ea";
      completion-highlight-bg = "#232427";
      completion-highlight-fg = "#f7f8f8";
      recolor-lightcolor = "#0a0a0c";
      recolor-darkcolor = "#e6e7ea";
      font = "Inter 11";
      selection-clipboard = "clipboard";
      adjust-open = "width";
    };
  };

  programs.imv = {
    enable = true;
    settings.options = {
      background = "0a0a0c";
      overlay_font = "Inter:11";
      overlay_text_color = "e6e7ea";
      overlay_background_color = "151618";
      overlay_background_alpha = "d9";
    };
  };
}
