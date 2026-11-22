{ config, lib, pkgs, ... }:
{
  home.packages = [ pkgs.vicinae ];

  xdg.dataFile."vicinae/themes/graphite.toml".source = ./graphite.toml;

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
}
