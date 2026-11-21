# Logitech MX Master 3S: the button below the thumb wheel (BTN_FORWARD)
# opens the app drawer. keyd turns the button into a tap of the left Super
# key, which Hyprland binds to the drawer (home/hyprland/hyprland.lua).
{ ... }:
{
  services.keyd = {
    enable = true;
    keyboards.mx-master = {
      # The Logitech USB receiver; m: matches only its mouse device.
      ids = [ "m:046d:c548" ];
      settings.main.mouseforward = "leftmeta";
    };
  };
}
