//@ pragma UseQApplication
//! The Hyprland shell, linked from ~/nixos/home/desktop/quickshell. Start: qs
//! Düzenle: hyprbar    Yeniden başlat: hyprbarreload
//
// A thin bar on every screen (with xeome's audio and power menus), an app
// drawer and screenshots (Shot), in xeome's graphite palette. QApplication
// rather than QGuiApplication: tray menus (QsMenuAnchor) need QtWidgets.
import Quickshell
import qs.bar
import qs.drawer
import qs.osd
import qs.shot

ShellRoot {
    Variants {
        model: Quickshell.screens
        delegate: Bar {}
    }

    AppDrawer {}
    Osd {}
    Shot {}
}
