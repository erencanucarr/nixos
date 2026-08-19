# Can's NixOS Configuration

Personal NixOS configuration for Lenovo ThinkPad laptops. The configuration
uses flakes, Home Manager, Sway, Stylix, SOPS and reusable local modules.

## Structure

```text
.
├── apps/                    # Application-specific NixOS modules
├── hosts/                   # Machine-specific configuration
│   ├── e16-gen3/            # Intel Lenovo ThinkPad E16 Gen 3
│   │   ├── config.nix
│   │   ├── default.nix
│   │   └── hardware/
│   │       ├── default.nix
│   │       └── filesystems.nix
│   └── e14-gen5/             # AMD Lenovo ThinkPad E14 Gen 5
│       ├── config.nix
│       ├── default.nix
│       └── hardware/
│           ├── default.nix
│           └── filesystems.nix
├── modules/                 # Reusable desktop, network and system modules
├── home.nix                 # Shared user and Home Manager configuration
├── flake.nix                # NixOS host definitions and inputs
└── flake.lock
```

Host-specific hardware must stay under `hosts/<host>/hardware`. Shared
features such as Sway, libvirt, Minikube and security belong in `modules/`.

## Current Host

The repository currently defines two hosts:

```text
e16-gen3: Lenovo ThinkPad E16 Gen 3, Intel CPU
e14-gen5: Lenovo ThinkPad E14 Gen 5, AMD CPU
```

The Intel host uses `kvm-intel`, Intel NPU support and Intel microcode updates.
The AMD host uses `kvm-amd` and AMD microcode updates. Each host has its own
filesystem UUIDs and hardware configuration.

## Apply Configuration

From this repository:

```bash
sudo nixos-rebuild switch --flake /etc/nixos#e16-gen3
```

On the AMD E14:

```bash
sudo nixos-rebuild switch --flake /etc/nixos#e14-gen5
```

Build without activating:

```bash
sudo nixos-rebuild build --flake /etc/nixos#e16-gen3
```

Inspect available hosts:

```bash
nix flake show
```

## Minikube

Minikube uses the KVM2 driver with the following defaults:

```text
CPU:    4 vCPU
Memory: 4 GB
Disk:   50 GB
Data:   /home/can/minikube/.minikube
```

Start and inspect the cluster:

```bash
minikube start
minikube status
kubectl get nodes
```

Stop it with:

```bash
minikube stop
```

The shell wrapper stops the Minikube and libvirt networks, then reports the
`libvirtd` state. Libvirt is socket-activated and does not need to run at boot.

## Adding Another Laptop

Create a new host directory, for example:

```text
hosts/e14-gen5/
├── config.nix
├── default.nix
└── hardware/
    ├── default.nix
    └── filesystems.nix
```

Generate the hardware configuration on the target machine instead of copying
the Intel host's disk and CPU settings:

```bash
sudo nixos-generate-config --show-hardware-config
```

Use `kvm-amd` and AMD microcode settings for an AMD laptop. Add the new host
to `flake.nix`, then apply it with its own flake name:

```bash
sudo nixos-rebuild switch --flake /etc/nixos#e14-gen5
```

## Secrets

Secrets are managed with SOPS. Do not add plaintext credentials, private keys
or generated machine secrets to this repository.
