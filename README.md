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
│   ├── desktop.nix           # login screen, GNOME apps, theme, fonts
│   ├── discord.nix           # Discord through the ByeDPI proxy
│   ├── mouse.nix             # MX Master side button opens the overview
│   └── hyprland.nix          # Hyprland and its tools
├── home/can.nix              # user apps and the GTK look (dconf)
├── home/vicinae.nix          # Spotlight-style launcher on Super+Space
├── home/ghostty.nix          # Ghostty terminal, graphite and Caffeine colours
├── home/links.nix            # links files below into place, editable
├── home/shell.nix            # ~/.bashrc and the prompt, from home/shell/
├── home/shell/               # bashrc (aliases, zhelp) and starship.toml
├── home/hyprland.nix         # Hyprland and Quickshell configs, linked
├── home/hyprland/            # hyprland.lua, lock, idle, notifications
└── home/quickshell/          # the bar, app drawer and power menu
```

## Desktop

Hyprland on Wayland in the graphite palette from
[xeome/dots](https://github.com/xeome/dots), logged into from GDM:

- **Windows:** tiled, with a 1px translucent edge, brighter on the focused
  window, and the others dimmed a little. Config: `home/hyprland/hyprland.lua`.
- **Bar:** Quickshell, 30px, one per screen: the app drawer button and that
  screen's workspaces, the clock, the tray, volume and power.
- **App drawer:** Super alone, the mouse's side button or the bar's button.
- **Launcher:** Vicinae on Super+Space.
- **Lock and idle:** hyprlock, locked after 15 minutes, screens off after 20.
- **Notifications:** mako.
- **Theme:** dark libadwaita, adw-gtk3 for GTK 3 apps, WhiteSur icons and
  cursors, Inter and JetBrains Mono.

The Hyprland and Quickshell files are linked from this repo rather than
copied into the store, so an edit applies with `hyprreload` or
`hyprbarreload`, without a rebuild. `zhelp hypr` lists the keys.

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

## Thanks

Some of this comes from xeome's [dots](https://github.com/xeome/dots).
Thanks, xeome.
