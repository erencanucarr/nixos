{ ... }:
let
  cloudflare = "1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com 2606:4700:4700::1111#cloudflare-dns.com";
  quad9 = "9.9.9.9#dns.quad9.net 149.112.112.112#dns.quad9.net";
in
{
  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNS = cloudflare;
      FallbackDNS = quad9;
      DNSOverTLS = "true";
      Domains = "~.";
    };
  };
}
