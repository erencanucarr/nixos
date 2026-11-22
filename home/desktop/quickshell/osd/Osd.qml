import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import qs.common

PanelWindow {
    id: root

    property string icon: ""
    property real value: 0
    property string label: ""
    property bool alert: false

    property real lastVolume: -1
    property bool lastMuted: false
    property int lastCaps: -1

    readonly property int drift: 6

    function flash(icon: string, value: real, label: string, alert: bool): void {
        root.icon = icon;
        root.value = value;
        root.label = label;
        root.alert = alert;
        root.visible = true;
        hide.restart();
    }

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
    WlrLayershell.namespace: "can-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    anchors.bottom: true
    margins.bottom: 120 - drift
    implicitWidth: 300
    implicitHeight: 52 + drift
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: false
    mask: Region {}

    onVisibleChanged: if (visible)
        enter.restart()

    Timer {
        id: hide
        interval: 1500
        onTriggered: root.visible = false
    }

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    Connections {
        target: root.sink?.audio ?? null

        function onVolumeChanged(): void {
            root.flashVolume();
        }

        function onMutedChanged(): void {
            root.flashVolume();
        }
    }

    function flashVolume(): void {
        const a = root.sink?.audio;
        if (!a)
            return;

        const changed = root.lastVolume >= 0 && (Math.abs(a.volume - root.lastVolume) > 0.001 || a.muted !== root.lastMuted);
        root.lastVolume = a.volume;
        root.lastMuted = a.muted;
        if (!changed)
            return;

        const pct = Math.round(a.volume * 100);
        root.flash(a.muted ? Glyph.volOff : pct > 66 ? Glyph.volHigh : pct > 33 ? Glyph.volMid : Glyph.volLow, a.muted ? 0 : a.volume, "", false);
    }

    property bool micReady: false

    onSourceChanged: root.micReady = false

    Timer {
        interval: 500
        running: root.source !== null && !root.micReady
        onTriggered: root.micReady = true
    }

    Connections {
        target: root.source?.audio ?? null

        function onMutedChanged(): void {
            if (!root.micReady)
                return;

            const muted = root.source.audio.muted;
            root.flash(muted ? Glyph.micOff : Glyph.mic, 0, muted ? "Mikrofon kapalı" : "Mikrofon açık", muted);
        }
    }

    readonly property string capsDir: caps.count > 0 ? caps.get(0, "filePath") : ""

    FolderListModel {
        id: caps

        folder: "file:///sys/class/leds"
        nameFilters: ["*capslock"]
        showFiles: false
        showDotAndDotDot: false
    }

    FileView {
        path: root.capsDir ? root.capsDir + "/brightness" : ""
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const on = parseInt(text()) > 0 ? 1 : 0;
            const changed = root.lastCaps >= 0 && on !== root.lastCaps;
            root.lastCaps = on;
            if (changed)
                root.flash("⇪", 0, on ? "Büyük harf açık" : "Büyük harf kapalı", false);
        }
    }

    Surface {
        width: parent.width
        height: parent.height - root.drift

        NumberAnimation on y {
            id: enter
            from: root.drift
            to: 0
            duration: Theme.anim
            easing.type: Theme.ease
            running: false
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 14

            BarText {
                text: root.icon
                color: root.alert ? Theme.hot : Theme.text
                font.pixelSize: 20
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 6
                visible: root.label === ""
                radius: height / 2
                color: Theme.rule

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, root.value))
                    height: parent.height
                    radius: height / 2
                    color: Theme.text

                    Behavior on width {
                        NumberAnimation {
                            duration: 120
                        }
                    }
                }
            }

            BarText {
                Layout.fillWidth: true
                visible: root.label !== ""
                text: root.label
                color: root.alert ? Theme.hot : Theme.text
            }

            BarText {
                visible: root.label === ""
                text: `${Math.round(root.value * 100)}%`
            }
        }
    }
}
