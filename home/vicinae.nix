# Vicinae: a Spotlight/Raycast-style launcher. Super+Space opens it
# (apps, files, calculator, emoji, clipboard history).
# The server runs in the background so the window opens instantly.
{ config, lib, pkgs, ... }:
{
  home.packages = [ pkgs.vicinae ];

  # Graphite, xeome's near-monochrome palette (see the file's header).
  xdg.dataFile."vicinae/themes/graphite.toml".source = ./vicinae-graphite.toml;

  # The managed half of the config. settings.json is vicinae's own file, which
  # its settings window rewrites, so it only gets an import of this one.
  xdg.configFile."vicinae/nix.json".text = builtins.toJSON {
    theme.dark.name = "graphite";
  };
  home.activation.vicinaeImport = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    f="${config.xdg.configHome}/vicinae/settings.json"
    if [ ! -s "$f" ]; then
      run mkdir -p "$(dirname "$f")"
      run printf '{\n   "imports": ["nix.json"]\n}\n' > "$f"
    elif ! grep -q '"nix.json"' "$f"; then
      if grep -q '"imports"[[:space:]]*:[[:space:]]*\[[[:space:]]*\]' "$f"; then
        run sed -i 's/"imports"[[:space:]]*:[[:space:]]*\[[[:space:]]*\]/"imports": ["nix.json"]/' "$f"
      elif grep -q '"imports"[[:space:]]*:[[:space:]]*\[' "$f"; then
        run sed -i '0,/"imports"[[:space:]]*:[[:space:]]*\[/s/\("imports"[[:space:]]*:[[:space:]]*\[\)/\1"nix.json", /' "$f"
      else
        run sed -i '0,/^[[:space:]]*{/s/^\([[:space:]]*{\)/\1\n   "imports": ["nix.json"],/' "$f"
      fi
    fi
  '';

  systemd.user.services.vicinae = {
    Unit = {
      Description = "Vicinae launcher server";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.vicinae}/bin/vicinae server --replace";
      Restart = "always";
      RestartSec = 5;
      KillMode = "process";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  dconf.settings = {
    # Super+Space belongs to the launcher, as Cmd+Space does on macOS.
    # GNOME uses it to switch keyboard layouts; there is only one (tr).
    "org/gnome/desktop/wm/keybindings" = {
      switch-input-source = [ ];
      switch-input-source-backward = [ ];
    };
    "org/gnome/settings-daemon/plugins/media-keys".custom-keybindings = [
      "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/vicinae/"
    ];
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/vicinae" = {
      name = "Vicinae";
      command = "${pkgs.vicinae}/bin/vicinae toggle";
      binding = "<Super>space";
    };
  };
}
