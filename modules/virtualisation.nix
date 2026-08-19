{ pkgs, lib, ... }:
let
  libvirtdConfig = pkgs.writeText "libvirtd.conf" ''
    auth_unix_ro = "polkit"
    auth_unix_rw = "polkit"
    namespaces = []
  '';
in
{
  virtualisation.libvirtd = {
    enable = true;
    onBoot = "ignore";
    onShutdown = "shutdown";
    qemu = {
      swtpm.enable = true;
    };
  };
  systemd.services.libvirtd.serviceConfig.Environment = lib.mkForce [
    "LIBVIRTD_ARGS=\"--config ${libvirtdConfig} --timeout 10\""
  ];
  systemd.services.libvirtd.wantedBy = lib.mkForce [ ];
  systemd.services.libvirt-guests.wantedBy = lib.mkForce [ ];
  programs.virt-manager.enable = true;
  environment.systemPackages = with pkgs; [
    libvirt
    virt-manager
    minikube
    kubectl
    kubernetes-helm
  ];
  users.users.can.extraGroups = [
    "libvirtd"
    "kvm"
    "i2c"
  ];
}
