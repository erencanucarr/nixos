{
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;

    extraConfig.pipewire."92-min-quantum"."context.properties" = {
      "default.clock.min-quantum" = 512;
    };

    wireplumber.extraConfig."51-usb-audio"."monitor.alsa.rules" = [
      {
        matches = [
          { "node.name" = "~alsa_output.usb-.*"; }
          { "node.name" = "~alsa_input.usb-.*"; }
        ];
        actions.update-props = {
          "session.suspend-timeout-seconds" = 0;
          "api.alsa.headroom" = 1024;
        };
      }
    ];
  };
}
