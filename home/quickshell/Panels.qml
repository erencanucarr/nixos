pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// What is open. Hyprland's keys reach it over IPC:
//   qs ipc call drawer toggle    qs ipc call power toggle
Singleton {
    id: root

    property bool drawerOpen: false
    property bool powerOpen: false

    function toggleDrawer(): void {
        root.powerOpen = false;
        root.drawerOpen = !root.drawerOpen;
    }

    function togglePower(): void {
        root.drawerOpen = false;
        root.powerOpen = !root.powerOpen;
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
            root.togglePower();
        }
    }
}
