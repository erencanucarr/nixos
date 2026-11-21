# Hyprland's config and the Quickshell shell, linked from this repo (see
# links.nix) so they can be edited and reloaded without a rebuild.
{ ... }:
{
  repoLinks = {
    ".config/hypr" = "hyprland";
    ".config/quickshell" = "quickshell";
    ".config/mako/config" = "hyprland/mako.conf";
  };
}
