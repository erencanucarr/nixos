# Sound: PipeWire, which also serves PulseAudio and ALSA apps.
#
# GNOME used to switch on rtkit, which lets PipeWire's audio thread run in
# realtime; it went with GNOME, and without it the thread waits behind any
# busy process and the sound crackles. The rest keeps USB headsets (the
# Arctis 7+, the QuadCast) steady.
{
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;

    # Apps asking for very low latency (Discord, games) can drop the period
    # to 32 samples, short enough to underrun; 512 is ~11 ms at 48 kHz.
    extraConfig.pipewire."92-min-quantum"."context.properties" = {
      "default.clock.min-quantum" = 512;
    };

    # USB audio: keep the device open instead of suspending it after 5 s
    # idle (a pop or a garbled start when sound comes back), and keep a
    # buffer of headroom against the USB clock drifting from PipeWire's.
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
