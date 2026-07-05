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
    "login".fprintAuth = true;
    "sddm".fprintAuth = true;
    "sddm-autologin".fprintAuth = true;
  };
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "net.reactivated.fprint.device.enroll" &&
          subject.user == "can") {
        return polkit.Result.YES;
      }
    });
  '';
}
