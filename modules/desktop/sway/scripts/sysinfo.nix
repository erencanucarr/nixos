{ pkgs }:
pkgs.writeShellScriptBin "sysinfo" ''
  cpu=$(awk -v a="$(grep '^cpu ' /proc/stat)" -v b="$(sleep 0.5 && grep '^cpu ' /proc/stat)" 'BEGIN {
    split(a, x); split(b, y);
    idle = (y[5]-x[5]) / (y[2]+y[3]+y[4]+y[5]+y[6]+y[7]+y[8] - x[2]-x[3]-x[4]-x[5]-x[6]-x[7]-x[8]) * 100;
    used = 100 - idle;
    printf "%.1f", used
  }')
  temp=$(awk '{printf "%.0f°C", $1/1000}' /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo "N/A")
  mem=$(free -h | awk '/^Mem:/ {print $3 " / " $2 " (" $3/$2*100 "%)"}')
  bat_name=$(upower -e | grep -i bat | head -1)
  if [ -n "$bat_name" ]; then
    bat_info=$(upower -i "$bat_name" 2>/dev/null)
    bat_pct=$(echo "$bat_info" | awk '/percentage/{print $NF}')
    bat_state=$(echo "$bat_info" | awk '/state/{print $2}')
    bat_cycle=$(echo "$bat_info" | awk -F': +' '/cycle count/{print $2}')
    [ -z "$bat_cycle" ] && bat_cycle=$(awk '/CYCLE_COUNT/{print $2}' /sys/class/power_supply/BAT0/uevent 2>/dev/null || echo "-")
    health=$(cat /sys/class/power_supply/BAT0/energy_full_design 2>/dev/null)
    [ -n "$health" ] && health_pct=$(awk -v f="$health" -v n="$(cat /sys/class/power_supply/BAT0/energy_full)" 'BEGIN{printf "%.0f", n/f*100}')
    battery="    $bat_pct ($bat_state) — cycle: $bat_cycle, health: $health_pct%"
  else
    battery="    No battery"
  fi
  disk=$(df -h / /home 2>/dev/null | awk 'NR>1 {printf "    %s: %s / %s (%s)\n", $6, $3, $2, $5}')
  {
    printf "  System Info\n"
    printf "━━━━━━━━━━━━━━━━━━━━━━\n"
    printf "    CPU: %s%%\n" "$cpu"
    printf "    Temp: %s\n" "$temp"
    printf "    RAM: %s\n" "$mem"
    printf "%s\n" "$battery"
    printf "%s" "$disk"
  } | vicinae dmenu --placeholder="System Info" --height=520 --width=620 --no-footer
''
