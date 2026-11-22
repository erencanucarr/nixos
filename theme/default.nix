{ lib }:
let
  palette = import ./palette.nix;
  bare = c: lib.removePrefix "#" c;
  channel = c: i: toString (lib.fromHexString (builtins.substring i 2 (bare c)));
in
{
  inherit palette bare;
  colors = lib.filterAttrs (_: v: builtins.isString v) palette;
  rgba = c: a: "rgba(${channel c 0}, ${channel c 2}, ${channel c 4}, ${toString a})";
}
