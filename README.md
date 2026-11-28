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
├── theme/
│   ├── palette.nix           # every colour, in one place; the files below read it
│   └── default.nix           # helpers on top of the palette (colors, bare hex, rgba)
├── .github/workflows/        # weekly flake.lock update as a pull request
├── hosts/<host>/
│   ├── default.nix           # which modules the host uses, its ecu.* options, hostname
│   └── hardware.nix          # kernel modules and disk UUIDs
├── modules/                  # the system (NixOS)
│   ├── core/
│   │   ├── base.nix          # boot, locale, user, network, Bluetooth, nix
│   │   ├── nvidia.nix        # NVIDIA driver, CUDA, LTS kernel
│   │   ├── audio.nix         # PipeWire, realtime audio, steady USB headsets
│   │   ├── dns.nix           # encrypted DNS (DNS-over-TLS) through resolved
│   │   └── tailscale.nix     # Tailscale; "can" can control it without sudo
│   ├── desktop/
│   │   ├── desktop.nix       # ly login screen, Flea (file manager and file picker), viewers, theme, fonts
│   │   ├── hyprland.nix      # Hyprland and its tools
│   │   ├── clipboard.nix     # ecu-clip: clipboard history with cliphist (ecu.clipboard)
│   │   └── screenshot.nix    # ecu-shot: screenshots, video, GIF, OCR and QR (ecu.screenshot)
│   └── apps/
│       ├── discord.nix       # ByeDPI proxy for Discord: Equibop and Firefox (PAC) use it
│       ├── firefox.nix       # Firefox: theme, uBlock, Bitwarden, privacy settings
│       └── taildrop.nix      # ecu-taildrop: send and receive files over Tailscale (ecu.taildrop)
└── home/                     # the user (Home Manager)
    ├── can.nix               # user apps and the GTK look
    ├── links.nix             # links the folders below into place, editable
    ├── theme.nix             # writes the palette to ~/.config/ecu-theme for qs, Hyprland, GTK
    ├── shell/                # ~/.bashrc (aliases, zhelp), the prompt, ssh
    ├── desktop/
    │   ├── hyprland.nix      # links hyprland/, quickshell/ and the gtk/ folders
    │   ├── hyprland/         # hyprland.lua, lock screen, idle
    │   │   └── bin/          # helpers: sunset (night light), dpms
    │   ├── gtk/              # graphite colours for GTK 3 and 4 apps
    │   ├── wallpapers/       # wallpaper images, picked with Super+Shift+W
    │   └── quickshell/       # the shell: shell.qml starts it
    │       ├── common/       # theme, glyphs, shared cards and menus
    │       ├── bar/          # the bar; its calendar (with notes) and power menu
    │       ├── weather/      # Ankara's weather beside the clock
    │       ├── media/        # what is playing, and its controls
    │       ├── audio/        # volume/mic bar module, audio menu, per-app mixer, Arctis battery + ChatMix
    │       ├── notif/        # notifications, their history and Do Not Disturb
    │       ├── net/          # network menu: traffic, addresses, DNS, Wi-Fi, IP settings
    │       ├── tailscale/    # Tailscale: connection, devices, exit node, services
    │       ├── clip/         # clipboard history panel (Super+V); ecu-clip does the work
    │       ├── drawer/       # app drawer
    │       ├── keys/         # every shortcut, read from Hyprland (Super+K)
    │       ├── overview/     # window overview (mouse thumb button, Super+Tab)
    │       ├── session/      # full-screen power menu (Super+P)
    │       ├── wallpaper/    # the wallpaper on every screen and its picker
    │       ├── osd/          # volume and mic pop-ups, note reminders
    │       └── shot/         # screenshot UI (F8): photo, video, GIF, text (OCR), QR; ecu-shot does the work
    └── apps/
        ├── flea.nix          # Flea in graphite colours, Taildrop in its menu
        ├── vicinae/          # launcher on Super+Space and its theme
        ├── equibop/          # Equibop (Discord) theme
        ├── ghostty.nix       # terminal
        └── viewers.nix       # zathura (PDF) and imv (pictures) in graphite
```

## Options

Own modules keep their switches under `ecu.*`, set per host in `hosts/<host>/default.nix`:
`ecu.screenshot`, `ecu.taildrop` and `ecu.clipboard` (`days`, `maxItems`, `images`; the panel can override them). The Arctis 7+ ChatMix wheel and battery come from my
[arctis-chatmix.nix](https://github.com/erencanucarr/arctis-chatmix.nix) flake (`services.arctis-chatmix`), and the
Flea file manager from [flea.nix](https://github.com/erencanucarr/flea.nix) (`programs.flea`).

## Thanks

Some of this comes from xeome's [dots](https://github.com/xeome/dots).
Thanks, xeome.
