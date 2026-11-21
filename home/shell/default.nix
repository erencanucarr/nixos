# The shell setup: ~/.bashrc (aliases, zhelp) and the starship prompt, linked
# from this folder (see ../links.nix).
{ ... }:
{
  repoLinks = {
    ".bashrc" = "shell/bashrc";
    ".config/starship.toml" = "shell/starship.toml";
  };
}
