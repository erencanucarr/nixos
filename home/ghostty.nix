# Ghostty, set up like xeome/dots (home/.config/ghostty, MIT): JetBrainsMono
# at 10pt, 15px padding, and the Caffeine colours on graphite grounds, picked
# by the desktop's light or dark scheme. Unlike there, the titlebar stays:
# GNOME's window buttons live in it.
{ ... }:
{
  programs.ghostty = {
    enable = true;
    # Ghostty injects its own bash integration; ~/.bashrc stays ours.
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

      theme = "light:caffeine-light,dark:caffeine";
      shell-integration-features = "ssh-env";

      keybind = [
        "ctrl+shift+plus=increase_font_size:1"
        "ctrl+shift+minus=decrease_font_size:1"
      ];
    };

    # Slot 0 of the dark palette is graphite's `rule`, not black, because the
    # background is already near-black. Selected text is inverted.
    themes.caffeine = {
      palette = [
        "0=#232427" "1=#e06c75" "2=#b5c98f" "3=#ffd9a0"
        "4=#8fb0d9" "5=#cba6c9" "6=#88c0c8" "7=#e6e7ea"
        "8=#8a8f98" "9=#ff8a93" "10=#c9dba8" "11=#ffe6c4"
        "12=#a9c3e0" "13=#ddc0db" "14=#a4d4da" "15=#f7f8f8"
      ];
      background = "#0e0e10";
      foreground = "#e6e7ea";
      cursor-color = "#f7f8f8";
      cursor-text = "#0e0e10";
      selection-background = "#e6e7ea";
      selection-foreground = "#0a0a0c";
    };

    themes.caffeine-light = {
      palette = [
        "0=#3a322a" "1=#c0392b" "2=#5a7d3c" "3=#a9762a"
        "4=#3a6ea5" "5=#9a4f8a" "6=#2a8589" "7=#c8c0b4"
        "8=#6b6258" "9=#d04a3a" "10=#6a9048" "11=#c08a3a"
        "12=#4a7eb5" "13=#aa5f9a" "14=#3a989c" "15=#202020"
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
