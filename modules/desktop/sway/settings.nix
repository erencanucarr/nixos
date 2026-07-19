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

      bindswitch --locked lid:on output eDP-1 disable
      bindswitch --locked lid:off output eDP-1 enable
    '';
  };

  programs.swaylock.enable = true;
}
