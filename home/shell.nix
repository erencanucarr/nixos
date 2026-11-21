# The shell setup: ~/.bashrc (aliases, zhelp) and the starship prompt.
# The files live in this repo and are linked, not copied into the store, so
# they stay editable (zedit, zprompt) and a change works without a rebuild.
{ config, lib, ... }:
let
  repo = "${config.home.homeDirectory}/nixos/home/shell";
  links = {
    ".bashrc" = "bashrc";
    ".config/starship.toml" = "starship.toml";
  };
in
{
  home.activation.shellLinks = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    lib.concatStrings (lib.mapAttrsToList (target: source: ''
      t="${config.home.homeDirectory}/${target}"
      if [ "$(readlink "$t")" != "${repo}/${source}" ]; then
        if [ -e "$t" ] && [ ! -L "$t" ]; then run mv "$t" "$t.bak"; fi
        run mkdir -p "$(dirname "$t")"
        run ln -sfn "${repo}/${source}" "$t"
      fi
    '') links)
  );
}
