{ config, pkgs, ... }:
{
  sops = {
    age.keyFile = "${config.users.users.can.home}/.config/sops/age/keys.txt";
    defaultSopsFile = ./secrets.yaml;
    defaultSopsFormat = "yaml";
  };
}
