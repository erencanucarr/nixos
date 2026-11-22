pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// What is open, and the idle inhibitor. Hyprland's keys reach it over IPC:
//   qs ipc call drawer toggle    qs ipc call power toggle
//   qs ipc call audio toggle     qs ipc call weather toggle
//   qs ipc call net toggle       qs ipc call overview toggle
//   qs ipc call session toggle   qs ipc call calendar toggle
//   qs ipc call walls toggle
// The bar popups (Power, AudioMenu) open on the focused monitor's bar.
Singleton {
    id: root

    property bool drawerOpen: false
    // The screen the drawer opened on, for Catcher.
    property string drawerScreen: ""
    property bool overviewOpen: false
    property bool sessionOpen: false
    // The wallpaper picker, and the screen it opened on.
    property bool wallsOpen: false
    property string wallsScreen: ""
    // The open bar popup as "<key>@<screen>" (Popup.qml), or "".
    property string popup: ""

    // Idle inhibitor, after xeome's Idle.qml: -1 off, 0 until turned off,
    // otherwise the minutes picked. Bar's IdleInhibitor follows `awake`, and
    // hypridle honours it, so neither the lock nor the screens-off timeout
    // fires while it is on.
    property int awakeSpan: -1
    // Epoch ms the inhibit lapses at; 0 while off or indefinite.
    property double awakeUntil: 0
    // The clock the countdown reads: a binding cannot depend on Date.now().
    property double now: 0
    readonly property bool awake: awakeSpan >= 0

    function toggleDrawer(): void {
        root.wallsOpen = false;
        root.popup = "";
        root.overviewOpen = false;
        root.drawerScreen = root.focusedScreen();
        root.sessionOpen = false;
        root.drawerOpen = !root.drawerOpen;
    }

    function togglePopup(key: string, screen: string): void {
        root.wallsOpen = false;
        const id = `${key}@${screen}`;
        root.drawerOpen = false;
        root.overviewOpen = false;
        root.sessionOpen = false;
        root.popup = root.popup === id ? "" : id;
    }

    function focusedScreen(): string {
        return Hyprland.focusedMonitor?.name ?? Quickshell.screens[0]?.name ?? "";
    }

    // Re-picking the running duration turns it off.
    function setAwake(minutes: int): void {
        if (minutes === root.awakeSpan) {
            root.awakeSpan = -1;
            root.awakeUntil = 0;
            return;
        }
        root.awakeSpan = minutes;
        root.now = Date.now();
        root.awakeUntil = minutes > 0 ? root.now + minutes * 60000 : 0;
    }

    // "1sa 23dk" is too wide for a row suffix; "1:23" and "42 dk" are not.
    function awakeLeft(): string {
        const m = Math.ceil(Math.max(0, root.awakeUntil - root.now) / 60000);
        return m >= 60 ? `${Math.floor(m / 60)}:${String(m % 60).padStart(2, "0")}` : `${m} dk`;
    }

    Timer {
        running: root.awakeUntil > 0
        interval: 1000
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            root.now = Date.now();
            if (root.now >= root.awakeUntil)
                root.setAwake(-1);
        }
    }

    function toggleWalls(): void {
        root.popup = "";
        root.drawerOpen = false;
        root.overviewOpen = false;
        root.sessionOpen = false;
        root.wallsScreen = root.focusedScreen();
        root.wallsOpen = !root.wallsOpen;
    }

    function toggleSession(): void {
        root.wallsOpen = false;
        root.popup = "";
        root.drawerOpen = false;
        root.overviewOpen = false;
        root.sessionOpen = !root.sessionOpen;
    }

    function toggleOverview(): void {
        root.wallsOpen = false;
        root.popup = "";
        root.drawerOpen = false;
        root.sessionOpen = false;
        root.overviewOpen = !root.overviewOpen;
    }

    IpcHandler {
        target: "walls"

        function toggle(): void {
            root.toggleWalls();
        }
        function close(): void {
            root.wallsOpen = false;
        }
    }

    IpcHandler {
        target: "session"

        function toggle(): void {
            root.toggleSession();
        }
        function close(): void {
            root.sessionOpen = false;
        }
    }

    IpcHandler {
        target: "overview"

        function toggle(): void {
            root.toggleOverview();
        }
        function close(): void {
            root.overviewOpen = false;
        }
    }

    IpcHandler {
        target: "drawer"

        function toggle(): void {
            root.toggleDrawer();
        }
        function close(): void {
            root.drawerOpen = false;
        }
    }

    IpcHandler {
        target: "power"

        function toggle(): void {
            root.togglePopup("power", root.focusedScreen());
        }
        function close(): void {
            root.popup = "";
        }
    }

    IpcHandler {
        target: "net"

        function toggle(): void {
            root.togglePopup("net", root.focusedScreen());
        }
        function close(): void {
            root.popup = "";
        }
    }

    IpcHandler {
        target: "calendar"

        function toggle(): void {
            root.togglePopup("calendar", root.focusedScreen());
        }
        function close(): void {
            root.popup = "";
        }
    }

    IpcHandler {
        target: "weather"

        function toggle(): void {
            root.togglePopup("weather", root.focusedScreen());
        }
        function close(): void {
            root.popup = "";
        }
    }

    IpcHandler {
        target: "audio"

        function toggle(): void {
            root.togglePopup("audio", root.focusedScreen());
        }
        function apps(): void {
            root.togglePopup("audio-apps", root.focusedScreen());
        }
        function close(): void {
            root.popup = "";
        }
    }
}
