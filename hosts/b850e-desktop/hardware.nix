{ config, lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "nvme" "ahci" "xhci_pci" "usb_storage" "usbhid" "sd_mod" ];
  boot.kernelModules = [ "kvm-amd" ];

  fileSystems."/" = {
    device = "/dev/mapper/luks-8dcffbdb-ba4f-4434-a016-be6df4f66595";
    fsType = "ext4";
  };

  boot.initrd.luks.devices."luks-8dcffbdb-ba4f-4434-a016-be6df4f66595".device =
    "/dev/disk/by-uuid/8dcffbdb-ba4f-4434-a016-be6df4f66595";

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/3108-3169";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
