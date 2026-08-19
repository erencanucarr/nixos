{ ... }:
{
  fileSystems."/" = {
    device = "/dev/mapper/luks-869e2888-5c61-42bd-a15d-716b9b1a3548";
    fsType = "ext4";
  };

  boot.initrd.luks.devices."luks-869e2888-5c61-42bd-a15d-716b9b1a3548".device =
    "/dev/disk/by-uuid/869e2888-5c61-42bd-a15d-716b9b1a3548";

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/B315-BE83";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [ ];
}
