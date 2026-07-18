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
    cat <<'BINDS' | fuzzel --dmenu --prompt="Keybinds > " --width=65 --lines=25
    ════════════════════════════════════════════════════════
    Navigation
    ════════════════════════════════════════════════════════
    Mod4+1-9            Workspace 1-9
    Mod4+0              Workspace 10
    Ctrl+Left           Workspace önceki
    Ctrl+Right          Workspace sonraki
    Ctrl+Tab            Workspace sonraki
    Ctrl+Shift+Tab      Workspace önceki
    Mod4+Tab            Workspace sonraki
    Mod4+Shift+Tab      Workspace önceki
    Mod4+Shift+1-9      Pencereyi workspace'e taşı
    Mod4+a              Parent container (yukarı çık)
    Mod4+grave (`)      Scratchpad toggle
    ════════════════════════════════════════════════════════
    Launch
    ════════════════════════════════════════════════════════
    Mod4+Return         Alacritty (terminal)
    Alt+Space           Fuzzel (launcher)
    Mod4+d              Fuzzel (launcher)
    Mod4+e              PCManFM (dosya yöneticisi)
    ════════════════════════════════════════════════════════
    Windows
    ════════════════════════════════════════════════════════
    Mod4+q              Kapat
    Mod4+f              Tam ekran
    Mod4+v              Dikey böl
    Mod4+b              Yatay böl
    Mod4+Shift+space    Floating toggle
    Mod4+space          Focus mode_toggle
    Mod4+Shift+minus    Scratchpad
    Mod4+minus          Scratchpad göster
    Mod4+arrows/hjkl    Odaklan
    Mod4+Shift+arrows   Taşı
    Mod4+r              Resize modu
    Mod4+s              Stacking layout (üst üste)
    Mod4+w              Tabbed layout (sekme)
    Mod4+b              Splith layout (yan yana)
    Mod4+v              Splitv layout (alt alta)
    ════════════════════════════════════════════════════════
    Screenshot
    ════════════════════════════════════════════════════════
    Print               Bölge seç → Swappy düzenle
    Mod4+Print          Tam ekran → Swappy düzenle
    Mod4+Shift+s        Bölge seç → clipboard
    Mod4+Shift+a        Bölge → OCR (tesseract)
    Mod4+c              Cliphist (pano geçmişi)
    ════════════════════════════════════════════════════════
    Media / System
    ════════════════════════════════════════════════════════
    XF86AudioRaise      Ses +
    XF86AudioLower      Ses -
    XF86AudioMute       Sessiz
    XF86AudioNext/Prev  Sonraki/Önceki şarkı
    XF86AudioPlay       Oynat/Duraklat
    XF86MonBrightness+  Parlaklık +
    XF86MonBrightness-  Parlaklık -
    Caps_Lock           Caps OSD
    Mod4+l              Kilit ekranı
    Mod4+m              AGS Quick Settings
    Mod4+Escape         Power menu
    Mod4+k              Bu yardım
    🔔 (tıkla)          Notification Center
    🔔 (sağ tık)        Bildirimleri temizle
    Mod4+Shift+c        Config reload
    Mod4+Shift+e        Çıkış
    BINDS
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


  home.packages = with pkgs; [
    vesktop-wrapped
    keybinds-help
    powermenu
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
