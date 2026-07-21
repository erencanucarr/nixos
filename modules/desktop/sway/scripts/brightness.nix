{ pkgs }:
let
  menu = pkgs.writeShellScriptBin "brightness-menu" ''
    choice=$(
      printf "+10\n-10\n25\n50\n75\n100" \
      | fuzzel --dmenu --prompt=" " --lines=3 --width=15
    )
    case "$choice" in
      "+10") brightnessctl set +10% ;;
      "-10") brightnessctl set 10%- ;;
      25|50|75|100) brightnessctl set "$choice%" ;;
      *)
        [ -n "$choice" ] && brightnessctl set "$choice%" 2>/dev/null || true
        ;;
    esac
  '';

  indicator = pkgs.writeShellScriptBin "brightness-indicator" ''
    scr=$(brightnessctl get)
    scr_max=$(brightnessctl max)
    scr_pct=$(( scr * 100 / scr_max ))
    printf '{"text": " %s%%", "tooltip": "%%%s"}\n' "$scr_pct" "$scr_pct"
  '';
in [ menu indicator ]
