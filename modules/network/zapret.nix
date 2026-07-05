{ config, pkgs, ... }:

{
  services.zapret = {
    enable = true;
    params = [
      "--dpi-desync=fake --dpi-desync-ttl=3"
      "--dpi-desync=fake --dpi-desync-ttl=3"
      "--dpi-desync=fake --dpi-desync-ttl=3"
    ];
    whitelist = [
      "discord.com"
      "gateway.discord.gg"
      "cdn.discordapp.com"
      "discordapp.net"
      "googleapis.com"
      "discord-attachments-uploads-prd.storage.googleapis.com"
      "dis.gd"
      "discord.co"
      "discord.design"
      "discord.dev"
      "discord.gg"
      "discord.gift"
      "discord.gifts"
      "discord.media"
      "discord.new"
      "discord.store"
      "discord.tools"
      "discordapp.com"
      "discordmerch.com"
      "discordpartygames.com"
      "discord-activities.com"
      "discordactivities.com"
      "discordsays.com"
      "discordstatus.com"
    ];
  };
}
