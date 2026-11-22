{ lib, theme, ... }:
{
  repoLinks.".bashrc" = "shell/bashrc";

  programs.starship = {
    enable = true;
    enableBashIntegration = false;
    settings = builtins.fromTOML (builtins.readFile ./starship.toml) // {
      palette = "graphite";
      palettes.graphite = theme.colors;
    };
  };

  home.activation.dropStarshipLink = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    t="$HOME/.config/starship.toml"
    if [ -L "$t" ] && [ "$(readlink "$t")" = "$HOME/nixos/home/shell/starship.toml" ]; then
      run rm "$t"
    fi
  '';
}
