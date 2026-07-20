{ pkgs }:
pkgs.writeShellScriptBin "powermenu" ''
  choice=$(printf "⏻ Shutdown\n Reboot\n Lock\n󰗽 Logout\n󰤄 Sleep" | \
    fuzzel --dmenu --prompt="Power > " --width=30 --lines=5)
  case "$choice" in
    *Shutdown) systemctl poweroff ;;
    *Reboot) systemctl reboot ;;
    *Lock) swaylock -f ;;
    *Logout) swaymsg exit ;;
    *Sleep) systemctl suspend ;;
  esac
''
