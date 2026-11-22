{ lib, ... }:
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      srv = {
        HostName = "100.100.1.4";
        User = "root";
      };
      "*" = lib.hm.dag.entryAfter [ "srv" ] {
        AddKeysToAgent = "no";
        ServerAliveInterval = 30;
        ServerAliveCountMax = 3;
      };
    };
  };
}
