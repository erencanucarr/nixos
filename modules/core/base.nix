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
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
    ];
  };

  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

  hardware.bluetooth.enable = true;
  services.fwupd.enable = true;

  nixpkgs.config.allowUnfree = true;
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
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
    gh
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
