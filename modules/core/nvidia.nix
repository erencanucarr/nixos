# NVIDIA RTX 3060 (Ampere) on the open kernel modules, with CUDA.
{ config, pkgs, ... }:
{
  # The LTS kernel: NVIDIA's modules lag behind the newest kernels, and a
  # driver that fails to build leaves the machine without a desktop.
  boot.kernelPackages = pkgs.linuxPackages;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    # Saves video memory across suspend, so the desktop comes back without a
    # black or corrupted screen.
    powerManagement.enable = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Video decoding through NVDEC for Firefox and other VA-API apps.
  environment.sessionVariables.LIBVA_DRIVER_NAME = "nvidia";

  # CUDA. The toolkit gives nvcc and the CUDA libraries; libcuda itself comes
  # with the driver under /run/opengl-driver/lib. nix-ld lets prebuilt
  # binaries, such as PyTorch wheels from pip, find the driver and a libc.
  # cudaSupport is not set nixpkgs-wide: that rebuilds many packages from source.
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
