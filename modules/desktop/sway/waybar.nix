{ config, pkgs, lib, ... }:
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
in {
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
          "custom/powermenu"
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
          format-charging = "{icon}  {capacity}%";
          format-plugged = "{icon}  {capacity}%";
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

        "custom/powermenu" = {
          tooltip = false;
          format = "⏻";
          on-click = "powermenu";
        };
      };
    };
    style = ''
      * {
          font-family: "JetBrainsMono Nerd Font";
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
#custom-notification,
#custom-powermenu {
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
      #custom-notification,
      #custom-powermenu {
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

  stylix.targets.waybar.enable = false;

  systemd.user.services.waybar = {
    Unit = {
      Description = "Waybar";
      PartOf = [ "sway-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.waybar}/bin/waybar";
      Restart = "on-failure";
      RestartSec = 1;
    };
    Install = {
      WantedBy = [ "sway-session.target" ];
    };
  };
}
