{ config, pkgs, lib, ... }: {
  wayland.windowManager.sway.config.keybindings = lib.mkOptionDefault {
    "Mod4+l" = "exec swaylock -f";
    "Alt+Space" = "exec vicinae toggle";
    "Mod4+Shift+s" = "exec grim -g \"$(slurp -d)\" - | wl-copy";
    "Mod4+Shift+a" = "exec grim -g \"$(slurp)\" - | tesseract stdin stdout -l tur | wl-copy";
    "Mod4+c" = "exec cliphist-menu";
    "Mod4+e" = "exec thunar";
    "Mod4+Shift+space" = "floating toggle";
    "Mod4+m" = "exec qs ipc call notif toggle";
    "XF86AudioRaiseVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ --limit 1.0 && qs ipc call osd volume";
    "XF86AudioLowerVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && qs ipc call osd volume";
    "XF86AudioMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && qs ipc call osd volume";
    "XF86AudioMicMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle && qs ipc call osd mic";
    "XF86MonBrightnessUp" = "exec brightnessctl s +5% && qs ipc call osd brightness";
    "XF86MonBrightnessDown" = "exec brightnessctl s 5%- && qs ipc call osd brightness";
    "Caps_Lock" = "exec qs ipc call osd caps";
    "XF86AudioNext" = "exec playerctl next";
    "XF86AudioPause" = "exec playerctl play-pause";
    "XF86AudioPlay" = "exec playerctl play-pause";
    "XF86AudioPrev" = "exec playerctl previous";
    "Print" = "exec screenshot-region";
    "Mod4+Print" = "exec screenshot-full";
    "Mod4+q" = "kill";
    "Mod4+Escape" = "exec qs ipc call power toggle";
    "Mod4+p" = "exec qs ipc call power toggle";
    "Mod4+Shift+i" = "exec sysinfo";
    "Mod4+Shift+r" = "exec recording-toggle";
  };
}
