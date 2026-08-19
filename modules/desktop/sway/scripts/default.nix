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
  focusNotificationApp = pkgs.writeShellScriptBin "focus-notification-app" ''
    app="''${1:-}"
    [ -n "$app" ] || exit 0

    for _ in $(seq 1 15); do
      id=$(${pkgs.sway}/bin/swaymsg -t get_tree | ${pkgs.jq}/bin/jq -r --arg app "$app" '
        def norm: ascii_downcase | gsub("[^a-z0-9]"; "");
        ($app | norm) as $target |
        def matches($value):
          ($value | norm) as $normalized
          | $normalized != "" and (($normalized | contains($target)) or ($target | contains($normalized)));
        [ .. | objects
          | select(.id? and (
              matches(.app_id // "") or
              matches(.window_properties.class // "") or
              matches(.window_properties.instance // "")
            ))
          | .id ] | first // empty
      ')
      if [ -n "$id" ]; then
        ${pkgs.sway}/bin/swaymsg "[con_id=$id] focus" >/dev/null
        exit 0
      fi
      ${pkgs.coreutils}/bin/sleep 0.2
    done
  '';
in
  [ micmute focusNotificationApp ]
  ++ screenshot
   ++ recording
