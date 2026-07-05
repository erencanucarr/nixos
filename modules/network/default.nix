{
  imports = [
    ./zapret.nix
  ];

  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];
  };

  services.resolved = {
    enable = true;
    settings = {
      Resolve = {
        DNS = [
          "9.9.9.9#dns.quad9.net"
          "149.112.112.112#dns.quad9.net"
        ];
        DNSOverTLS = "true";
        DNSSEC = "true";
        Domains = [ "~." ];
        FallbackDNS = [
          "9.9.9.9#dns.quad9.net"
          "149.112.112.112#dns.quad9.net"
        ];
      };
    };
  };
}
