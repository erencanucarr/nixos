{ config, lib, pkgs, ... }:
let
  cfg = config.ecu.headset;

  chatmix = pkgs.writeShellApplication {
    name = "ecu-chatmix";
    runtimeInputs = with pkgs; [ coreutils gnugrep jq pipewire wireplumber ];
    text = ''
      state="''${XDG_RUNTIME_DIR}/ecu-chatmix"
      loops=()

      hid() {
        for h in /sys/class/hidraw/hidraw*; do
          grep -q 'HID_ID=0003:00001038:0000220E' "$h/device/uevent" 2>/dev/null || continue
          if [ "$(cat "$h/device/../bInterfaceNumber" 2>/dev/null)" = "$1" ]; then
            echo "/dev/''${h##*/}"
            return 0
          fi
        done
        return 1
      }

      ids() {
        pw-dump 2>/dev/null | jq -r '[$ARGS.positional[] as $n | first(.[] | select(.info.props."node.name" == $n) | .id) // "" | tostring] | join(",")' --args "$@" || true
      }

      start_loops() {
        for kind in game:Oyun chat:Sohbet; do
          n=''${kind%%:*}
          pw-loopback -n "arctis_$n" \
            --capture-props="media.class=Audio/Sink node.name=arctis_$n node.description=\"Arctis ''${kind#*:}\" audio.position=[FL,FR]" \
            --playback-props="node.name=arctis_$n.out target.object=${cfg.sink} node.passive=true node.dont-fallback=true stream.dont-remix=true audio.position=[FL,FR]" &
          loops+=("$!")
        done
      }

      stop_loops() {
        if [ "''${#loops[@]}" -gt 0 ]; then
          kill "''${loops[@]}" 2>/dev/null || true
        fi
        loops=()
        echo off > "$state"
      }

      apply() {
        if [ -n "$game_id" ]; then wpctl set-volume "$game_id" "$1%" || true; fi
        if [ -n "$chat_id" ]; then wpctl set-volume "$chat_id" "$2%" || true; fi
        echo "$1 $2" > "$state"
      }

      initial() {
        { sleep 0.3; printf '\x00\xb0' > "$1"; } &
        while read -r id _ _ _ g c _; do
          if [ "$id" = "b0" ]; then
            echo "$(( 16#$g )) $(( 16#$c ))"
            return
          fi
        done < <(timeout 2 stdbuf -oL od -An -tx1 -w64 -v "$1")
        echo "100 100"
      }

      trap 'stop_loops; exit 0' TERM INT

      while true; do
        if ! events=$(hid 05) || ! status=$(hid 03) || [ -z "$(ids ${lib.escapeShellArg cfg.sink})" ]; then
          sleep 10
          continue
        fi

        start_loops
        game_id="" chat_id="" game_sink=""
        for _ in $(seq 50); do
          IFS=, read -r game_id chat_id game_sink < <(ids arctis_game.out arctis_chat.out arctis_game) || true
          [ -n "$game_id" ] && [ -n "$chat_id" ] && [ -n "$game_sink" ] && break
          sleep 0.2
        done
        wpctl set-default "$game_sink" || true

        read -r g c < <(initial "$status")
        apply "$g" "$c"

        while read -r id g c _; do
          [ "$id" = "45" ] && apply "$(( 16#$g ))" "$(( 16#$c ))"
        done < <(stdbuf -oL od -An -tx1 -w64 -v "$events")

        stop_loops
        sleep 2
      done
    '';
  };
in
{
  options.ecu.headset = {
    enable = lib.mkEnableOption "SteelSeries Arctis 7+ pil durumu ve ChatMix tekerleği (ecu-chatmix)";

    sink = lib.mkOption {
      type = lib.types.str;
      default = "alsa_output.usb-SteelSeries_Arctis_7_-00.analog-stereo";
      description = "Kulaklığın ALSA çıkışının PipeWire düğüm adı; Oyun ve Sohbet çıkışları buna bağlanır.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.headsetcontrol chatmix ];
    services.udev.packages = [ pkgs.headsetcontrol ];

    systemd.user.services.ecu-chatmix = {
      description = "Arctis 7+ ChatMix wheel";
      wantedBy = [ "default.target" ];
      after = [ "pipewire.service" "wireplumber.service" ];
      serviceConfig = {
        ExecStart = "${chatmix}/bin/ecu-chatmix";
        Restart = "always";
        RestartSec = 5;
      };
    };
  };
}
