//@ pragma UseQApplication
//! The Hyprland shell, linked from ~/nixos/home/quickshell. Start: qs
//! Düzenle: hyprbar    Yeniden başlat: hyprbarreload
//
// A thin bar on every screen, an app drawer and a power menu, in xeome's
// graphite palette. QApplication rather than QGuiApplication: tray menus
// (QsMenuAnchor) need QtWidgets.
import Quickshell

ShellRoot {
    Variants {
        model: Quickshell.screens
        delegate: Bar {}
    }

    AppDrawer {}
    PowerMenu {}
}
