# The shell setup: ~/.bashrc (aliases, zhelp) and the starship prompt, linked
# from home/shell/ (see links.nix).
{ ... }:
{
  repoLinks = {
    ".bashrc" = "shell/bashrc";
    ".config/starship.toml" = "shell/starship.toml";
  };
}
