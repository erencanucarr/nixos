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
│   ├── hyprland.nix          # Hyprland and its tools
│   ├── discord.nix           # Discord through the ByeDPI proxy
│   └── mouse.nix             # MX Master side button opens the app drawer
└── home/
    ├── can.nix               # user apps and the GTK look
    ├── links.nix             # links the folders below into place, editable
    ├── shell.nix             # ~/.bashrc and the prompt
    ├── shell/                # bashrc (aliases, zhelp) and starship.toml
    ├── hyprland.nix          # Hyprland and Quickshell configs
    ├── hyprland/             # hyprland.lua, lock, idle, notifications
    ├── quickshell/           # the bar, menus, app drawer, screenshots
    ├── vicinae.nix           # launcher on Super+Space, vicinae-graphite.toml its theme
    └── ghostty.nix           # terminal
```

## Thanks

Some of this comes from xeome's [dots](https://github.com/xeome/dots).
Thanks, xeome.
