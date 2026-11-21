# Hyprland's config and the Quickshell shell, linked from this repo (see
# links.nix) so they can be edited and reloaded without a rebuild.
{ ... }:
{
  repoLinks = {
    ".config/hypr" = "desktop/hyprland";
    ".config/quickshell" = "desktop/quickshell";
    ".config/mako/config" = "desktop/hyprland/mako.conf";
  };
}
