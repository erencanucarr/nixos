# Discord through Turkey's block. The ISP resets any TLS connection whose
# SNI names Discord (DNS answers correctly). ByeDPI splits and reorders the
# handshake so the DPI box cannot read it, as a SOCKS proxy on loopback, and
# Discord is started with that proxy. Only Discord goes through it; other
# apps connect directly.
#
# The arguments are the ones xeome/dots runs (github.com/xeome/dots,
# home/.config/systemd/user/byedpi.service), tested on this machine's ISP:
# discord.com and the gateway's WebSocket answer through it.
{ pkgs, ... }:
let
  proxy = "socks5://127.0.0.1:1080";
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
}
