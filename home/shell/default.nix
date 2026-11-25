{ theme, ... }:
{
  imports = [ ./ssh.nix ];

  repoLinks.".bashrc" = "shell/bashrc";

  programs.starship = {
    enable = true;
    enableBashIntegration = false;
    settings = builtins.fromTOML (builtins.readFile ./starship.toml) // {
      palette = "graphite";
      palettes.graphite = theme.colors;
    };
  };
}
