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
├── theme/palette.nix         # every colour, in one place; the files below read it
├── .github/workflows/        # weekly flake.lock update as a pull request
├── hosts/<host>/
│   ├── default.nix           # which modules the host uses, its hostname
│   └── hardware.nix          # kernel modules and disk UUIDs
├── modules/                  # the system (NixOS)
│   ├── core/
│   │   ├── base.nix          # boot, locale, user, network, nix
│   │   ├── nvidia.nix        # NVIDIA driver, CUDA, LTS kernel
│   │   ├── audio.nix         # PipeWire, realtime audio, steady USB headsets
│   │   └── dns.nix           # encrypted DNS (DNS-over-TLS) through resolved
│   ├── desktop/
│   │   ├── desktop.nix       # ly login screen, Thunar and viewers, theme, fonts
│   │   └── hyprland.nix      # Hyprland and its tools
│   └── apps/
│       ├── discord.nix       # Discord through the ByeDPI proxy
│       └── firefox.nix       # Firefox: theme, uBlock, Bitwarden, privacy settings
└── home/                     # the user (Home Manager)
    ├── can.nix               # user apps and the GTK look
    ├── links.nix             # links the folders below into place, editable
    ├── theme.nix             # writes the palette to ~/.config/can-theme for qs, Hyprland, GTK
    ├── shell/                # ~/.bashrc (aliases, zhelp) and the prompt
    ├── desktop/
    │   ├── hyprland.nix      # links hyprland/ and quickshell/
    │   ├── hyprland/         # hyprland.lua, lock screen, idle
    │   ├── gtk/              # graphite colours for GTK 3 and 4 apps (Thunar…)
    │   ├── wallpapers/       # wallpaper images, picked with Super+Shift+W
    │   └── quickshell/       # the shell: shell.qml starts it
    │       ├── common/       # theme, glyphs, shared cards and menus
    │       ├── bar/          # the bar; its calendar (with notes), audio and power menus
    │       ├── weather/      # Ankara's weather beside the clock
    │       ├── media/        # what is playing, and its controls
    │       ├── notif/        # notifications, their history and Do Not Disturb
    │       ├── net/          # network menu: traffic, addresses, DNS, Wi-Fi, IP settings
    │       ├── drawer/       # app drawer
    │       ├── keys/         # every shortcut, read from Hyprland (Super+K)
    │       ├── overview/     # window overview (mouse thumb button, Super+Tab)
    │       ├── session/      # full-screen power menu (Super+P)
    │       ├── wallpaper/    # the wallpaper on every screen and its picker
    │       ├── osd/          # volume and mic pop-ups
    │       └── shot/         # screenshots, their editor, video and GIF recording
    └── apps/
        ├── vicinae/          # launcher on Super+Space and its theme
        ├── ghostty.nix       # terminal
        └── viewers.nix       # zathura (PDF) and imv (pictures) in graphite
```

## Thanks

Some of this comes from xeome's [dots](https://github.com/xeome/dots).
Thanks, xeome.
