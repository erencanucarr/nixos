{ config, lib, pkgs, ... }:
let
  cfg = config.ecu.screenshot;

  tesseract = pkgs.tesseract.override { enableLanguages = cfg.ocr.languages; };

  tools = [
    pkgs.coreutils
    pkgs.gnused
    pkgs.grim
    pkgs.vips
    pkgs.wf-recorder
    pkgs.ffmpeg
    pkgs.wl-clipboard
    pkgs.libnotify
    pkgs.xdg-user-dirs
    pkgs.wireplumber
    pkgs.pipewire
    pkgs.jq
  ]
  ++ lib.optional cfg.ocr.enable tesseract
  ++ lib.optional cfg.qr.enable pkgs.zbar;

  shot = pkgs.writeShellApplication {
    name = "ecu-shot";
    runtimeInputs = tools;
    text = ''
      run="''${XDG_RUNTIME_DIR:-/tmp}"

      folder() {
        local d
        d=$(xdg-user-dir "$1" 2>/dev/null) || d=""
        if [ -z "$d" ] || [ "$d" = "$HOME" ]; then
          d="$HOME/$2"
        fi
        d="$d/$3"
        mkdir -p "$d"
        printf '%s' "$d"
      }

      pictures() {
        folder PICTURES Pictures ${lib.escapeShellArg cfg.folders.pictures}
      }

      videos() {
        folder VIDEOS Videos ${lib.escapeShellArg cfg.folders.videos}
      }

      stamp() {
        date +%Y-%m-%d_%H-%M-%S
      }

      note() {
        notify-send -a "$@"
      }

      scan() {
        local frame=$1 x=$2 y=$3 w=$4 h=$5 out
        rm -f "$run"/ecu-shot-scan-*.png
        out="$run/ecu-shot-scan-$(stamp).png"
        if ! vips crop -- "$frame" "$out" "$x" "$y" "$w" "$h"; then
          rm -f "$frame"
          return 1
        fi
        rm -f "$frame"
        printf '%s' "$out"
      }

      cmd=''${1:-}
      shift || true

      case "$cmd" in
        freeze)
          rm -f "$run"/ecu-shot-*.ppm
          if ! grim -t ppm -o "$1" "$2"; then
            note "Ekran görüntüsü" "Ekran görüntüsü alınamadı"
            exit 1
          fi
          echo ok
          ;;

        photo)
          delay=$1 frame=$2 x=$3 y=$4 w=$5 h=$6 geometry=$7
          f="$(pictures)/$(stamp).png"
          if [ "$delay" = 0 ]; then
            vips crop -- "$frame" "''${f}[compression=1]" "$x" "$y" "$w" "$h" || f=""
          else
            sleep "$delay"
            grim -g "$geometry" "$f" || f=""
          fi
          rm -f "$frame"
          if [ -z "$f" ]; then
            note "Ekran görüntüsü" "Ekran görüntüsü alınamadı"
            exit 1
          fi
          wl-copy -t image/png < "$f"
          printf '%s' "$f"
          ;;

        screen)
          f="$(pictures)/$(stamp).png"
          if ! grim -o "$1" "$f"; then
            note "Ekran görüntüsü" "Ekran görüntüsü alınamadı"
            exit 1
          fi
          wl-copy -t image/png < "$f"
          printf '%s' "$f"
          ;;

        record)
          kind=$1 id=$2 audio=$3
          shift 3
          if [ "$kind" = gif ]; then
            rm -f "$run"/ecu-rec-*.mp4
            f="$run/ecu-rec-$id.mp4"
            set -- "$@" -r ${toString cfg.gif.fps}
          else
            f="$(videos)/$id.mp4"
            set -- "$@" -r ${toString cfg.video.fps}
            if [ "$audio" = 1 ]; then
              sink=$(wpctl inspect @DEFAULT_AUDIO_SINK@ | sed -n 's/.*node.name = "\(.*\)"/\1/p') || sink=""
              if [ -n "$sink" ]; then
                target=$(pw-dump 2>/dev/null | jq -r --arg n "$sink.out" 'first(.[] | select(.type == "PipeWire:Interface:Node") | (.info.props // {}) | select(."node.name" == $n) | ."target.object" // empty | strings)' 2>/dev/null) || target=""
                if [ -n "$target" ]; then
                  sink=$target
                fi
                set -- "$@" --audio-backend=pipewire "--audio=$sink.monitor"
              fi
            fi
          fi
          exec wf-recorder -y "$@" -c libx264 -p preset=veryfast -p crf=${toString cfg.video.quality} -x yuv420p -f "$f"
          ;;

        finish)
          kind=$1 id=$2
          d=$(videos)
          if [ "$kind" = gif ]; then
            src="$run/ecu-rec-$id.mp4"
            f="$d/$id.gif"
            [ -s "$src" ] || exit 1
            ffmpeg -y -loglevel error -i "$src" -vf "fps=${toString cfg.gif.fps},scale='min(${toString cfg.gif.maxWidth},iw)':-2:flags=lanczos,split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=4" "$f" || { rm -f "$src"; exit 1; }
            rm -f "$src"
            wl-copy -t image/gif < "$f"
          else
            f="$d/$id.mp4"
            [ -s "$f" ] || exit 1
            jq -rn --arg p "$f" '"file://" + ($p | split("/") | map(@uri) | join("/"))' | wl-copy -t text/uri-list
          fi
          rm -f "$run"/ecu-rec-thumb-*.png
          t="$run/ecu-rec-thumb-$id.png"
          ffmpeg -y -loglevel error -i "$f" -frames:v 1 -vf "scale=592:-2" "$t" || t=""
          printf '%s\n%s' "$f" "$t"
          ;;

        ocr)
          if ! img=$(scan "$@"); then
            echo fail
            exit 0
          fi
          text=$(tesseract "$img" stdout --oem 1 --psm 6 -l ${lib.concatStringsSep "+" cfg.ocr.languages} --dpi 300 -c preserve_interword_spaces=1 2>/dev/null | sed -e 's/[[:space:]]*$//') || text=""
          if [ -z "$text" ]; then
            printf 'empty\n%s' "$img"
            exit 0
          fi
          printf '%s' "$text" | wl-copy
          printf 'ok\n%s\n%s' "$img" "$text"
          ;;

        qr)
          if ! img=$(scan "$@"); then
            echo fail
            exit 0
          fi
          result=$(zbarimg -q --raw -Sdisable -Sqrcode.enable "$img" 2>/dev/null) || result=""
          if [ -z "$result" ]; then
            printf 'empty\n%s' "$img"
            exit 0
          fi
          printf '%s' "$result" | wl-copy --sensitive
          printf 'ok\n%s' "$img"
          ;;

        copy)
          wl-copy -t image/png < "$1"
          ;;

        notify)
          note "$@"
          ;;

        *)
          echo "kullanım: ecu-shot freeze|photo|screen|record|finish|ocr|qr|copy|notify" >&2
          exit 64
          ;;
      esac
    '';
  };
in
{
  options.ecu.screenshot = {
    enable = lib.mkEnableOption "ekran görüntüsü, kayıt, OCR ve QR sistemi";

    folders = {
      pictures = lib.mkOption {
        type = lib.types.str;
        default = "Ekran Görüntüleri";
        description = "Resimler klasörünün altında ekran görüntülerinin kaydedildiği klasör.";
      };
      videos = lib.mkOption {
        type = lib.types.str;
        default = "Ekran Kayıtları";
        description = "Videolar klasörünün altında video ve GIF kayıtlarının kaydedildiği klasör.";
      };
    };

    video = {
      fps = lib.mkOption {
        type = lib.types.ints.positive;
        default = 60;
        description = "Video kaydının kare hızı.";
      };
      quality = lib.mkOption {
        type = lib.types.ints.between 0 51;
        default = 20;
        description = "x264 CRF değeri; düştükçe kalite ve dosya boyutu artar.";
      };
    };

    gif = {
      fps = lib.mkOption {
        type = lib.types.ints.positive;
        default = 15;
        description = "GIF kare hızı.";
      };
      maxWidth = lib.mkOption {
        type = lib.types.ints.positive;
        default = 960;
        description = "GIF'in en fazla genişliği, piksel.";
      };
    };

    ocr = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Seçilen alandaki yazıyı okuyup panoya kopyalayan yazı türü.";
      };
      languages = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "tur" "eng" ];
        example = [ "tur" "eng" "deu" ];
        description = "Tesseract dil kodları.";
      };
    };

    qr.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Seçilen alandaki QR kodu okuyup panoya kopyalayan qr türü.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ shot ];
    environment.etc."ecu/shot.json".text = builtins.toJSON {
      ocr = cfg.ocr.enable;
      qr = cfg.qr.enable;
    };
  };
}
