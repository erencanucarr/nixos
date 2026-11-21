# NixOS configuration

Flake-based NixOS configuration with Home Manager.

## Hosts

| Host            | Machine                                             |
| --------------- | --------------------------------------------------- |
| `b850e-desktop` | Ryzen 7 7800X3D, RTX 3060, LUKS-encrypted ext4 root |

## Layout

```text
.
├── flake.nix                 # inputs and hosts
├── hosts/<host>/
│   ├── default.nix           # which modules the host uses, its hostname
│   └── hardware.nix          # kernel modules and disk UUIDs
├── modules/
│   ├── base.nix              # boot, locale, user, network, nix
│   ├── nvidia.nix            # NVIDIA driver, CUDA, LTS kernel
│   ├── gnome.nix             # GNOME, WhiteSur theme, extensions, fonts
│   ├── discord.nix           # Discord through the ByeDPI proxy
│   └── mouse.nix             # MX Master side button opens the overview
├── pkgs/whitesur.nix         # the WhiteSur build both GNOME and Home Manager use
├── home/can.nix              # GNOME settings (dconf) and GTK 4 theme files
├── home/vicinae.nix          # Spotlight-style launcher on Super+Space
├── home/ghostty.nix          # Ghostty terminal, graphite and Caffeine colours
├── home/shell.nix            # links ~/.bashrc and the prompt to home/shell/
└── home/shell/               # bashrc (aliases, zhelp) and starship.toml
```

## Desktop

GNOME on Wayland with a macOS look:

- **Theme:** WhiteSur GTK and GNOME Shell theme, icons and cursors, dark.
  libadwaita apps get it through `~/.config/gtk-4.0`.
- **Dock:** Dash to Dock at the bottom, hiding when a window covers it, with
  the app grid button first.
- **Panels:** Blur my Shell blurs the top bar, the overview and the dock.
- **Windows:** close, minimise and maximise on the left; new windows centred.
- **Tray:** AppIndicator support for tray icons.

The settings are written to dconf on every switch. A change made in GNOME's
own settings lasts until the next switch; to keep it, set it in
`home/can.nix`.

## NVIDIA and CUDA

The host runs the LTS kernel with NVIDIA's open kernel modules. CUDA comes as
`cudaPackages.cudatoolkit` (`nvcc` and the CUDA libraries); `libcuda` comes
with the driver. `nix-ld` lets prebuilt binaries such as PyTorch wheels from
pip find the driver. `cudaSupport` is not turned on nixpkgs-wide, since that
builds many packages from source.

```bash
nvidia-smi
nvcc --version
```

## Discord

Discord is blocked in Turkey by DPI: DNS answers correctly, but the ISP resets
any TLS connection whose SNI names Discord. `modules/discord.nix` runs ByeDPI
as a SOCKS proxy on `127.0.0.1:1080` and starts Discord with
`--proxy-server` pointing at it. Firefox gets a proxy auto-config file that
sends Discord's domains, and only those, through the same proxy. Everything
else connects directly.

If Discord stops connecting, check the proxy first:

```bash
systemctl status byedpi
curl -sS -o /dev/null -w "%{http_code}\n" --socks5-hostname 127.0.0.1:1080 https://discord.com
```

## Apply

The system is built from this repository only. `/etc/nixos/configuration.nix`
is left over from the installer and is not read: add packages here instead
(`home/can.nix` for your own apps, `modules/base.nix` for system tools).

```bash
sudo nixos-rebuild switch --flake .#b850e-desktop
```

Build without activating:

```bash
nixos-rebuild build --flake .#b850e-desktop
```

## Reinstalling a host

The disk UUIDs change with every install. Copy them from the new
`/etc/nixos/hardware-configuration.nix` into `hosts/<host>/hardware.nix`
before the first switch, or the machine will not boot.
