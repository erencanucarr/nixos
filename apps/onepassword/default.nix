{ pkgs, ... }:

{
  programs = {
    _1password.enable = true;
    _1password-gui = {
      enable = true;
      package =
        with pkgs;
        _1password-gui.overrideAttrs (
          {
            buildInputs ? [ ],
            postFixup ? "",
            ...
          }:
          {
            buildInputs = buildInputs ++ [
              makeWrapper
            ];
          }
        );
    };
  };
  environment.etc."1password/custom_allowed_browsers" = {
    text = ''
      librewolf
      firefox
    '';
    mode = "0755";
  };
}
