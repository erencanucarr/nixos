# From `nixos-generate-config` on this machine. The disk UUIDs change on
# every reinstall: take them from the new /etc/nixos/hardware-configuration.nix.
{ config, lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # The installer also lists xhci_pci_prom21, which the LTS kernel this host
  # runs (modules/nvidia.nix) does not have, so the initrd fails to build with it.
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
