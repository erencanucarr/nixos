# The WhiteSur GTK and GNOME Shell theme, built once with the options both
# modules/gnome.nix (installs it) and home/can.nix (links its GTK 4 files) use.
# The 26.05 package predates GNOME 49; unstable's is newer. It is only theme
# files, so taking it from unstable mixes no libraries.
{ unstable }:
unstable.whitesur-gtk-theme.override {
  # Nautilus with the sidebar in the window's full height, as in Finder.
  nautilusStyle = "stable";
  roundedMaxWindow = true;
}
