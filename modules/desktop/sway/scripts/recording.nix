{ pkgs }:
let
  toggle = pkgs.writeShellScriptBin "recording-toggle" ''
    if [ -f /tmp/recording-pid ] && kill -0 "$(cat /tmp/recording-pid)" 2>/dev/null; then
      kill "$(cat /tmp/recording-pid)" 2>/dev/null
      rm -f /tmp/recording-pid /tmp/recording-indicator
      pkill -RTMIN+3 .waybar-wrapped 2>/dev/null
      notify-send -i camera-video "Recording" "Kayıt durduruldu"
    else
      SAVE_DIR="''${XDG_VIDEOS_DIR:-$HOME/Videos/recordings}"
      mkdir -p "$SAVE_DIR"
      FILE="$SAVE_DIR/record-$(date +%Y%m%d-%H%M%S).mp4"
      touch /tmp/recording-indicator
      pkill -RTMIN+3 .waybar-wrapped 2>/dev/null
      wf-recorder -f "$FILE" -c h264_vaapi -d /dev/dri/renderD128 &
      echo $! > /tmp/recording-pid
      notify-send -i camera-video "Recording" "Kayıt başladı"
    fi
  '';

  indicator = pkgs.writeShellScriptBin "recording-indicator" ''
    if [ -f /tmp/recording-indicator ]; then
      printf '{"text": "  ", "class": "recording", "tooltip": "Kayıt yapılıyor — tıkla durdur"}\n'
    else
      printf '{"text": "", "class": "idle"}\n'
    fi
  '';
in [ toggle indicator ]
