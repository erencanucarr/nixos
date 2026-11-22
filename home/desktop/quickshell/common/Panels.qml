pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Singleton {
    id: root

    property bool drawerOpen: false
    property string drawerScreen: ""
    property bool overviewOpen: false
    property bool sessionOpen: false
    property bool wallsOpen: false
    property bool keysOpen: false
    property string keysScreen: ""
    property string wallsScreen: ""
    property string popup: ""

    property int awakeSpan: -1
    property double awakeUntil: 0
    property double now: 0
    readonly property bool awake: awakeSpan >= 0

    function toggleDrawer(): void {
        root.keysOpen = false;
        root.wallsOpen = false;
        root.popup = "";
        root.overviewOpen = false;
        root.drawerScreen = root.focusedScreen();
        root.sessionOpen = false;
        root.drawerOpen = !root.drawerOpen;
    }

    function togglePopup(key: string, screen: string): void {
        root.keysOpen = false;
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

    function toggleKeys(): void {
        root.popup = "";
        root.drawerOpen = false;
        root.overviewOpen = false;
        root.sessionOpen = false;
        root.wallsOpen = false;
        root.keysScreen = root.focusedScreen();
        root.keysOpen = !root.keysOpen;
    }

    function toggleWalls(): void {
        root.keysOpen = false;
        root.popup = "";
        root.drawerOpen = false;
        root.overviewOpen = false;
        root.sessionOpen = false;
        root.wallsScreen = root.focusedScreen();
        root.wallsOpen = !root.wallsOpen;
    }

    function toggleSession(): void {
        root.keysOpen = false;
        root.wallsOpen = false;
        root.popup = "";
        root.drawerOpen = false;
        root.overviewOpen = false;
        root.sessionOpen = !root.sessionOpen;
    }

    function toggleOverview(): void {
        root.keysOpen = false;
        root.wallsOpen = false;
        root.popup = "";
        root.drawerOpen = false;
        root.sessionOpen = false;
        root.overviewOpen = !root.overviewOpen;
    }

    IpcHandler {
        target: "keys"

        function toggle(): void {
            root.toggleKeys();
        }
        function close(): void {
            root.keysOpen = false;
        }
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
        target: "media"

        function toggle(): void {
            root.togglePopup("media", root.focusedScreen());
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
