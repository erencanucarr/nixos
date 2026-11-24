//@ pragma UseQApplication
import Quickshell
import qs.bar
import qs.common
import qs.headset
import qs.drawer
import qs.keys
import qs.notif
import qs.osd
import qs.overview
import qs.session
import qs.shot
import qs.wallpaper

ShellRoot {
    readonly property bool headsetPresent: Headset.present

    Wallpaper {}

    Variants {
        model: Quickshell.screens
        delegate: Bar {}
    }

    Variants {
        model: Quickshell.screens
        delegate: Catcher {}
    }

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
        active: Panels.keysOpen

        Keys {}
    }

    LazyLoader {
        active: Panels.wallsOpen

        Picker {}
    }

    LazyLoader {
        active: Notifs.popups.length > 0

        NotifPopups {}
    }

    LazyLoader {
        active: Notes.due.length > 0

        Reminder {}
    }

    Osd {}
    Shot {}
}
