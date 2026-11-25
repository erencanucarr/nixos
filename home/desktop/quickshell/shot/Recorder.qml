pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string kind: ""
    property string stamp: ""
    property bool audio: true
    property var target: []
    property bool recording: false
    property bool saving: false
    property int countdown: 0
    property int elapsed: 0
    property rect area

    readonly property bool busy: recording || saving || countdown > 0 || wait.running

    signal saved(string file, string thumb, string kind, int seconds, rect area)

    function clock(s: int): string {
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }

    function start(kind: string, target: var, delay: int, audio: bool, area: rect): void {
        if (root.busy)
            return;
        root.kind = kind;
        root.target = target;
        root.audio = audio;
        root.area = area;
        root.elapsed = 0;
        root.countdown = delay;
        if (delay > 0)
            tick.start();
        else
            wait.start();
    }

    function stop(): void {
        if (root.countdown > 0 || wait.running) {
            tick.stop();
            wait.stop();
            root.countdown = 0;
        } else if (root.recording) {
            rec.signal(2);
        }
    }

    function begin(): void {
        root.stamp = Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss");
        rec.exec(["ecu-shot", "record", root.kind, root.stamp, root.audio ? "1" : "0", ...root.target]);
        root.recording = true;
    }

    Timer {
        id: wait

        interval: 250
        onTriggered: root.begin()
    }

    Timer {
        id: tick

        interval: 1000
        repeat: true
        onTriggered: {
            root.countdown -= 1;
            if (root.countdown <= 0) {
                tick.stop();
                root.begin();
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.recording
        onTriggered: root.elapsed += 1
    }

    Process {
        id: rec

        onExited: {
            root.recording = false;
            root.saving = true;
            save.exec(["ecu-shot", "finish", root.kind, root.stamp]);
        }
    }

    Process {
        id: save

        stdout: StdioCollector {
            onStreamFinished: {
                root.saving = false;
                const [file, thumb] = text.split("\n");
                if (file)
                    root.saved(file, thumb ?? "", root.kind, root.elapsed, root.area);
                else
                    Quickshell.execDetached(["ecu-shot", "notify", "Ekran kaydı", "Kayıt kaydedilemedi"]);
            }
        }
    }
}
