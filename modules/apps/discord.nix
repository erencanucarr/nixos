# Discord through Turkey's block. The ISP resets any TLS connection whose
# SNI names Discord (DNS answers correctly). ByeDPI splits and reorders the
# handshake so the DPI box cannot read it, as a SOCKS proxy on loopback.
# The Discord app is started with that proxy, and Firefox sends Discord's
# domains, and only those, through it. Everything else connects directly.
#
# The arguments are the ones xeome/dots runs (github.com/xeome/dots,
# home/.config/systemd/user/byedpi.service), tested on this machine's ISP:
# discord.com and the gateway's WebSocket answer through it.
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

  # Each domain and its subdomains go to the proxy; nothing else does.
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
      # ciadpi listens on every interface by default.
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
    (pkgs.discord.override { commandLineArgs = "--proxy-server=${proxy}"; })
  ];

  # Not locked, so Firefox's own network settings can still override it.
  programs.firefox.policies.Proxy = {
    Mode = "autoConfig";
    AutoConfigURL = "file://${pac}";
    Locked = false;
  };
}
