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
    for i in $(seq 1 15); do
      if ss -tlnp 2>/dev/null | grep -q 4452; then
        break
      fi
      sleep 1
    done
    export HTTP_PROXY="http://127.0.0.1:4452"
    export HTTPS_PROXY="http://127.0.0.1:4452"
    exec ${pkgs.vesktop}/bin/vesktop "$@"
  '';

  scripts = import ./modules/desktop/sway/scripts { inherit pkgs; };
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
  ] ++ scripts ++ [
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
    brightnessctl
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
