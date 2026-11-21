//@ pragma UseQApplication
//! The Hyprland shell, linked from ~/nixos/home/quickshell. Start: qs
//! Düzenle: hyprbar    Yeniden başlat: hyprbarreload
//
// A thin bar on every screen (with xeome's audio and power menus), an app
// drawer and screenshots (Shot), in xeome's graphite palette. QApplication
// rather than QGuiApplication: tray menus (QsMenuAnchor) need QtWidgets.
import Quickshell

ShellRoot {
    Variants {
        model: Quickshell.screens
        delegate: Bar {}
    }

    AppDrawer {}
    Shot {}
}
