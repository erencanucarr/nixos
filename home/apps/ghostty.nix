{ lib, theme, ... }:
let
  c = theme.colors;
in
{
  programs.ghostty = {
    enable = true;
    enableBashIntegration = false;

    settings = {
      font-family = "JetBrainsMono Nerd Font";
      font-style = "Medium";
      font-style-bold = "Bold";
      font-style-italic = "Medium Italic";
      font-style-bold-italic = "Bold Italic";
      font-size = 10;

      window-padding-x = 15;
      window-padding-y = 15;
      gtk-titlebar = false;

      theme = "light:caffeine-light,dark:caffeine";
      shell-integration-features = "ssh-env";

      keybind = [
        "ctrl+shift+plus=increase_font_size:1"
        "ctrl+shift+minus=decrease_font_size:1"
      ];
    };

    themes.caffeine = {
      palette = lib.imap0 (i: v: "${toString i}=${v}") theme.palette.ansi;
      background = c.panel;
      foreground = c.text;
      cursor-color = c.bright;
      cursor-text = c.panel;
      selection-background = c.text;
      selection-foreground = c.ground;
    };

    themes.caffeine-light = {
      palette = [
        "0=#3a322a"
        "1=#c0392b"
        "2=#5a7d3c"
        "3=#a9762a"
        "4=#3a6ea5"
        "5=#9a4f8a"
        "6=#2a8589"
        "7=#c8c0b4"
        "8=#6b6258"
        "9=#d04a3a"
        "10=#6a9048"
        "11=#c08a3a"
        "12=#4a7eb5"
        "13=#aa5f9a"
        "14=#3a989c"
        "15=#202020"
      ];
      background = "#f9f9f9";
      foreground = "#202020";
      cursor-color = "#644a40";
      cursor-text = "#ffffff";
      selection-background = "#e1dddb";
      selection-foreground = "#202020";
    };
  };
}
