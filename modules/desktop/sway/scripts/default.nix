{ pkgs }:
let
  sysinfo = import ./sysinfo.nix { inherit pkgs; };
  screenshot = import ./screenshot.nix { inherit pkgs; };
  recording = import ./recording.nix { inherit pkgs; };
  cliphist-menu = import ./cliphist-menu.nix { inherit pkgs; };
in
  [ sysinfo cliphist-menu ]
  ++ screenshot
   ++ recording
