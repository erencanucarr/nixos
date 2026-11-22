//@ pragma UseQApplication
//! The Hyprland shell, linked from ~/nixos/home/desktop/quickshell. Start: qs
//! Düzenle: hyprbar    Yeniden başlat: hyprbarreload
//
// A thin bar on every screen (with xeome's audio and power menus), an app
// drawer, a window overview and screenshots (Shot), in xeome's graphite
// palette. QApplication rather than QGuiApplication: tray menus
// (QsMenuAnchor) need QtWidgets.
import Quickshell
import qs.bar
import qs.common
import qs.drawer
import qs.osd
import qs.overview
import qs.session
import qs.shot
import qs.wallpaper

ShellRoot {
    Wallpaper {}

    Variants {
        model: Quickshell.screens
        delegate: Bar {}
    }

    // Closes a menu or the drawer on a click on another screen.
    Variants {
        model: Quickshell.screens
        delegate: Catcher {}
    }

    // Built while open, freed when closed: they take no memory meanwhile.
    LazyLoader {
        active: Panels.drawerOpen

        AppDrawer {}
    }

    LazyLoader {
        active: Panels.overviewOpen

        Overview {}
    }

    LazyLoader {
        active: Panels.sessionOpen

        Session {}
    }

    LazyLoader {
        active: Panels.wallsOpen

        Picker {}
    }

    // Calendar notes that are due (Notes.qml).
    LazyLoader {
        active: Notes.due.length > 0

        Reminder {}
    }

    Osd {}
    Shot {}
}
