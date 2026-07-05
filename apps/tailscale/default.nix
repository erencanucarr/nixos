{
  ...
}:

{
  services.tailscale = {
    enable = true;
    extraSetFlags = [
      "--accept-dns"
      "--accept-routes"
      "--ssh"
    ];
  };
}
