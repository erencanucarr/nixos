# GNOME's look and behaviour for can, written to dconf on every switch.
# A setting changed in GNOME's own UI lasts until the next switch; to keep it,
# set it here.
{ lib, pkgs, unstable, ... }:
let
  inherit (lib.hm.gvariant) mkTuple mkDouble mkUint32;
  whitesur = import ../pkgs/whitesur.nix { inherit unstable; };
  theme = "WhiteSur-Dark";

  # The theme's GTK 4 folder holds only a gresource and two CSS files that
  # import from it. libadwaita reads plain files from ~/.config/gtk-4.0, so
  # the resources (gtk.css, gtk-dark.css, assets/, windows-assets/) are
  # unpacked here at the paths the CSS names them by.
  whitesurGtk4 = pkgs.runCommand "whitesur-gtk4-${theme}" { nativeBuildInputs = [ pkgs.glib.dev ]; } ''
    res=${whitesur}/share/themes/${theme}/gtk-4.0/gtk.gresource
    for r in $(gresource list "$res"); do
      rel=''${r#/org/gnome/theme/}
      mkdir -p "$out/$(dirname "$rel")"
      gresource extract "$res" "$r" > "$out/$rel"
    done
    test -s "$out/gtk.css" && test -d "$out/assets"
  '';
in
{
  home.stateVersion = "26.05";

  dconf.settings = {
    "org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = [
        "user-theme@gnome-shell-extensions.gcampax.github.com"
        "dash-to-dock@micxgx.gmail.com"
        "blur-my-shell@aunetx"
        "appindicatorsupport@rgcjonas.gmail.com"
      ];
      favorite-apps = [
        "org.gnome.Nautilus.desktop"
        "firefox.desktop"
        "org.gnome.Ptyxis.desktop"
        "org.gnome.Console.desktop"
        "org.gnome.Settings.desktop"
      ];
    };
    "org/gnome/shell/extensions/user-theme".name = theme;

    "org/gnome/desktop/interface" = {
      gtk-theme = theme;
      icon-theme = "WhiteSur-dark";
      cursor-theme = "WhiteSur-cursors";
      color-scheme = "prefer-dark";
      font-name = "Inter 11";
      document-font-name = "Inter 11";
      monospace-font-name = "JetBrainsMono Nerd Font 11";
      clock-show-weekday = true;
      enable-hot-corners = false;
    };
    # Close, minimise and maximise on the left, as on macOS.
    "org/gnome/desktop/wm/preferences".button-layout = "close,minimize,maximize:";
    "org/gnome/mutter".center-new-windows = true;
    "org/gnome/desktop/input-sources".sources = [ (mkTuple [ "xkb" "tr" ]) ];

    # A macOS-style dock: at the bottom, out of the way of maximised windows,
    # with the app grid (Launchpad) button first.
    "org/gnome/shell/extensions/dash-to-dock" = {
      dock-position = "BOTTOM";
      dock-fixed = false;
      intellihide = true;
      extend-height = false;
      dash-max-icon-size = 48;
      show-apps-at-top = true;
      show-trash = false;
      show-mounts = false;
      running-indicator-style = "DOTS";
      click-action = "minimize-or-previews";
      transparency-mode = "FIXED";
      background-opacity = mkDouble 0.6;
      custom-theme-shrink = true;
      apply-custom-theme = false;
    };

    "org/gnome/shell/extensions/blur-my-shell/panel".blur = true;
    "org/gnome/shell/extensions/blur-my-shell/overview".blur = true;
    "org/gnome/shell/extensions/blur-my-shell/dash-to-dock".blur = true;

    "org/gnome/desktop/session".idle-delay = mkUint32 900;
  };

  # libadwaita apps (Nautilus, Settings, most GNOME apps) ignore the GTK
  # theme and read only ~/.config/gtk-4.0. WhiteSur's GTK 4 files there give
  # them the theme too.
  xdg.configFile = lib.listToAttrs (map
    (f: lib.nameValuePair "gtk-4.0/${f}" { source = "${whitesurGtk4}/${f}"; })
    [ "gtk.css" "gtk-dark.css" "assets" "windows-assets" ]);
}
