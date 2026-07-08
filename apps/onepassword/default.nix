{ config, pkgs, ... }:
let
  user = config.users.users.can;
in
{
  programs = {
    _1password.enable = true;
    _1password-gui = {
      enable = true;
      package = with pkgs;
        _1password-gui.overrideAttrs (
          {
            buildInputs ? [ ],
            postFixup ? "",
            ...
          }:
          {
            buildInputs = buildInputs ++ [ makeWrapper ];
          }
        );
    };
    ssh.startAgent = true;
  };
  environment.etc."1password/custom_allowed_browsers" = {
    text = ''
      librewolf
      firefox
    '';
    mode = "0755";
  };
  environment.sessionVariables = {
    SSH_AUTH_SOCK = "${user.home}/.1password/agent.sock";
  };
  programs.ssh.extraConfig = ''
    IdentityAgent ${user.home}/.1password/agent.sock
  '';
}
