# can's apps and the look GTK apps read from dconf, written on every switch.
{ lib, pkgs, ... }:
let
  # Obsidian with libstdc++ on its library path, so plugins that ship native
  # modules load (ecu-terminal's node-pty needs it; NixOS has no global copy).
  # This binding shadows pkgs.obsidian in home.packages below.
  obsidian = pkgs.symlinkJoin {
    name = "obsidian-${pkgs.obsidian.version}";
    paths = [ pkgs.obsidian ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/obsidian \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib ]}
    '';
  };
in
{
  imports = [ ./links.nix ./shell.nix ./hyprland.nix ./vicinae.nix ./ghostty.nix ];

  home.stateVersion = "26.05";

  # Apps for this user only. System-wide tools are in modules/base.nix.
  # Terminal tools used by ~/.bashrc: eza (ls), bat (cat), fzf (fuzzy search),
  # zoxide (smart cd), fd (find), starship (prompt), wl-clipboard (copy/paste),
  # duf (disks), ncdu (folder sizes), trash-cli (safe delete), tealdeer (tldr).
  home.packages = with pkgs; [
    obsidian
    eza
    bat
    fzf
    zoxide
    fd
    starship
    wl-clipboard
    duf
    ncdu
    trash-cli
    tealdeer
  ];

  # What GTK apps read: dark libadwaita, adw-gtk3 so GTK 3 apps match it,
  # WhiteSur icons and cursors, and the fonts.
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      gtk-theme = "adw-gtk3-dark";
      icon-theme = "WhiteSur-dark";
      cursor-theme = "WhiteSur-cursors";
      color-scheme = "prefer-dark";
      font-name = "Inter 11";
      document-font-name = "Inter 11";
      monospace-font-name = "JetBrainsMono Nerd Font Medium 10";
      # The same rendering as fontconfig in modules/desktop.nix.
      font-antialiasing = "grayscale";
      font-hinting = "slight";
    };
    # Apps that draw their own titlebar: a single close button.
    "org/gnome/desktop/wm/preferences".button-layout = "appmenu:close";
  };
}
