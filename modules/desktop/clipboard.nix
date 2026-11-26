{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.ecu.clipboard;

  defaults = {
    inherit (cfg) days maxItems images;
    paused = false;
  };

  clip = pkgs.writeShellApplication {
    name = "ecu-clip";
    runtimeInputs = [
      pkgs.cliphist
      pkgs.wl-clipboard
      pkgs.coreutils
      pkgs.gnugrep
      pkgs.gawk
      pkgs.jq
      pkgs.util-linux
    ];
    text = ''
      thumbs="''${XDG_RUNTIME_DIR:-/tmp}/ecu-clip"
      state="''${XDG_STATE_HOME:-$HOME/.local/state}/ecu-clip"
      settings="$state/settings.json"
      times="$state/times"
      image='^\[\[ binary data .* (png|jpeg|jpg|gif|webp|bmp)( |$)'
      fallback=${lib.escapeShellArg (builtins.toJSON defaults)}
      mkdir -p "$state"

      lock() {
        exec 9>"$state/lock"
        flock 9
      }

      conf() {
        local user='{}'
        if [ -s "$settings" ]; then
          user=$(cat "$settings")
        fi
        jq -c --argjson d "$fallback" --argjson u "$user" '$d + . + $u | del(.enable)' /etc/ecu/clipboard.json 2>/dev/null || printf '%s\n' "$fallback"
      }

      prune() {
        local c=$1 days max now cutoff=0
        days=$(jq -r .days <<<"$c")
        max=$(jq -r .maxItems <<<"$c")
        now=$(date +%s)
        if [ "$days" -gt 0 ]; then
          cutoff=$((now - days * 86400))
        fi
        touch "$times"
        cliphist list | awk -F'\t' -v now="$now" -v cutoff="$cutoff" -v max="$max" -v times="$times" -v del="$state/del" -v keep="$state/times.new" '
          BEGIN {
            while ((getline line < times) > 0) { split(line, a, " "); at[a[1]] = a[2] }
            printf "" > del
            printf "" > keep
          }
          $1 != "" {
            n++
            ts = ($1 in at) ? at[$1] : now
            if (n > max || (cutoff > 0 && ts < cutoff)) print > del
            else print $1 " " ts > keep
          }'
        if [ -s "$state/del" ]; then
          cliphist delete < "$state/del"
        fi
        mv "$state/times.new" "$times"
        rm -f "$state/del"
      }

      store() {
        local c types id
        c=$(conf)
        if [ "$(jq -r .paused <<<"$c")" = true ]; then
          cat > /dev/null
          return
        fi
        if [ "$(jq -r .images <<<"$c")" != true ] && [ "''${CLIPBOARD_STATE:-data}" = data ]; then
          types=$(wl-paste -l 2>/dev/null || true)
          if grep -q '^image/' <<<"$types" && ! grep -q '^text/' <<<"$types"; then
            cat > /dev/null
            return
          fi
        fi
        lock
        cliphist -max-items "$(jq -r .maxItems <<<"$c")" store
        id=$(cliphist list | sed -n '1s/\t.*//p')
        touch "$times"
        if [ -n "$id" ] && ! grep -q "^$id " "$times"; then
          printf '%s %s\n' "$id" "$(date +%s)" >> "$times"
        fi
        prune "$c"
      }

      entry() {
        cliphist -preview-width 400 list | grep -m1 -P "^$1\t" || true
      }

      list() {
        lock
        prune "$(conf)"
        mkdir -p "$thumbs"
        local rows id preview ext keep=()
        rows=$(cliphist -preview-width 400 list)
        while IFS=$'\t' read -r id preview; do
          [ -n "$id" ] || continue
          if [[ $preview =~ $image ]]; then
            ext=''${BASH_REMATCH[1]}
            keep+=("$id.$ext")
            [ -s "$thumbs/$id.$ext" ] || printf '%s\t\n' "$id" | cliphist decode > "$thumbs/$id.$ext" 2>/dev/null || true
          fi
        done <<<"$rows"
        for f in "$thumbs"/*; do
          [ -e "$f" ] || continue
          [[ " ''${keep[*]} " == *" ''${f##*/} "* ]] || rm -f "$f"
        done
        printf '%s\n' "$rows" | jq -R -s -c --arg dir "$thumbs" --rawfile tm "$times" '
          ($tm | split("\n") | map(select(length > 0) | split(" ") | {(.[0]): (.[1] | tonumber)}) | add // {}) as $at
          | split("\n") | map(select(length > 0) | (index("\t")) as $t | {id: .[:$t], text: .[$t + 1:]})
          | map(. + {at: ($at[.id] // null)} + (if (.text | test("^\\[\\[ binary data ")) then
              (.text | capture("^\\[\\[ binary data (?<size>[0-9.]+ [KMG]?i?B) (?<ext>[a-z]+)(?: (?<dims>[0-9]+x[0-9]+))?")) as $m
              | {kind: "image", size: $m.size, ext: $m.ext, dims: ($m.dims // ""), thumb: "\($dir)/\(.id).\($m.ext)"}
            else {kind: "text"} end))'
      }

      valid_id() {
        if ! [[ ''${1:-} =~ ^[0-9]+$ ]]; then
          echo "geçersiz kayıt: ''${1:-}" >&2
          exit 2
        fi
      }

      copy() {
        local row type=""
        valid_id "''${1:-}"
        row=$(entry "$1")
        [ -n "$row" ] || exit 1
        if [[ $row =~ $image ]]; then
          type="image/''${BASH_REMATCH[1]/jpg/jpeg}"
        fi
        if [ -n "$type" ]; then
          printf '%s\n' "$row" | cliphist decode | wl-copy -t "$type"
        else
          printf '%s\n' "$row" | cliphist decode | wl-copy
        fi
      }

      remove() {
        local row
        valid_id "''${1:-}"
        lock
        row=$(entry "$1")
        [ -n "$row" ] || exit 0
        printf '%s\n' "$row" | cliphist delete
        rm -f "$thumbs/$1".*
      }

      set_opt() {
        local k=''${1:-} v=''${2:-} ok=false
        case "$k" in
          days) [[ $v =~ ^[0-9]+$ ]] && ok=true ;;
          maxItems) [[ $v =~ ^[0-9]+$ ]] && [ "$v" -ge 10 ] && [ "$v" -le 5000 ] && ok=true ;;
          images | paused) [[ $v =~ ^(true|false)$ ]] && ok=true ;;
        esac
        if [ "$ok" != true ]; then
          echo "geçersiz ayar: $k=$v" >&2
          exit 2
        fi
        lock
        [ -s "$settings" ] || echo '{}' > "$settings"
        jq --arg k "$k" --argjson v "$v" '.[$k] = $v' "$settings" > "$settings.tmp"
        mv "$settings.tmp" "$settings"
        prune "$(conf)"
      }

      case "''${1:-}" in
        store) store ;;
        list) list ;;
        copy) copy "''${2:-}" ;;
        delete) remove "''${2:-}" ;;
        prune)
          lock
          prune "$(conf)"
          ;;
        config) conf ;;
        set) set_opt "''${2:-}" "''${3:-}" ;;
        reset)
          lock
          rm -f "$settings"
          prune "$(conf)"
          ;;
        wipe)
          lock
          cliphist wipe
          rm -rf "$thumbs" "$times"
          ;;
        *)
          echo "kullanım: ecu-clip list | copy <id> | delete <id> | wipe | config | set <ayar> <değer> | reset | prune" >&2
          exit 2
          ;;
      esac
    '';
  };
in
{
  options.ecu.clipboard = {
    enable = lib.mkEnableOption "pano geçmişi (cliphist) ve bardaki pano paneli";

    days = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 7;
      description = "Kayıtların kaç gün tutulacağı; 0 sınırsız. Panelden değiştirilebilir.";
    };

    maxItems = lib.mkOption {
      type = lib.types.ints.between 10 5000;
      default = 200;
      description = "Saklanacak en fazla kayıt; eskiler silinir. Panelden değiştirilebilir.";
    };

    images = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Kopyalanan görsellerin de kaydedilmesi. Panelden değiştirilebilir.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      clip
      pkgs.cliphist
      pkgs.wl-clipboard
    ];

    environment.etc."ecu/clipboard.json".text = builtins.toJSON (defaults // { enable = true; });

    systemd.user.services.ecu-clipboard = {
      description = "Pano geçmişini kaydet";
      wantedBy = [ "default.target" ];
      unitConfig.StartLimitIntervalSec = 0;
      serviceConfig = {
        ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${clip}/bin/ecu-clip store";
        Restart = "always";
        RestartSec = 3;
      };
    };

    systemd.user.services.ecu-clip-prune = {
      description = "Süresi dolan pano kayıtlarını sil";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${clip}/bin/ecu-clip prune";
      };
    };

    systemd.user.timers.ecu-clip-prune = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "hourly";
        Persistent = true;
      };
    };
  };
}
