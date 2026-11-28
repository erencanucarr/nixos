{
  config,
  lib,
  osConfig,
  theme,
  ...
}:
let
  c = theme.colors;
  home = config.home.homeDirectory;
  ansi = lib.listToAttrs (
    lib.imap0 (i: v: lib.nameValuePair "color${toString i}" v) theme.palette.ansi
  );
in
{
  programs.flea = {
    enable = true;

    theme.colors = {
      accent = c.warm;
      selection = c.selRaised;
      muted = c.dim;
      background = c.panel;
      dark_background = c.ground;
      darker_background = c.ground;
      lighter_background = c.raised;
      foreground = c.text;
      dark_foreground = c.dim;
      light_foreground = c.text;
      bright_foreground = c.bright;
      red = c.hot;
      orange = c.hot;
      yellow = c.warm;
      inherit (c)
        green
        cyan
        blue
        magenta
        ;
      cursor = c.text;
      selection_foreground = c.bright;
      selection_background = c.selRaised;
    }
    // ansi;

    settings.places.favourites =
      map
        (n: {
          label = n;
          path = "${home}/${n}";
        })
        [
          "Downloads"
          "Documents"
          "Pictures"
          "Videos"
          "Music"
          "Projects"
        ]
      ++ lib.optional osConfig.ecu.taildrop.enable {
        label = "Taildrop";
        path = "${home}/Downloads/${osConfig.ecu.taildrop.folder}";
      }
      ++ lib.optionals osConfig.ecu.screenshot.enable [
        {
          label = osConfig.ecu.screenshot.folders.pictures;
          path = "${home}/Pictures/${osConfig.ecu.screenshot.folders.pictures}";
        }
        {
          label = osConfig.ecu.screenshot.folders.videos;
          path = "${home}/Videos/${osConfig.ecu.screenshot.folders.videos}";
        }
      ];

    actions = lib.mkIf osConfig.ecu.taildrop.enable {
      taildrop = {
        name = "Tailscale ile gönder";
        mime = [ "*" ];
        selection = "one";
        run = [
          "/run/current-system/sw/bin/ecu-taildrop"
          "pick"
          "{path}"
        ];
        mode = "background";
      };
    };
  };
}
