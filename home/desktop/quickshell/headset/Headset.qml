pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool present: false
    property bool online: false
    property bool charging: false
    property int level: -1
    property string name: ""

    property bool mixing: false
    property int game: 100
    property int chat: 100
    readonly property real balance: root.chat < 100 ? 0.5 * root.chat / 100 : root.game < 100 ? 1 - 0.5 * root.game / 100 : 0.5

    property int viewers: 0
    property real lastQuery: 0
    property string warned: ""

    readonly property int idleInterval: 300000
    readonly property int openInterval: 30000

    function watch(on: bool): void {
        root.viewers = Math.max(0, root.viewers + (on ? 1 : -1));
        if (on && Date.now() - root.lastQuery > 5000)
            root.refresh();
    }

    function refresh(): void {
        if (query.running)
            return;
        root.lastQuery = Date.now();
        query.running = true;
    }

    function apply(text: string): void {
        let dev = null;
        try {
            dev = JSON.parse(text).devices?.[0] ?? null;
        } catch (e) {
            dev = null;
        }
        root.present = dev !== null && dev.status === "success";
        root.name = (dev?.device ?? "").replace(/^SteelSeries /, "");
        const status = dev?.battery?.status ?? "";
        root.online = status === "BATTERY_AVAILABLE" || status === "BATTERY_CHARGING";
        root.charging = status === "BATTERY_CHARGING";
        root.level = root.online ? (dev.battery.level ?? -1) : -1;
        root.checkLow();
    }

    function checkLow(): void {
        if (!root.online || root.charging || root.level < 0 || root.level > 25) {
            if (root.charging || root.level > 25)
                root.warned = "";
            return;
        }
        const step = root.level === 0 ? "empty" : "low";
        if (root.warned === step)
            return;
        root.warned = step;
        const empty = step === "empty";
        Quickshell.execDetached(["notify-send", "-a", "Kulaklık", "-i", "audio-headset", "-u", empty ? "critical" : "normal", empty ? `${root.name} pili bitmek üzere` : `${root.name} pili azaldı`, empty ? "Şarja takmazsan birazdan kapanacak." : `Pil %${root.level}, şarja takmayı unutma.`]);
    }

    FileView {
        id: mixFile

        path: `${Quickshell.env("XDG_RUNTIME_DIR")}/arctis-chatmix`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            const [g, c] = text().trim().split(" ").map(Number);
            root.mixing = !isNaN(g) && !isNaN(c);
            if (root.mixing) {
                root.game = g;
                root.chat = c;
            }
        }
        onLoadFailed: root.mixing = false
    }

    Timer {
        interval: 30000
        running: !root.mixing
        repeat: true
        onTriggered: mixFile.reload()
    }

    Process {
        id: query

        command: ["headsetcontrol", "-b", "-o", "json"]
        stdout: StdioCollector {
            onStreamFinished: root.apply(this.text)
        }
    }

    Timer {
        interval: root.viewers > 0 ? root.openInterval : root.idleInterval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
