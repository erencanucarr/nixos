# Logitech MX Master 3S: the button below the thumb wheel (BTN_FORWARD)
# opens the GNOME overview. GNOME on Wayland cannot bind mouse buttons, so
# keyd turns the button into a tap of the left Super key.
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
