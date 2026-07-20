{ pkgs }:
pkgs.writeShellScriptBin "powermenu" ''
  current=$(powerprofilesctl get)
  if [ "$current" = "performance" ]; then
    perf_icon="✓"
    bal_icon=" "
    sav_icon=" "
  elif [ "$current" = "balanced" ]; then
    perf_icon=" "
    bal_icon="✓"
    sav_icon=" "
  else
    perf_icon=" "
    bal_icon=" "
    sav_icon="✓"
  fi
  choice=$(printf "⏻  Shutdown\n  Reboot\n  Lock\n󰗽  Logout\n󰤄  Sleep\n━ Power Profiles ─────\n''${perf_icon} 󱐋  Performance\n''${bal_icon}   Balanced\n''${sav_icon}   Power Saver" | \
    fuzzel --dmenu --prompt="Power > " --width=36 --lines=11)
  case "$choice" in
    *Shutdown) systemctl poweroff ;;
    *Reboot) systemctl reboot ;;
    *Lock) swaylock -f ;;
    *Logout) swaymsg exit ;;
    *Sleep) systemctl suspend ;;
    *Performance) powerprofilesctl set performance ;;
    *Balanced) powerprofilesctl set balanced ;;
    *"Power Saver") powerprofilesctl set power-saver ;;
  esac
''
