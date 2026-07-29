{ pkgs }:
pkgs.writeShellScriptBin "cliphist-menu" ''
  pick=$(printf "🗑  Tümünü Temizle\n%s" "$(cliphist list)" | vicinae dmenu --placeholder="Clipboard" --height=620 --width=760)
  case "$pick" in
    "🗑  Tümünü Temizle") cliphist wipe; notify-send -i dialog-information "Clipboard" "Temizlendi" ;;
    "")
      ;; # do nothing
    *) echo "$pick" | cliphist decode | wl-copy ;;
  esac
''
