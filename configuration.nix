{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./modules/security
    ./modules/desktop
    ./modules/network
    ./apps
  ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.kernelPackages = pkgs.linuxPackages_latest;
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
  services.xserver.xkb = {
    layout = "tr";
    variant = "";
  };
  console.keyMap = "trq";
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };
  services.blueman.enable = true;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;
  services.udev.extraRules = ''
    SUBSYSTEM=="leds", KERNEL=="tpacpi::kbd_backlight", ACTION=="add", RUN+="${pkgs.coreutils}/bin/chmod 666 /sys/class/leds/tpacpi::kbd_backlight/brightness"
    ACTION=="add", SUBSYSTEM=="sound", KERNEL=="controlC1", RUN+="${pkgs.writeShellScript "micmute-led-wrapper" ''
      exec ${pkgs.systemd}/bin/systemd-run --no-block --unit=micmute-led-setup ${pkgs.writeShellScript "micmute-led-setup" ''
        ${pkgs.kmod}/bin/modprobe snd_ctl_led
        ${pkgs.alsa-utils}/bin/alsactl init 1 || true
        echo 'Mic ACP LED Capture Switch' | ${pkgs.coreutils}/bin/tee /sys/class/sound/ctl-led/mic/card1/attach 2>/dev/null || true
      ''}
    ''}"
  '';
  users.users."can" = {
    isNormalUser = true;
    description = "Can";
    extraGroups = [ "networkmanager" "wheel" ];
  };
  programs.firefox = {
    enable = true;
    preferencesStatus = "default";
    preferences = {
      "font.name.serif.x-western" = "DejaVu Serif";
      "font.name.sans-serif.x-western" = "DejaVu Sans";
      "font.name.monospace.x-western" = "JetBrainsMono Nerd Font";
      "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
    };
  };
  nixpkgs.config.allowUnfree = true;
  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
    };
  };
  environment.systemPackages = with pkgs; [
    wget
    curl
    btop
    dig
    git
    pkgs.opencode
    fzf
    tree
    unzip
    age
    sops
    usbutils
    openfortivpn
  ];
  system.stateVersion = "26.05";
}
