{ config, pkgs, lib, ... }: {
  wayland.windowManager.sway.config.keybindings = lib.mkOptionDefault {
    "Mod4+l" = "exec swaylock -f";
    "Alt+Space" = "exec vicinae toggle";
    "Mod4+Shift+s" = "exec grim -g \"$(slurp -d)\" - | wl-copy";
    "Mod4+Shift+a" = "exec grim -g \"$(slurp)\" - | tesseract stdin stdout -l tur | wl-copy";
    "Mod4+e" = "exec thunar";
    "Mod4+Shift+space" = "exec qs ipc call windows toggle";
    "Mod4+m" = "exec qs ipc call notif toggle";
    "XF86AudioRaiseVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ --limit 1.0 && qs ipc call osd volume";
    "XF86AudioLowerVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && qs ipc call osd volume";
    "XF86AudioMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && qs ipc call osd volume";
    "XF86AudioMicMute" = "exec micmute";
    "F4" = "exec micmute";
    "XF86MonBrightnessUp" = "exec sh -c 'brightnessctl s +5%; ddcutil setvcp 10 + 5 --display 1 --noverify 2>/dev/null || true; qs ipc call osd brightness'";
    "XF86MonBrightnessDown" = "exec sh -c 'brightnessctl s 5%-; ddcutil setvcp 10 - 5 --display 1 --noverify 2>/dev/null || true; qs ipc call osd brightness'";
    "Caps_Lock" = "exec qs ipc call osd caps";
    "XF86AudioNext" = "exec playerctl next";
    "XF86AudioPause" = "exec playerctl play-pause";
    "XF86AudioPlay" = "exec playerctl play-pause";
    "XF86AudioPrev" = "exec playerctl previous";
    "Print" = "exec qs ipc call capture toggle";
    "Mod4+Ctrl+c" = "exec qs ipc call capture toggle";
    "Mod4+Print" = "exec screenshot-full";
    "Mod4+q" = "kill";
    "Mod4+Escape" = "exec qs ipc call power toggle";
    "Mod4+p" = "exec qs ipc call power toggle";
    "Mod4+Shift+r" = "exec recording-toggle";
  };
}
