{ config, pkgs, lib, stylix, ihtc, ... }:
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
    ss=${pkgs.iproute2}/bin/ss
    if ! $ss -tln 2>/dev/null | grep -q '127.0.0.1:4452'; then
      ${pkgs.util-linux}/bin/setsid ${ihtc.packages.x86_64-linux.ihtc}/bin/ihtc \
        --listen 127.0.0.1:4452 --regex 'discord|discordapp|googleapis' >/dev/null 2>&1 &
      for i in $(seq 1 30); do
        $ss -tln 2>/dev/null | grep -q '127.0.0.1:4452' && break
        sleep 0.1
      done
    fi
    export HTTP_PROXY="http://127.0.0.1:4452"
    export HTTPS_PROXY="http://127.0.0.1:4452"

    if ${pkgs.procps}/bin/pgrep -f 'Vesktop/resources/app.asar' >/dev/null 2>&1; then
      ${pkgs.sway}/bin/swaymsg '[app_id="vesktop"] focus' >/dev/null 2>&1 \
        || ${pkgs.sway}/bin/swaymsg '[class="vesktop"] focus' >/dev/null 2>&1
      exec ${pkgs.vesktop}/bin/vesktop --ozone-platform=wayland "$@"
    fi

    lock="$HOME/.config/vesktop/SingletonLock"
    if [ -L "$lock" ]; then
      owner=$(readlink "$lock")
      pid=''${owner##*-}
      if [ -n "$pid" ] && ! kill -0 "$pid" 2>/dev/null; then
        rm -f "$lock"
      fi
    fi
    exec ${pkgs.vesktop}/bin/vesktop --ozone-platform=wayland "$@"
  '';

  scripts = import ./modules/desktop/sway/scripts { inherit pkgs; };
in
{
  imports = [
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
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      "~" = "cd ~";
      "-" = "cd -";
      tmp = "cd /tmp";

      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git log --oneline --graph --decorate --all";
      gd = "git diff";
      gco = "git checkout";
      gb = "git branch";

      cls = "clear";
      df = "df -h";
      free = "free -h";
      ports = "ss -tulanp";
      nixs = "sudo nixos-rebuild switch";
      nixup = "nix flake update --flake /etc/nixos";
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

      shell() { nix shell "nixpkgs#$1"; }

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
  ] ++ scripts ++ [
    nerd-fonts.jetbrains-mono
    grim slurp wl-clipboard
    libnotify
    playerctl
    claude-code
    tesseract5
    alacritty
    swaylock swayidle swaybg
    networkmanagerapplet pavucontrol
    ags
    swappy
    imv
    mpv
    vicinae
    wf-recorder
    brightnessctl
    file-roller
  ];
  home.sessionVariables = {
    XDG_SESSION_TYPE = "wayland";
    QT_QPA_PLATFORM = "wayland;xcb";
    NIXOS_OZONE_WL = "1";
    WEBRTC_USE_PIPEWIRE = "1";
  };

  stylix.targets.sway.enable = false;
  stylix.targets.alacritty.enable = false;

  xdg.configFile."swappy/config".text = ''
    [Default]
    early_exit=true
    save_dir=$HOME/Pictures/screenshots
    save_filename_format=screenshot-%Y%m%d-%H%M%S.png
    show_panel=true
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

  xdg.configFile."vicinae/settings.json".text = builtins.toJSON {
    telemetry = { system_info = false; };
    search_files_in_root = false;
    close_on_focus_loss = true;
    pop_to_root_on_close = true;
    font = {
      rendering = "qt";
      normal = {
        family = "JetBrainsMono Nerd Font";
        size = 12;
      };
    };
    theme = {
      light = {
        name = "can-dark";
        icon_theme = "Papirus-Dark";
      };
      dark = {
        name = "can-dark";
        icon_theme = "Papirus-Dark";
      };
    };
    launcher_window = {
      opacity = 0.96;
      blur = { enabled = true; };
      material = "blur";
      rounding = 7;
      layer_shell = {
        enabled = true;
        keyboard_interactivity = "on_demand";
        layer = "overlay";
      };
      client_side_decorations = {
        enabled = true;
        border_width = 1;
        shadow_size = 12;
      };
      size = {
        width = 620;
        height = 460;
      };
    };
  };

  xdg.configFile."vicinae/themes/can-dark.toml".text = ''
    [meta]
    name = "can-dark"
    description = "Can dark monochrome theme"
    variant = "dark"
    inherits = "vicinae-dark"

    [colors.core]
    accent = "#FFFFFF"
    accent_foreground = "#000000"
    background = "#000000"
    foreground = "#FFFFFF"
    secondary_background = "#0A0A0A"
    border = "#1F1F22"

    [colors.main_window]
    border = "#1F1F22"

    [colors.accents]
    blue = "#A0A0A0"
    green = "#FFFFFF"
    magenta = "#A0A0A0"
    orange = "#A0A0A0"
    red = "#FFFFFF"
    yellow = "#FFFFFF"
    cyan = "#A0A0A0"
    purple = "#A0A0A0"

    [colors.text]
    default = "colors.core.foreground"
    muted = "#A0A0A0"
    placeholder = "#666666"
    selection = { background = "#1E1E22", foreground = "#FFFFFF" }

    [colors.text.links]
    default = "#FFFFFF"
    visited = "#A0A0A0"

    [colors.input]
    border = "#1F1F22"
    border_focus = "#FFFFFF"

    [colors.list.item.selection]
    background = "#1E1E22"
    foreground = "#FFFFFF"
    secondary_background = "#1E1E22"
    secondary_foreground = "#A0A0A0"

    [colors.list.item.hover]
    foreground = "#FFFFFF"
    secondary_foreground = "#A0A0A0"

    [colors.scrollbars]
    background = "#333333"

    [colors.loading]
    bar = "#FFFFFF"
    spinner = "#FFFFFF"
  '';

  xdg.dataFile."applications/vesktop.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Vesktop
    Comment=Discord client
    Exec=vesktop %U
    Icon=vesktop
    Terminal=false
    Categories=Network;InstantMessaging;
    StartupWMClass=Vesktop
  '';

  xdg.configFile."mozilla/firefox/r8rx6oul.default/chrome/userChrome.css".text = ''
    @namespace url(http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul);
    * { font-size: 14px !important; }
  '';

  systemd.user.services.vicinae = {
    Unit = {
      Description = "Vicinae Launcher Daemon";
      After = [ "graphical-session.target" "sway-session.target" ];
      PartOf = [ "graphical-session.target" ];
      Requires = [ "dbus.socket" ];
    };
    Service = {
      Type = "simple";
      Environment = [
        "QT_QPA_PLATFORM=wayland"
        "WAYLAND_DISPLAY=wayland-1"
        "USE_LAYER_SHELL=1"
      ];
      ExecStartPre = "${pkgs.bash}/bin/bash -c 'n=0; while [ ! -S \"$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY\" ]; do n=$((n+1)); [ $n -ge 100 ] && exit 1; ${pkgs.coreutils}/bin/sleep 0.1; done'";
      ExecStart = "${pkgs.vicinae}/bin/vicinae server --replace";
      Restart = "always";
      RestartSec = 2;
      KillMode = "process";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

}
