{ lib, pkgs, ... }:
let
  proxy = "socks5://127.0.0.1:1080";

  domains = [
    "discord.com"
    "discord.gg"
    "discord.gift"
    "discord.media"
    "discord.new"
    "discord.dev"
    "discordapp.com"
    "discordapp.net"
    "discordcdn.com"
    "discordstatus.com"
    "dis.gd"
  ];

  pac = pkgs.writeText "discord.pac" ''
    function FindProxyForURL(url, host) {
      var domains = ${builtins.toJSON domains};
      for (var i = 0; i < domains.length; i++) {
        if (host === domains[i] || dnsDomainIs(host, "." + domains[i])) {
          return "SOCKS5 127.0.0.1:1080";
        }
      }
      return "DIRECT";
    }
  '';
in
{
  services.byedpi = {
    enable = true;
    extraArgs = [
      "--ip" "127.0.0.1"
      "--port" "1080"
      "--split" "1"
      "--disorder" "3+s"
      "--mod-http=h,d"
      "--auto=torst"
      "--tlsrec" "1+s"
    ];
  };

  environment.systemPackages = [
    (pkgs.symlinkJoin {
      name = "equibop";
      paths = [ pkgs.equibop ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/equibop --add-flags "--proxy-server=${proxy}" --set PULSE_SINK arctis_chat
      '';
    })
  ];

  programs.firefox.policies.Proxy = {
    Mode = "autoConfig";
    AutoConfigURL = "file://${pac}";
    Locked = false;
  };
}
