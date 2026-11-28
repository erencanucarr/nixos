{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.ecu.taildrop;

  taildrop = pkgs.writeShellApplication {
    name = "ecu-taildrop";
    runtimeInputs = [
      config.services.tailscale.package
      pkgs.coreutils
      pkgs.gnused
      pkgs.zenity
      pkgs.libnotify
      pkgs.xdg-user-dirs
      pkgs.xdg-utils
    ];
    text = ''
      inbox() {
        local d
        d="$(xdg-user-dir DOWNLOAD 2>/dev/null || echo "$HOME/Downloads")/${cfg.folder}"
        mkdir -p "$d"
        printf '%s' "$d"
      }

      note() {
        notify-send -a Tailscale "$@"
      }

      send() {
        local target=$1 picked label out
        shift
        local files=("$@")
        if [ ''${#files[@]} -eq 0 ]; then
          picked=$(zenity --file-selection --multiple --separator=$'\n' --title="$target cihazına gönder" 2>/dev/null) || exit 0
          mapfile -t files <<<"$picked"
        fi
        [ ''${#files[@]} -gt 0 ] || exit 0
        if [ ''${#files[@]} -eq 1 ]; then
          label=$(basename "''${files[0]}")
        else
          label="''${#files[@]} dosya"
        fi
        note "Taildrop: gönderiliyor" "$label → $target"
        if out=$(tailscale file cp "''${files[@]}" "$target:" 2>&1); then
          note "Taildrop: gönderildi" "$label → $target"
        else
          note -u critical "Taildrop: gönderilemedi" "$target: $(printf '%s' "$out" | tail -n 1)"
          exit 1
        fi
      }

      pick() {
        [ $# -gt 0 ] || exit 0
        local rows=() target
        while IFS=$'\t' read -r _ name state; do
          [ -n "$name" ] || continue
          rows+=("$name" "''${state:-çevrimiçi}")
        done < <(tailscale file cp --targets 2>/dev/null | sort -t $'\t' -k3,3)
        if [ ''${#rows[@]} -eq 0 ]; then
          note -u critical "Taildrop" "Dosya gönderilebilecek bir cihaz yok."
          exit 1
        fi
        target=$(zenity --list --title="Nereye gönderilsin?" --text="$# dosya" --column=Cihaz --column=Durum --width=460 --height=320 "''${rows[@]}" 2>/dev/null) || exit 0
        [ -n "$target" ] || exit 0
        send "$target" "$@"
      }

      receive() {
        local d before after new count first body
        d=$(inbox)
        while true; do
          before=$(ls -1A "$d")
          if ! tailscale file get --wait --conflict=rename "$d" >/dev/null 2>&1; then
            sleep 10
            continue
          fi
          after=$(ls -1A "$d")
          new=$(comm -13 <(printf '%s\n' "$before" | sort) <(printf '%s\n' "$after" | sort) | sed '/^$/d')
          [ -n "$new" ] || continue
          count=$(printf '%s\n' "$new" | wc -l)
          first=$(printf '%s\n' "$new" | head -n 1)
          if [ "$count" -eq 1 ]; then
            body="$first"
          else
            body="$first ve $((count - 1)) dosya daha"
          fi
          (
            action=$(notify-send -a Tailscale -A open="Klasörü aç" --wait "Taildrop: dosya geldi" "$body" 2>/dev/null || true)
            if [ "$action" = open ]; then
              xdg-open "$d" >/dev/null 2>&1 || true
            fi
          ) &
        done
      }

      cmd=''${1:-}
      shift || true

      case "$cmd" in
        send)
          [ $# -ge 1 ] || { echo "kullanım: ecu-taildrop send <cihaz> [dosya...]" >&2; exit 64; }
          send "$@"
          ;;
        pick)
          pick "$@"
          ;;
        receive)
          receive
          ;;
        inbox)
          inbox
          ;;
        *)
          echo "kullanım: ecu-taildrop send <cihaz> [dosya...] | pick <dosya...> | receive | inbox" >&2
          exit 64
          ;;
      esac
    '';
  };

in
{
  options.ecu.taildrop = {
    enable = lib.mkEnableOption "Tailscale ile dosya gönderme ve alma (Taildrop)";

    folder = lib.mkOption {
      type = lib.types.str;
      default = "Taildrop";
      description = "İndirilenler klasörünün altında gelen dosyaların kaydedildiği klasör.";
    };

  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.services.tailscale.enable;
        message = "ecu.taildrop için services.tailscale.enable açık olmalı.";
      }
    ];

    environment.systemPackages = [ taildrop ];

    environment.etc."ecu/taildrop.json".text = builtins.toJSON { enable = true; };

    systemd.user.services.ecu-taildrop = {
      description = "Taildrop ile gelen dosyaları al";
      wantedBy = [ "default.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${taildrop}/bin/ecu-taildrop receive";
        Restart = "always";
        RestartSec = 10;
      };
    };

  };
}
