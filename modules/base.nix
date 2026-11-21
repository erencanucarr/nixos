# What every host shares: boot, locale, the user, networking, nix itself.
{ pkgs, unstable, ... }:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "Europe/Istanbul";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "tr_TR.UTF-8";
    LC_IDENTIFICATION = "tr_TR.UTF-8";
    LC_MEASUREMENT = "tr_TR.UTF-8";
    LC_MONETARY = "tr_TR.UTF-8";
    LC_NAME = "tr_TR.UTF-8";
    LC_NUMERIC = "tr_TR.UTF-8";
    LC_PAPER = "tr_TR.UTF-8";
    LC_TELEPHONE = "tr_TR.UTF-8";
    LC_TIME = "tr_TR.UTF-8";
  };
  services.xserver.xkb.layout = "tr";
  console.keyMap = "trq";

  users.users.can = {
    isNormalUser = true;
    description = "Can";
    extraGroups = [ "networkmanager" "wheel" "video" ];
    # The MacBook's key for this machine, so SSH survives a reinstall.
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEsarS+DLcG9flUUe2RIgAp8uKQlKxsmgtGFMW0pE6Iq claude-mac-to-b850e"
    ];
  };

  networking.networkmanager.enable = true;
  # The firewall stays on; the openssh module opens port 22 itself.
  networking.firewall.enable = true;
  services.openssh.enable = true;

  hardware.bluetooth.enable = true;
  services.fwupd.enable = true;

  programs.firefox.enable = true;

  nixpkgs.config.allowUnfree = true;
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  environment.systemPackages = with pkgs; [
    git
    wget
    curl
    btop
    fastfetch
    pciutils
    usbutils
    unzip
    unstable.claude-code
  ];
}
