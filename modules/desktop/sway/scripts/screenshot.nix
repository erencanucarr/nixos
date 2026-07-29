{ pkgs }:
let
  screenshotScript = pkgs.writeShellScript "screenshot-with-swappy" ''
    set -euo pipefail

    SAVE_DIR="''${XDG_PICTURES_DIR:-$HOME/Pictures/screenshots}"
    mkdir -p "$SAVE_DIR"

    if command -v wl-paste >/dev/null 2>&1 && command -v wl-copy >/dev/null 2>&1; then
      clipboard_types=$(wl-paste --list-types 2>/dev/null || true)
      case "$clipboard_types" in
        *image/png*) wl-copy --clear >/dev/null 2>&1 || true ;;
      esac
    fi

    input=$(mktemp --suffix=.png)
    before=$(mktemp)
    after=$(mktemp)
    cleanup() {
      rm -f "$input" "$before" "$after"
    }
    trap cleanup EXIT

    printf '%s\n' "$SAVE_DIR"/*.png 2>/dev/null | sort > "$before" || true

    if ! "$@" > "$input"; then
      exit 0
    fi

    if ! swappy -f "$input"; then
      notify-send -u critical "Screenshot" "Screenshot editor failed"
      exit 1
    fi

    printf '%s\n' "$SAVE_DIR"/*.png 2>/dev/null | sort > "$after" || true
    new_file=$(comm -13 "$before" "$after" | sed -n '1p')

    if [ -n "$new_file" ] && [ -f "$new_file" ]; then
      notify-send "Screenshot" "Saved: $(basename "$new_file")"
    fi
  '';

  region = pkgs.writeShellScriptBin "screenshot-region" ''
    exec ${screenshotScript} grim -g "$(slurp)" -
  '';

  full = pkgs.writeShellScriptBin "screenshot-full" ''
    exec ${screenshotScript} grim -
  '';
in [ region full ]
