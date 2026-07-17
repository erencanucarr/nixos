{ config, pkgs, lib, plasma-manager, stylix, ... }:
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
    export HTTP_PROXY="http://127.0.0.1:4452"
    export HTTPS_PROXY="http://127.0.0.1:4452"
    exec ${pkgs.vesktop}/bin/vesktop "$@"
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
    ════════════════════════════════════════════════════════
    Screenshot
    ════════════════════════════════════════════════════════
    Print               Tam ekran → Swappy düzenle
    Mod4+Print          Bölge seç → Swappy düzenle
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
    Mod4+k              Bu yardım
    Mod4+Shift+c        Config reload
    Mod4+Shift+e        Çıkış
    BINDS
  '';
in
{
  imports = [
    plasma-manager.homeModules.plasma-manager
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

  programs.swaylock.enable = true;

  home.packages = with pkgs; [
    vesktop-wrapped
    keybinds-help
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

  wayland.windowManager.sway = {
    enable = true;
    checkConfig = false;
    systemd = {
      enable = true;
      variables = [
        "DISPLAY"
        "NIXOS_OZONE_WL"
        "PATH"
        "QT_QPA_PLATFORM"
        "SWAYSOCK"
        "WAYLAND_DISPLAY"
        "XCURSOR_SIZE"
        "XCURSOR_THEME"
        "XDG_CURRENT_DESKTOP"
        "XDG_DATA_DIRS"
        "XDG_SESSION_TYPE"
      ];
      xdgAutostart = true;
    };
    config = {
      modifier = "Mod4";
      terminal = "alacritty";
      menu = "fuzzel";
      gaps = {
        inner = 1;
        outer = 0;
      };
      window.border = 2;
      floating.border = 0;
      window.titlebar = false;
      window.hideEdgeBorders = "none";
      focus.mouseWarping = false;
      input."type:keyboard".xkb_layout = "tr";
      colors = {
        background = c.background;
        focused = {
          background = c.active;
          border = c.active;
          text = c.background;
          indicator = c.active;
          childBorder = c.active;
        };
        focusedInactive = {
          background = c.inactive;
          border = c.inactive;
          text = c.text;
          indicator = c.inactive;
          childBorder = c.inactive;
        };
        unfocused = {
          background = c.background;
          border = c.background;
          text = c.text;
          indicator = c.background;
          childBorder = c.background;
        };
        urgent = {
          background = c.urgent;
          border = c.urgent;
          text = c.background;
          indicator = c.urgent;
          childBorder = c.urgent;
        };
        placeholder = {
          background = c.background;
          border = c.background;
          text = c.text;
          indicator = c.background;
          childBorder = c.background;
        };
      };
      keybindings = lib.mkOptionDefault {
        "Mod4+l" = "exec swaylock -f";
        "Alt+Space" = "exec fuzzel";
        "Mod4+Shift+s" = "exec grim -g \"$(slurp -d)\" - | wl-copy";
        "Mod4+Shift+a" = "exec grim -g \"$(slurp)\" - | tesseract stdin stdout -l tur | wl-copy";
        "Mod4+c" = "exec cliphist list | fuzzel --dmenu | cliphist decode | wl-copy";
        "Mod4+e" = "exec pcmanfm";
        "Mod4+Shift+space" = "floating toggle";
        "Mod4+m" = "exec ags -t quicksettings";
        "XF86AudioRaiseVolume" = "exec swayosd-client --output-volume raise";
        "XF86AudioLowerVolume" = "exec swayosd-client --output-volume lower";
        "XF86AudioMute" = "exec swayosd-client --output-volume mute-toggle";
        "XF86MonBrightnessUp" = "exec swayosd-client --brightness raise";
        "XF86MonBrightnessDown" = "exec swayosd-client --brightness lower";
        "Caps_Lock" = "exec swayosd-client --caps-lock";
        "XF86AudioNext" = "exec playerctl next";
        "XF86AudioPause" = "exec playerctl play-pause";
        "XF86AudioPlay" = "exec playerctl play-pause";
        "XF86AudioPrev" = "exec playerctl previous";
        "Print" = "exec grim - | swappy -f -";
        "Mod4+Print" = "exec grim -g \"$(slurp)\" - | swappy -f -";
      };
      floating.criteria = [
        { title = "Picture-in-Picture"; }
        { app_id = "pcmanfm"; }
        { app_id = "pavucontrol"; }
        { app_id = "nm-connection-editor"; }
      ];
      bars = [
        {
          hiddenState = "hide";
          mode = "invisible";
        }
      ];
      startup = [
        { command = "${pkgs.swaybg}/bin/swaybg -i ${config.stylix.image} -m fill > /dev/null 2>&1"; }
        { command = "waybar > /dev/null 2>&1"; }
        { command = "swaync > /dev/null 2>&1"; }
        { command = "swayosd-server > /dev/null 2>&1"; }
        { command = "ags > /dev/null 2>&1 &"; }
        { command = "swaymsg workspace number 1"; }
        { command = "nm-applet"; }
        { command = "blueman-applet"; }
        { command = "wl-paste --type text --watch cliphist store"; }
        { command = "wl-paste --type image --watch cliphist store"; }
      ];
    };
      extraConfig = ''
        workspace_auto_back_and_forth yes
        smart_gaps on
        smart_borders on
        bindsym Ctrl+Left workspace prev
        bindsym Ctrl+Right workspace next
        bindsym Ctrl+Tab workspace next
        bindsym Ctrl+Shift+Tab workspace prev
        bindsym Mod4+Tab workspace next
        bindsym Mod4+Shift+Tab workspace prev

        exec swayidle -w \
          timeout 300 'swaylock -f' \
          timeout 600 'swaymsg "output * dpms off"' \
               resume 'swaymsg "output * dpms on"' \
          before-sleep 'swaylock -f'

        bindsym --no-warn Mod4+k exec keybinds-help
      '';
  };

  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 38;
        spacing = 4;
        modules-left = [
          "sway/workspaces"
          "mpris"
        ];
        modules-center = [
          "sway/window"
        ];
        modules-right = [
          "idle_inhibitor"
          "custom/notification"
          "network"
          "pulseaudio"
          "clock"
          "battery"
          "tray"
        ];

        "sway/workspaces" = {
          disable-scroll = true;
          all-outputs = true;
          format = "{name}";
        };

        "sway/window" = {
          format = "{}";
          empty-format = "";
          separate-outputs = true;
          max-length = 50;
          tooltip = false;
        };

        clock = {
          format = "{:%a %d %b  %H:%M}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };

        pulseaudio = {
          format = "{icon} {volume}%";
          format-muted = "MUTED";
          format-icons = {
            default = [ "" "" "" ];
          };
          on-click = "pavucontrol";
        };

        network = {
          format-wifi = "{essid}";
          format-ethernet = "{ipaddr}";
          format-disconnected = "";
          interval = 3;
          on-click = "nm-connection-editor";
        };

        battery = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{icon} {capacity}%";
          format-charging = " {capacity}%";
          format-plugged = " {capacity}%";
          format-icons = [ "" "" "" "" "" ];
        };

        tray = {
          spacing = 10;
        };

        mpris = {
          format = "{player_icon} {dynamic}";
          format-paused = "{status_icon} <i>{dynamic}</i>";
          player-icons = {
            default = "▶";
            mpv = "🎵";
          };
          status-icons = {
            paused = "⏸";
          };
          max-length = 30;
          tooltip-format = "{player} : {title}";
        };

        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = "󰅶";
            deactivated = "󰾫";
          };
        };

        "custom/notification" = {
          tooltip = false;
          format = "{icon}";
          format-icons = {
            notification = "";
            dnd-notification = "";
            dnd-none = "";
          };
          return-type = "json";
          exec = "swaync-client -swb";
          on-click = "swaync-client -t";
          on-click-right = "swaync-client -d";
          escape = true;
        };
      };
    };
    style = ''
      * {
          font-family: "JetBrains Mono";
          font-size: 14px;
          min-height: 0;
          font-weight: bold;
      }

      window#waybar {
          background-color: ${c.background};
          color: ${c.text};
      }

      window#waybar.hidden {
        opacity: 0;
      }

      window#waybar.empty #window {
          background-color: transparent;
          border: none;
          padding: 0;
          margin: 0;
      }

      tooltip {
        background: ${c.background};
        border: 1px solid ${c.active};
        padding: 8px 12px;
      }

      tooltip label {
        color: ${c.text};
      }

      #workspaces {
          margin: 4px 2px;
      }

      #window.empty {
          background-color: transparent;
          color: transparent;
          padding: 0;
          margin: 0;
          border: none;
      }

#window,
#network,
#pulseaudio,
#clock,
#idle_inhibitor,
#mpris,
#tray,
#custom-notification {
          background-color: ${c.inactive};
          color: ${c.text};
          border: 1px solid ${c.active};
          border-radius: 0;
          margin: 4px 2px;
          padding: 0 8px;
      }

      #workspaces button {
          background-color: ${c.background};
          color: ${c.text};
          border-radius: 0;
          margin: 0 2px;
          padding: 0 8px;
          border: none;
          transition: all 0.2s ease;
      }

      #workspaces button:hover {
          background-color: ${c.active};
          box-shadow: none;
      }

      #workspaces button.focused {
          background-color: ${c.inactive};
          border: 1px solid ${c.active};
          color: ${c.text};
      }

      #workspaces button.urgent {
          background-color: ${c.urgent};
          color: ${c.background};
      }

      #tray > .passive {
          -gtk-icon-effect: dim;
      }

      #tray > .needs-attention {
          -gtk-icon-effect: highlight;
          background-color: ${c.urgent};
      }

      #battery,
#custom-notification {
          background-color: ${c.inactive};
          color: ${c.text};
          border: 1px solid ${c.active};
          border-radius: 0;
          margin: 4px 2px;
          padding: 0 8px;
      }

      #battery.charging,
      #battery.plugged {
          background-color: #7cb342;
          color: #000000;
      }

      #battery.critical:not(.charging) {
          background-color: #eb4d4b;
          color: #ffffff;
          animation-name: blink;
          animation-duration: 0.5s;
          animation-timing-function: linear;
          animation-iteration-count: infinite;
          animation-direction: alternate;
      }

      @keyframes blink {
          to {
              background-color: #ffffff;
              color: #eb4d4b;
          }
      }
    '';
  };

  services.swaync = {
    enable = true;
    settings = {
      control-center-height = 2;
      control-center-layer = "overlay";
      control-center-margin-bottom = 20;
      control-center-margin-left = 0;
      control-center-margin-right = 10;
      control-center-margin-top = 20;
      control-center-width = 500;
      control-center-positionX = "right";
      control-center-positionY = "center";
      fit-to-screen = true;
      hide-on-action = false;
      hide-on-clear = true;
      image-visibility = "when-available";
      keyboard-shortcuts = true;
      layer = "overlay";
      notification-body-image-height = 100;
      notification-body-image-width = 200;
      notification-icon-size = 40;
      notification-inline-replies = true;
      notification-window-width = 400;
      positionX = "right";
      positionY = "top";
      timeout = 10;
      timeout-critical = 0;
      timeout-low = 5;
      transition-time = 100;
      widgets = [
        "title"
        "buttons-grid"
        "dnd"
        "mpris"
        "volume"
        "notifications"
      ];
      widget-config = {
        title = {
          text = "Notifications";
          button-text = "Clear";
          clear-all-button = true;
        };
        dnd = {
          text = "Do Not Disturb";
        };
        mpris = {
          image-radius = 3;
          image-size = 96;
        };
        notifications = {
          clear-all-button = true;
        };
        volume = {
          label = " ";
          show-per-app = true;
          show-per-app-icon = true;
          show-per-app-label = true;
        };
        "buttons-grid" = {
          actions = [
            {
              label = "";
              command = "nm-connection-editor";
            }
            {
              label = "";
              command = "blueman-manager";
            }
            {
              label = "󰹑";
              command = "grim -g \"$(slurp)\" - | wl-copy";
            }
            {
              label = "󰑊";
              command = "killall wf-recorder || wf-recorder -f /tmp/recording.mp4 &";
            }
            {
              label = "󰆍";
              command = "cliphist list | fuzzel --dmenu | cliphist decode | wl-copy";
            }
      ];
    };
    extraConfig = ''
      workspace_auto_back_and_forth yes
      smart_gaps on
      smart_borders on
      bindsym Ctrl+Left workspace prev
      bindsym Ctrl+Right workspace next
      bindsym Ctrl+Tab workspace next
      bindsym Ctrl+Shift+Tab workspace prev
      bindsym Mod4+Tab workspace next
      bindsym Mod4+Shift+Tab workspace prev

      exec swayidle -w \
        timeout 300 'swaylock -f' \
        timeout 600 'swaymsg "output * dpms off"' \
             resume 'swaymsg "output * dpms on"' \
        before-sleep 'swaylock -f'

      bindsym --no-warn Mod4+k exec keybinds-help
    '';
  };
    };
    style = ''
      @define-color bg ${c.background};
      @define-color bg-alt ${c.inactive};
      @define-color border ${c.active};
      @define-color text ${c.text};
      @define-color urgent ${c.urgent};

      * {
        font-family: "JetBrains Mono";
        font-size: 13px;
      }

      .notification-background .notification {
        margin: 0; padding: 0;
        background-color: @bg;
        border: none;
      }
      .notification-content {
        padding: 1rem 1.25rem;
        background-color: @bg-alt;
        border-left: 2px solid @border;
      }
      .notification.critical .notification-content {
        border-left: 2px solid @urgent;
      }
      .notification .summary {
        font-size: 1rem;
        color: @text;
      }
      .notification .body {
        font-size: 0.9rem;
        color: @text;
      }

      .control-center {
        background-color: @bg;
        border: 1px solid @border;
        padding: 1rem;
      }
      .widget-title label {
        font-weight: 600;
        font-size: 1.1rem;
        color: @text;
      }

      .buttons-grid {
        margin: 4px 0;
        spacing: 6px;
      }
      .buttons-grid button {
        background-color: @bg-alt;
        color: @text;
        border: 1px solid @border;
        border-radius: 0;
        padding: 8px 12px;
        font-size: 1rem;
        min-width: 40px;
      }
      .buttons-grid button:hover {
        background-color: @border;
      }

      .widget-mpris {
        background-color: @bg-alt;
        border: 1px solid @border;
        padding: 8px 12px;
        margin: 4px 0;
      }
      .widget-mpris label {
        color: @text;
      }
    '';
  };

  stylix.targets.swaync.enable = false;
  stylix.targets.waybar.enable = false;
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
      };
      colors = {
        background = "${c.background}dd";
        text = "${c.text}";
        match = "${c.active}";
        selection = "${c.inactive}";
        selection-text = "${c.text}";
        border = "${c.active}";
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
