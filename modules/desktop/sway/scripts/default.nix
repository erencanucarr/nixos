{ pkgs }:
let
  powermenu = import ./powermenu.nix { inherit pkgs; };
  keybinds-help = import ./keybinds-help.nix { inherit pkgs; };
  sysinfo = import ./sysinfo.nix { inherit pkgs; };
  screenshot = import ./screenshot.nix { inherit pkgs; };
  recording = import ./recording.nix { inherit pkgs; };
  brightness = import ./brightness.nix { inherit pkgs; };
in
  [ powermenu keybinds-help sysinfo ]
  ++ screenshot
  ++ recording
  ++ brightness
