{ config, pkgs, ... }:
{
  services.openssh.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ];
  services.fprintd = {
    enable = true;
    tod = {
      enable = true;
      driver = pkgs.libfprint-2-tod1-goodix-550a;
    };
  };
  systemd.services.fprintd = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "simple";
  };
  security.pam.services = {
    "login".fprintAuth = false;
    "sddm".fprintAuth = true;
    "sddm-autologin".fprintAuth = true;
  };
}
