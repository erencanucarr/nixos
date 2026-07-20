{ config, pkgs, lib, plasma-manager, stylix, ihtc, ... }:
let
  colors = with config.lib.stylix.colors; {
    withHashtag = {
      active = withHashtag.base03;
      background = withHashtag.base00;
      border = withHashtag.base03;
      inactive = withHashtag.base01;
      subtext = withHashtag.base04;
      text = withHashtag.base05;
      urgent = withHashtag.base08;
    };
  };
  c = colors.withHashtag;

  vesktop-wrapped = pkgs.writeShellScriptBin "vesktop" ''
    ${ihtc.packages.x86_64-linux.ihtc}/bin/ihtc --listen 127.0.0.1:4452 --verbose --regex 'discord|discordapp|googleapis' &
    IHTC_PID=$!
    for i in $(seq 1 15); do
      if ss -tlnp 2>/dev/null | grep -q 4452; then
        break
      fi
      sleep 1
    done
    export HTTP_PROXY="http://127.0.0.1:4452"
    export HTTPS_PROXY="http://127.0.0.1:4452"
    ${pkgs.vesktop}/bin/vesktop "$@"
    kill $IHTC_PID 2>/dev/null
    wait $IHTC_PID 2>/dev/null
  '';

  powermenu = pkgs.writeShellScriptBin "powermenu" ''
    choice=$(printf "⏻ Shutdown\n Reboot\n Lock\n󰗽 Logout\n󰤄 Sleep" | \
      fuzzel --dmenu --prompt="Power > " --width=30 --lines=5)
    case "$choice" in
      *Shutdown) systemctl poweroff ;;
      *Reboot) systemctl reboot ;;
      *Lock) swaylock -f ;;
      *Logout) swaymsg exit ;;
      *Sleep) systemctl suspend ;;
    esac
  '';

  keybinds-help = pkgs.writeShellScriptBin "keybinds-help" ''
    categories() {
      printf "󰩈  Navigation\n"
      printf "󰐌  Launch\n"
      printf "  Windows\n"
      printf "  Layout\n"
      printf "󰧚  Screenshot\n"
      printf "  Media / System\n"
      printf "  Exit\n"
    }

    bindings() {
      case "$1" in
        *Navigation*)
          printf "Mod4+1-9            Workspace 1-9\n"
          printf "Mod4+0              Workspace 10\n"
          printf "Ctrl+Left           Workspace önceki\n"
          printf "Ctrl+Right          Workspace sonraki\n"
          printf "Ctrl+Tab            Workspace sonraki\n"
          printf "Ctrl+Shift+Tab      Workspace önceki\n"
          printf "Mod4+Tab            Workspace sonraki\n"
          printf "Mod4+Shift+Tab      Workspace önceki\n"
          printf "Mod4+Shift+1-9      Pencereyi workspace'e taşı\n"
          printf "Mod4+a              Parent container\n"
          printf "Mod4+grave          Scratchpad toggle\n"
          ;;
        *Launch*)
          printf "Mod4+Return         Alacritty (terminal)\n"
          printf "Alt+Space           Fuzzel (launcher)\n"
          printf "Mod4+d              Fuzzel (launcher)\n"
          printf "Mod4+e              PCManFM (dosya yöneticisi)\n"
          ;;
        *Windows*)
          printf "Mod4+q              Kapat\n"
          printf "Mod4+f              Tam ekran\n"
          printf "Mod4+r              Resize modu\n"
          printf "Mod4+Shift+space    Floating toggle\n"
          printf "Mod4+space          Focus mode_toggle\n"
          printf "Mod4+Shift+minus    Scratchpad'a gönder\n"
          printf "Mod4+minus          Scratchpad göster\n"
          printf "Mod4+arrows/hjkl    Odaklan\n"
          printf "Mod4+Shift+arrows   Taşı\n"
          ;;
        *Layout*)
          printf "Mod4+s              Stacking (üst üste)\n"
          printf "Mod4+w              Tabbed (sekme)\n"
          printf "Mod4+b              Splith (yan yana)\n"
          printf "Mod4+v              Splitv (alt alta)\n"
          ;;
        *Screenshot*)
          printf "Print               Bölge seç → Swappy\n"
          printf "Mod4+Print          Tam ekran → Swappy\n"
          printf "Mod4+Shift+s        Bölge seç → clipboard\n"
          printf "Mod4+Shift+a        Bölge → OCR (tesseract)\n"
          printf "Mod4+c              Cliphist (pano geçmişi)\n"
          ;;
        *Media*)
          printf "XF86AudioRaise      Ses +\n"
          printf "XF86AudioLower      Ses -\n"
          printf "XF86AudioMute       Sessiz\n"
          printf "XF86AudioNext/Prev  Sonraki/Önceki şarkı\n"
          printf "XF86AudioPlay       Oynat/Duraklat\n"
          printf "XF86MonBrightness+  Parlaklık +\n"
          printf "XF86MonBrightness-  Parlaklık -\n"
          printf "Caps_Lock           Caps OSD\n"
          printf "Mod4+l              Kilit ekranı\n"
          printf "Mod4+m              AGS Quick Settings\n"
          printf "Mod4+Escape         Power menu\n"
          printf "Mod4+k              Bu yardım\n"
          printf "Mod4+Shift+c        Config reload\n"
          printf "Mod4+Shift+e        Sway'den çıkış\n"
          printf "Mod4+Shift+i        Sistem bilgisi\n"
          printf "Mod4+Shift+r        Kayıt başlat/durdur\n"
          printf "Notification tıkla  Notification Center\n"
          printf "Notification sağ tık Bildirimleri temizle\n"
          ;;
      esac
    }

    while true; do
      cat=$(categories | fuzzel --dmenu --prompt="Kategori > " --width=35 --lines=8)
      [ -z "$cat" ] && break
      [ "$cat" = "  Exit" ] && break
      choice=$(bindings "$cat" | fuzzel --dmenu --prompt="Keybinds > " --width=55 --lines=16)
      [ -n "$choice" ] && break
    done
  '';

  sysinfo = pkgs.writeShellScriptBin "sysinfo" ''
    cpu=$(awk -v a="$(grep '^cpu ' /proc/stat)" -v b="$(sleep 0.5 && grep '^cpu ' /proc/stat)" 'BEGIN {
      split(a, x); split(b, y);
      idle = (y[5]-x[5]) / (y[2]+y[3]+y[4]+y[5]+y[6]+y[7]+y[8] - x[2]-x[3]-x[4]-x[5]-x[6]-x[7]-x[8]) * 100;
      used = 100 - idle;
      printf "%.1f", used
    }')
    temp=$(awk '{printf "%.0f°C", $1/1000}' /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo "N/A")
    mem=$(free -h | awk '/^Mem:/ {print $3 " / " $2 " (" $3/$2*100 "%)"}')
    bat_name=$(upower -e | grep -i bat | head -1)
    if [ -n "$bat_name" ]; then
      bat_info=$(upower -i "$bat_name" 2>/dev/null)
      bat_pct=$(echo "$bat_info" | awk '/percentage/{print $NF}')
      bat_state=$(echo "$bat_info" | awk '/state/{print $2}')
      bat_cycle=$(echo "$bat_info" | awk -F': +' '/cycle count/{print $2}')
      [ -z "$bat_cycle" ] && bat_cycle=$(awk '/CYCLE_COUNT/{print $2}' /sys/class/power_supply/BAT0/uevent 2>/dev/null || echo "-")
      health=$(cat /sys/class/power_supply/BAT0/energy_full_design 2>/dev/null)
      [ -n "$health" ] && health_pct=$(awk -v f="$health" -v n="$(cat /sys/class/power_supply/BAT0/energy_full)" 'BEGIN{printf "%.0f", n/f*100}')
      battery="    $bat_pct ($bat_state) — cycle: $bat_cycle, health: $health_pct%"
    else
      battery="    No battery"
    fi
    disk=$(df -h / /home 2>/dev/null | awk 'NR>1 {printf "    %s: %s / %s (%s)\n", $6, $3, $2, $5}')
    {
      printf "  System Info\n"
      printf "━━━━━━━━━━━━━━━━━━━━━━\n"
      printf "    CPU: %s%%\n" "$cpu"
      printf "    Temp: %s\n" "$temp"
      printf "    RAM: %s\n" "$mem"
      printf "%s\n" "$battery"
      printf "%s" "$disk"
    } | fuzzel --dmenu --prompt="" --width=55 --lines=12
  '';

  screenshot-region = pkgs.writeShellScriptBin "screenshot-region" ''
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

  screenshot-full = pkgs.writeShellScriptBin "screenshot-full" ''
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

  recording-toggle = pkgs.writeShellScriptBin "recording-toggle" ''
    if [ -f /tmp/recording-pid ] && kill -0 "$(cat /tmp/recording-pid)" 2>/dev/null; then
      kill "$(cat /tmp/recording-pid)" 2>/dev/null
      rm -f /tmp/recording-pid /tmp/recording-indicator
      pkill -RTMIN+3 .waybar-wrapped 2>/dev/null
      notify-send -i camera-video "Recording" "Kayıt durduruldu"
    else
      SAVE_DIR="''${XDG_VIDEOS_DIR:-$HOME/Videos/recordings}"
      mkdir -p "$SAVE_DIR"
      FILE="$SAVE_DIR/record-$(date +%Y%m%d-%H%M%S).mp4"
      touch /tmp/recording-indicator
      pkill -RTMIN+3 .waybar-wrapped 2>/dev/null
      wf-recorder -f "$FILE" -c h264_vaapi -d /dev/dri/renderD128 &
      echo $! > /tmp/recording-pid
      notify-send -i camera-video "Recording" "Kayıt başladı"
    fi
  '';

  recording-indicator = pkgs.writeShellScriptBin "recording-indicator" ''
    if [ -f /tmp/recording-indicator ]; then
      printf '{"text": "  ", "class": "recording", "tooltip": "Kayıt yapılıyor — tıkla durdur"}\n'
    else
      printf '{"text": "", "class": "idle"}\n'
    fi
  '';
in
{
  imports = [
    plasma-manager.homeModules.plasma-manager
    ./modules/desktop/sway
  ];
  home = {
    username = "can";
    homeDirectory = "/home/can";
    stateVersion = "26.05";
  };
  programs.home-manager.enable = true;
  gtk = {
    enable = true;
    gtk2.force = true;
    theme = {
      name = lib.mkForce "adw-gtk3-dark";
      package = lib.mkForce pkgs.adw-gtk3;
    };
    iconTheme.name = "Papirus-Dark";
    iconTheme.package = pkgs.papirus-icon-theme;
  };
  programs.alacritty = {
    enable = true;
    settings = {
      font = {
        normal.family = "JetBrainsMono Nerd Font";
        size = 10;
      };
      window = {
        padding = { x = 0; y = 0; };
        opacity = 1.0;
      };
      colors = {
        primary = {
          background = c.background;
          foreground = c.text;
        };
        normal = {
          black = c.background;
          red = c.urgent;
          green = "#acc267";
          yellow = "#ddb26f";
          blue = "#6fc2ef";
          magenta = "#e1a3ee";
          cyan = "#12cfc0";
          white = c.text;
        };
      };
    };
  };


  programs.bash = {
    enable = true;

    shellAliases = {
      # Directory
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      "~" = "cd ~";
      "-" = "cd -";
      tmp = "cd /tmp";

      # Git
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git log --oneline --graph --decorate --all";
      gd = "git diff";
      gco = "git checkout";
      gb = "git branch";

      # System
      cls = "clear";
      df = "df -h";
      free = "free -h";
      ports = "ss -tulanp";
      nixs = "sudo nixos-rebuild switch";
      nixup = "nix flake update";
      nixq = "nix search nixpkgs";
      ip = "ip -c";
      myip = "curl -s ifconfig.me";
      zcat = "cat /etc/nixos/home.nix";
      zedit = "$EDITOR /etc/nixos/home.nix";
      zreload = "sudo nixos-rebuild switch";
    };

    bashrcExtra = ''
      unalias zcat zhelp zedit zreload 2>/dev/null

      mkcd() { mkdir -p "$1" && cd "$1"; }

      extract() {
        case "$1" in
          *.tar.gz|*.tgz)    tar xzf "$1" ;;
          *.tar.xz|*.txz)    tar xf "$1"  ;;
          *.tar.bz2|*.tbz2)  tar xjf "$1" ;;
          *.tar.zst|*.tzst)  tar --zstd -xf "$1" ;;
          *.tar)             tar xf "$1"  ;;
          *.gz)              gunzip "$1"  ;;
          *.bz2)             bunzip2 "$1" ;;
          *.xz)              unxz "$1"    ;;
          *.zip)             unzip "$1"   ;;
          *.7z)              7z x "$1"    ;;
          *.rar)             unrar x "$1" ;;
          *.zst)             unzstd "$1"  ;;
          *) echo "Bilinmeyen format: $1" ;;
        esac
      }

      archive() {
        case "$1" in
          tgz)  tar czf "$2.tar.gz" "$2" ;;
          tbz2) tar cjf "$2.tar.bz2" "$2" ;;
          txz)  tar cJf "$2.tar.xz" "$2" ;;
          tzst) tar --zstd -cf "$2.tar.zst" "$2" ;;
          zip)  zip -r "$2.zip" "$2" ;;
          7z)   7z a "$2.7z" "$2" ;;
          *) echo "Kullanım: archive <tgz|tbz2|txz|tzst|zip|7z> <dizin/dosya>" ;;
        esac
      }

      zhelp() {
        echo -e "\033[1;36m━━━ Z Yönetim ━━━━━━━━━━━━━━━━━━━━━\033[0m"
        printf "  \033[1;32m%-12s\033[0m → %s\n" "zcat"    "Nix config içeriğini göster"
        printf "  \033[1;32m%-12s\033[0m → %s\n" "zhelp"   "bu yardımı göster"
        printf "  \033[1;32m%-12s\033[0m → %s\n" "zedit"   "Nix config'i düzenle"
        printf "  \033[1;32m%-12s\033[0m → %s\n" "zreload" "NixOS'u yeniden derle"

        echo -e "\n\033[1;36m━━━ Dizin ━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
        printf "  \033[1;32m%-12s\033[0m → %s\n" ".."   "bir üst dizin"
        printf "  \033[1;32m%-12s\033[0m → %s\n" "..."  "iki üst dizin"
        printf "  \033[1;32m%-12s\033[0m → %s\n" "...." "üç üst dizin"
        printf "  \033[1;32m%-12s\033[0m → %s\n" "~"    "home dizini"
        printf "  \033[1;32m%-12s\033[0m → %s\n" "-"    "önceki dizin"

        echo -e "\n\033[1;36m━━━ Git ━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
        printf "  \033[1;32m%-12s\033[0m → %s\n" "gs"  "git status"
        printf "  \033[1;32m%-12s\033[0m → %s\n" "ga"  "git add"
        printf "  \033[1;32m%-12s\033[0m → %s\n" "gc"  "git commit"
        printf "  \033[1;32m%-12s\033[0m → %s\n" "gp"  "git push"
        printf "  \033[1;32m%-12s\033[0m → %s\n" "gl"  "git log (grafikli)"
        printf "  \033[1;32m%-12s\033[0m → %s\n" "gd"  "git diff"
        printf "  \033[1;32m%-12s\033[0m → %s\n" "gco" "git checkout"
        printf "  \033[1;32m%-12s\033[0m → %s\n" "gb"  "git branch"

        echo -e "\n\033[1;36m━━━ Dizin İşlemleri ━━━━━━━━━━━━━\033[0m"
        printf "  \033[1;32m%-12s\033[0m → %s\n" "mkcd"    "dizin oluştur + gir"
        printf "  \033[1;32m%-12s\033[0m → %s\n" "tmp"     "/tmp dizinine git"
        printf "  \033[1;32m%-12s\033[0m → %s\n" "extract" "arşiv çıkar (.tar.gz, .zip, ...)"
        printf "  \033[1;32m%-12s\033[0m → %s\n" "archive" "arşivle (tgz, tbz2, zip, ...)"

        echo -e "\n\033[1;36m━━━ NixOS & Sistem ━━━━━━━━━━━━━━━━\033[0m"
        printf "  \033[1;32m%-12s\033[0m → %s\n" "nixs"  "sudo nixos-rebuild switch"
        printf "  \033[1;32m%-12s\033[0m → %s\n" "cls"   "ekranı temizle"
        printf "  \033[1;32m%-12s\033[0m → %s\n" "df"    "disk kullanımı"
        printf "  \033[1;32m%-12s\033[0m → %s\n" "free"  "ram kullanımı"
        printf "  \033[1;32m%-12s\033[0m → %s\n" "ports" "açık portları göster"
        printf "  \033[1;32m%-12s\033[0m → %s\n" "ip"    "renkli ağ yönetimi"
        printf "  \033[1;32m%-12s\033[0m → %s\n" "myip"  "public IP göster"
        printf "  \033[1;32m%-12s\033[0m → %s\n" "nixup" "flake.lock güncelle"
        printf "  \033[1;32m%-12s\033[0m → %s\n" "nixq"  "nixpkgs'te paket ara"
      }
    '';
  };

  home.packages = with pkgs; [
    vesktop-wrapped
    keybinds-help
    powermenu
    sysinfo
    screenshot-region
    screenshot-full
    recording-toggle
    recording-indicator
    jetbrains-mono
    nerd-fonts.jetbrains-mono
    grim slurp wl-clipboard
    libnotify
    cliphist
    playerctl
    tesseract5
    alacritty
    fuzzel
    waybar
    swaynotificationcenter
    swaylock swayidle swaybg
    networkmanagerapplet pavucontrol
    swayosd
    ags
    swappy
    imv
    mpv
    wf-recorder
    file-roller
  ];
  home.sessionVariables = {
    XDG_CURRENT_DESKTOP = "KDE";
    XDG_SESSION_TYPE = "wayland";
    QT_QPA_PLATFORM = "wayland;xcb";
    NIXOS_OZONE_WL = "1";
  };

  stylix.targets.fuzzel.enable = false;
  stylix.targets.sway.enable = false;
  stylix.targets.alacritty.enable = false;

  xdg.configFile."swappy/config".text = ''
    [Default]
    early_exit=true
    save_dir=$HOME/Pictures/screenshots
    save_filename_format=screenshot-%Y%m%d-%H%M%S.png
    show_panel=false
    line_size=5
    text_size=20
    text_font=sans-serif
    paint_mode=brush
    fill_shape=false
    auto_save=false
    custom_color=rgba(193,125,17,1)
    transparent=false
    transparency=50
  '';

  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        terminal = "alacritty";
        font = "JetBrains Mono:size=12";
        dpi-aware = false;
        width = 40;
        lines = 15;
        horizontal-pad = 16;
        vertical-pad = 8;
        inner-pad = 4;
        prompt = ">> ";
        icon-theme = "Papirus-Dark";
      };
      colors = {
        background = "#1e1e1edd";
        text = "#ccccccff";
        match = "#ffffffff";
        selection = "#3a3a3aff";
        selection-text = "#ffffffff";
        selection-match = "#ffffffff";
        border = "#888888ff";
        prompt = "#ccccccff";
        input = "#ccccccff";
        placeholder = "#777777ff";
        counter = "#777777ff";
        message = "#ccccccff";
      };
      border = {
        radius = 8;
        width = 2;
      };
    };
  };

  programs.plasma = {
    enable = true;
    shortcuts = {
      "kwin" = {
        "Switch One Desktop to the Left" = "Ctrl+Left";
        "Switch One Desktop to the Right" = "Ctrl+Right";
        "Window to Previous Desktop" = "Ctrl+Shift+Left";
        "Window to Next Desktop" = "Ctrl+Shift+Right";
      };
    };
    panels = [
      {
        location = "bottom";
        height = 44;
        widgets = [
          "org.kde.plasma.kickoff"
          "org.kde.plasma.pager"
          { panelSpacer = { expanding = true; }; }
          {
            iconTasks = {
              settings = {
                General = {
                  useCustomStyle = true;
                  customIconStyle = 2;
                };
              };
            };
          }
          { panelSpacer = { expanding = true; }; }
          "org.kde.plasma.marginsseparator"
          "org.kde.plasma.systemtray"
          "org.kde.plasma.digitalclock"
          "org.kde.plasma.showdesktop"
        ];
      }
    ];
  };
}
