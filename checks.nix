{ pkgs }:
let
  qmlSyntax = pkgs.writeShellScript "ecu-qml-syntax" ''
    status=0
    for f in "$@"; do
      if out=$(${pkgs.qt6.qtdeclarative}/bin/qmllint "$f" 2>&1 | ${pkgs.gnugrep}/bin/grep -F "[syntax]"); then
        printf '%s\n' "$out"
        status=1
      fi
    done
    exit "$status"
  '';

  noComments = pkgs.writeShellScript "ecu-no-comments" ''
    status=0
    for f in "$@"; do
      case "$f" in
        *.qml | *.js | *.mjs)
          pattern='^[[:space:]]*//'
          allow='^[[:space:]]*//@'
          ;;
        *.lua)
          pattern='^[[:space:]]*--'
          allow='^-{8,} [a-z]+$'
          ;;
        *.nix)
          pattern='^[[:space:]]*#'
          allow='^$'
          ;;
        *)
          pattern='^[[:space:]]*#'
          allow='^(#!|# ═══)'
          ;;
      esac
      if ! ${pkgs.gawk}/bin/awk -v pattern="$pattern" -v allow="$allow" '
        $0 ~ pattern && $0 !~ allow { printf "%s:%d: %s\n", FILENAME, FNR, $0; bad = 1 }
        END { exit bad }
      ' "$f"; then
        status=1
      fi
    done
    if [ "$status" -ne 0 ]; then
      echo "Yorum satırı yasak: yukarıdaki satırları kaldır." >&2
    fi
    exit "$status"
  '';
in
{
  nixfmt.enable = true;
  deadnix.enable = true;
  statix.enable = true;
  shellcheck = {
    enable = true;
    files = "^home/desktop/hyprland/bin/";
  };

  qml-syntax = {
    enable = true;
    name = "qml sözdizimi";
    entry = "${qmlSyntax}";
    files = "\\.qml$";
    language = "system";
  };

  no-comments = {
    enable = true;
    name = "yorum satırı yasağı";
    entry = "${noComments}";
    files = "(\\.(nix|qml|js|mjs|lua)$|^home/shell/bashrc$|^home/desktop/hyprland/bin/)";
    language = "system";
  };
}
