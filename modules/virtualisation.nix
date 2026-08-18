{ pkgs, ... }:
{
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      swtpm.enable = true;
    };
  };
  programs.virt-manager.enable = true;
  environment.systemPackages = with pkgs; [
    libvirt
    virt-manager
  ];
  users.users.can.extraGroups = [
    "libvirtd"
    "kvm"
  ];
}
