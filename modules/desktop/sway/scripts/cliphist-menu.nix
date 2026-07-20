{ pkgs }:
pkgs.writeShellScriptBin "cliphist-menu" ''
  pick=$(printf "🗑  Tümünü Temizle\n%s" "$(cliphist list)" | fuzzel --dmenu --prompt="Clipboard > " --width=65 --lines=15)
  case "$pick" in
    "🗑  Tümünü Temizle") cliphist wipe; notify-send -i dialog-information "Clipboard" "Temizlendi" ;;
    "")
      ;; # do nothing
    *) echo "$pick" | cliphist decode | wl-copy ;;
  esac
''
