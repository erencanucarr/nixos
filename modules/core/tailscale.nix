_: {
  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "client";
    extraSetFlags = [
      "--operator=can"
      "--exit-node="
    ];
  };
}
