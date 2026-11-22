{ ... }:
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      srv = {
        hostname = "100.100.1.4";
        user = "root";
      };
      "*" = {
        addKeysToAgent = "no";
        serverAliveInterval = 30;
        serverAliveCountMax = 3;
      };
    };
  };
}
