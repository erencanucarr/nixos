{ ... }:
{
  fileSystems."/" = {
    device = "/dev/mapper/cryptroot";
    fsType = "ext4";
  };

  boot.initrd.luks.devices."cryptroot".device =
    "/dev/disk/by-uuid/f24fd0f8-d2d8-4b82-8a78-40e3dec6e681";

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/F045-8C3E";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };

  swapDevices = [ { device = "/swapfile"; } ];
}
