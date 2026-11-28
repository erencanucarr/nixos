{ lib, pkgs, ... }:
let
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
  imports = [
    ./links.nix
    ./theme.nix
    ./shell
    ./desktop/hyprland.nix
    ./apps/flea.nix
    ./apps/vicinae
    ./apps/ghostty.nix
    ./apps/viewers.nix
    ./apps/equibop
  ];

  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    obsidian
    bitwarden-desktop
    eza
    bat
    fzf
    zoxide
    fd
    ripgrep
    wl-clipboard
    duf
    ncdu
    trash-cli
    tealdeer
  ];

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      gtk-theme = "graphite-dark";
      icon-theme = "Papirus-Dark";
      cursor-theme = "Bibata-Modern-Classic";
      color-scheme = "prefer-dark";
      font-name = "Inter 11";
      document-font-name = "Inter 11";
      monospace-font-name = "JetBrainsMono Nerd Font Medium 10";
      font-antialiasing = "grayscale";
      font-hinting = "slight";
    };
    "org/gnome/desktop/wm/preferences".button-layout = "appmenu:close";
  };
}
