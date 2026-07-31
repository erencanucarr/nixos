{ pkgs }:
let
  screenshot = import ./screenshot.nix { inherit pkgs; };
  recording = import ./recording.nix { inherit pkgs; };
  micmute = pkgs.writeShellScriptBin "micmute" ''
    wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
    if wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | ${pkgs.gnugrep}/bin/grep -q '\[MUTED\]'; then
      brightnessctl -d platform::micmute set 1
    else
      brightnessctl -d platform::micmute set 0
    fi
    qs ipc call osd mic
  '';
in
  [ micmute ]
  ++ screenshot
   ++ recording
