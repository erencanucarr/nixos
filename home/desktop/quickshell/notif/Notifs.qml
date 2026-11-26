pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs.common

Singleton {
    id: root

    property bool dnd: false
    property var popups: []

    readonly property var history: [...server.trackedNotifications.values].reverse()

    readonly property var stamps: new Map()

    function setDnd(on: bool): void {
        root.dnd = on;
        dndFile.setText(on ? "1\n" : "0\n");
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    function age(n: var): string {
        const at = root.stamps.get(n.id);
        if (at === undefined)
            return "";
        const mins = Math.floor((clock.date.getTime() - at) / 60000);
        if (mins < 1)
            return "şimdi";
        if (mins < 60)
            return `${mins} dk`;
        if (mins < 1440)
            return `${Math.floor(mins / 60)} sa`;
        return `${Math.floor(mins / 1440)} gün`;
    }

    function timeout(n: var): int {
        if (n.expireTimeout >= 0)
            return n.expireTimeout;
        if (n.urgency === NotificationUrgency.Critical)
            return 0;
        return n.urgency === NotificationUrgency.Low ? 5000 : 8000;
    }

    function drop(n: var): void {
        root.popups = root.popups.filter(p => p !== n);
    }

    function dismissApp(app: string): void {
        for (const n of root.history)
            if (n.appName === app)
                n.dismiss();
        root.popups = root.popups.filter(p => p.appName !== app);
    }

    function clearAll(): void {
        for (const n of root.history)
            n.dismiss();
        root.popups = [];
        root.stamps.clear();
    }

    NotificationServer {
        id: server

        keepOnReload: true
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: n => {
            const id = n.id;
            const at = Date.now();
            root.stamps.set(id, at);
            n.closed.connect(() => {
                if (root.stamps.get(id) === at)
                    root.stamps.delete(id);
            });
            n.tracked = true;
            if (!root.dnd || n.urgency === NotificationUrgency.Critical)
                root.popups = [n, ...root.popups];
        }
    }

    FileView {
        id: dndFile

        path: `${Quickshell.env("HOME")}/.local/state/ecu-dnd`
        printErrors: false
        onLoaded: root.dnd = text().trim() === "1"
    }

    IpcHandler {
        target: "notifs"

        function toggle(): void {
            Panels.togglePopup("notifs", Panels.focusedScreen());
        }
        function dnd(): bool {
            root.setDnd(!root.dnd);
            return root.dnd;
        }
        function clear(): void {
            root.clearAll();
        }
    }
}
