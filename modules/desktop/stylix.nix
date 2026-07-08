{ config, pkgs, ... }:
{
  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    cursor.package = pkgs.bibata-cursors;
    cursor.name = "Bibata-Modern-Classic";
    cursor.size = 24;
    fonts = {
      monospace = {
        package = pkgs.jetbrains-mono;
        name = "JetBrains Mono";
      };
      sansSerif = {
        package = pkgs.jetbrains-mono;
        name = "JetBrains Mono";
      };
      serif = {
        package = pkgs.jetbrains-mono;
        name = "JetBrains Mono";
      };
      sizes = {
        applications = 10;
        desktop = 10;
        popups = 10;
        terminal = 12;
      };
    };
  };
}
