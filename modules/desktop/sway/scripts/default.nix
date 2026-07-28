{ pkgs }:
let
  powermenu = import ./powermenu.nix { inherit pkgs; };
  sysinfo = import ./sysinfo.nix { inherit pkgs; };
  screenshot = import ./screenshot.nix { inherit pkgs; };
  recording = import ./recording.nix { inherit pkgs; };
  brightness = import ./brightness.nix { inherit pkgs; };
  cliphist-menu = import ./cliphist-menu.nix { inherit pkgs; };
in
  [ powermenu sysinfo cliphist-menu ]
  ++ screenshot
  ++ recording
  ++ brightness
