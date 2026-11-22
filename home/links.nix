{ config, lib, ... }:
let
  home = config.home.homeDirectory;
  repo = "${home}/nixos/home";
in
{
  options.repoLinks = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = { };
    description = "Path under $HOME -> path under ~/nixos/home to link it to.";
  };

  config.home.activation.repoLinks = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    lib.concatStrings (lib.mapAttrsToList (target: source: ''
      t="${home}/${target}"
      if [ "$(readlink "$t")" != "${repo}/${source}" ]; then
        if [ -e "$t" ] && [ ! -L "$t" ]; then run mv "$t" "$t.bak"; fi
        run mkdir -p "$(dirname "$t")"
        run ln -sfn "${repo}/${source}" "$t"
      fi
    '') config.repoLinks)
  );
}
