{ config, pkgs, lib, ... }: {
  wayland.windowManager.sway.config.keybindings = lib.mkOptionDefault {
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
    "Print" = "exec grim -g \"$(slurp)\" - | swappy -f -";
    "Mod4+Print" = "exec grim - | swappy -f -";
    "Mod4+q" = "kill";
    "Mod4+Escape" = "exec powermenu";
  };
}
