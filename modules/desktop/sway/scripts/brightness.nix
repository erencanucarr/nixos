{ pkgs }:
let
  menu = pkgs.writeShellScriptBin "brightness-menu" ''
    KBD="/sys/class/leds/tpacpi::kbd_backlight"
    choice=$(
      printf "☀️ Ekran %%10\n☀️ Ekran -%%10\n---\n%%25\n%%50\n%%75\n%%100\n---\n⌨️ Klavye Aç\n⌨️ Klavye Orta\n⌨️ Klavye Kapat\n⌨️ Klavye +\n⌨️ Klavye -" \
      | fuzzel --dmenu --prompt="Parlaklık: " --lines=12
    )
    case "$choice" in
      "☀️ Ekran +%10") brightnessctl set +10% ;;
      "☀️ Ekran -%10") brightnessctl set 10%- ;;
      "%25") brightnessctl set 25% ;;
      "%50") brightnessctl set 50% ;;
      "%75") brightnessctl set 75% ;;
      "%100") brightnessctl set 100% ;;
      "⌨️ Klavye Aç") echo 2 > "$KBD/brightness" ;;
      "⌨️ Klavye Orta") echo 1 > "$KBD/brightness" ;;
      "⌨️ Klavye Kapat") echo 0 > "$KBD/brightness" ;;
      "⌨️ Klavye +")
        cur=$(cat "$KBD/brightness")
        max=$(cat "$KBD/max_brightness")
        next=$((cur + 1))
        [ "$next" -gt "$max" ] && next="$max"
        echo "$next" > "$KBD/brightness"
        ;;
      "⌨️ Klavye -")
        cur=$(cat "$KBD/brightness")
        next=$((cur - 1))
        [ "$next" -lt 0 ] && next=0
        echo "$next" > "$KBD/brightness"
        ;;
      *)
        [ -n "$choice" ] && brightnessctl set "$choice%" 2>/dev/null || true
        ;;
    esac
  '';

  indicator = pkgs.writeShellScriptBin "brightness-indicator" ''
    KBD="/sys/class/leds/tpacpi::kbd_backlight"
    scr=$(brightnessctl get)
    scr_max=$(brightnessctl max)
    scr_pct=$(( scr * 100 / scr_max ))
    kbd_val=$(cat "$KBD/brightness" 2>/dev/null || echo 0)
    if [ "$kbd_val" = "0" ]; then
      kbd_str="Kapalı"
    else
      kbd_str="$kbd_val"
    fi
    printf '{"text": " %s%%", "tooltip": "Ekran: %s%% — Klavye: %s"}\n' "$scr_pct" "$scr_pct" "$kbd_str"
  '';
in [ menu indicator ]
