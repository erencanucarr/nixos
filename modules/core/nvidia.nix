{ config, pkgs, ... }:
{
  boot.kernelPackages = pkgs.linuxPackages;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    powerManagement.enable = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  environment.sessionVariables.LIBVA_DRIVER_NAME = "nvidia";

  environment.systemPackages = with pkgs; [
    cudaPackages.cudatoolkit
    nvtopPackages.nvidia
    libva-utils
  ];
  programs.nix-ld = {
    enable = true;
    libraries = [ config.hardware.nvidia.package ];
  };
}
