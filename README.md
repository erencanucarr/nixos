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
├── modules/                  # the system (NixOS)
│   ├── core/
│   │   ├── base.nix          # boot, locale, user, network, nix
│   │   └── nvidia.nix        # NVIDIA driver, CUDA, LTS kernel
│   ├── desktop/
│   │   ├── desktop.nix       # login screen, GNOME apps, theme, fonts
│   │   ├── hyprland.nix      # Hyprland and its tools
│   │   └── mouse.nix         # MX Master side button opens the app drawer
│   └── apps/
│       └── discord.nix       # Discord through the ByeDPI proxy
└── home/                     # the user (Home Manager)
    ├── can.nix               # user apps and the GTK look
    ├── links.nix             # links the folders below into place, editable
    ├── shell/                # ~/.bashrc (aliases, zhelp) and the prompt
    ├── desktop/
    │   ├── hyprland.nix      # links hyprland/ and quickshell/
    │   ├── hyprland/         # hyprland.lua, lock, idle, notifications
    │   └── quickshell/       # the shell: shell.qml starts it
    │       ├── common/       # theme, glyphs, shared cards and menus
    │       ├── bar/          # the bar and its audio and power menus
    │       ├── weather/      # Ankara's weather beside the clock
    │       ├── drawer/       # app drawer
    │       ├── osd/          # volume and mic pop-ups
    │       └── shot/         # screenshots and their editor
    └── apps/
        ├── vicinae/          # launcher on Super+Space and its theme
        └── ghostty.nix       # terminal
```

## Thanks

Some of this comes from xeome's [dots](https://github.com/xeome/dots).
Thanks, xeome.
