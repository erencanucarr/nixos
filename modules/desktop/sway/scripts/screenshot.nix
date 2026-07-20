{ pkgs }:
let
  region = pkgs.writeShellScriptBin "screenshot-region" ''
    SAVE_DIR="''${XDG_PICTURES_DIR:-$HOME/Pictures/screenshots}"
    mkdir -p "$SAVE_DIR"
    BEFORE=$(ls -1 "$SAVE_DIR")
    grim -g "$(slurp)" - | swappy -f -
    AFTER=$(ls -1 "$SAVE_DIR")
    NEW=$(comm -13 <(echo "$BEFORE") <(echo "$AFTER") | head -1)
    if [ -n "$NEW" ]; then
      notify-send -i "$SAVE_DIR/$NEW" "Screenshot" "Saved: $NEW"
    else
      notify-send -i camera-screenshot "Screenshot" "Copied to clipboard"
    fi
  '';

  full = pkgs.writeShellScriptBin "screenshot-full" ''
    SAVE_DIR="''${XDG_PICTURES_DIR:-$HOME/Pictures/screenshots}"
    mkdir -p "$SAVE_DIR"
    BEFORE=$(ls -1 "$SAVE_DIR")
    grim - | swappy -f -
    AFTER=$(ls -1 "$SAVE_DIR")
    NEW=$(comm -13 <(echo "$BEFORE") <(echo "$AFTER") | head -1)
    if [ -n "$NEW" ]; then
      notify-send -i "$SAVE_DIR/$NEW" "Screenshot" "Saved: $NEW"
    else
      notify-send -i camera-screenshot "Screenshot" "Copied to clipboard"
    fi
  '';
in [ region full ]
