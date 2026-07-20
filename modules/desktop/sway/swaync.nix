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
              command = "recording-toggle";
            }
            {
              label = "󰆍";
              command = "cliphist list | fuzzel --dmenu | cliphist decode | wl-copy";
            }
          ];
        };
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
}
