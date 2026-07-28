import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property color bg
    required property color fg
    required property color muted
    required property color accent
    required property color line
    required property string fontFamily

    property int hideAfterMs: 1500
    property int cardWidth: 260
    property int cardHeight: 60
    property int bottomOffset: 90

    property string kind: ""
    property real value: 0
    property bool isMuted: false
    property bool capsEnabled: false
    property string icon: ""
    property bool showing: false
    property bool alive: false

    Timer {
        id: hideTimer
        interval: root.hideAfterMs
        onTriggered: root.showing = false
    }

    Timer {
        id: closeTimer
        interval: 260
        onTriggered: root.alive = false
    }

    onShowingChanged: {
        if (showing) {
            closeTimer.stop()
            alive = true
        } else if (alive) {
            closeTimer.restart()
        }
    }

    PwObjectTracker {
        objects: {
            const objects = []
            if (Pipewire.defaultAudioSink) objects.push(Pipewire.defaultAudioSink)
            if (Pipewire.defaultAudioSource) objects.push(Pipewire.defaultAudioSource)
            return objects
        }
    }

    function volumeIcon(volume, muted) {
        if (muted) return "\u{F075F}"
        if (volume > 0.66) return "\u{F057E}"
        if (volume > 0.33) return "\u{F0580}"
        if (volume > 0.001) return "\u{F057F}"
        return "\u{F075F}"
    }

    function brightnessIcon(percent) {
        if (percent > 0.66) return "\u{F00DE}"
        if (percent > 0.33) return "\u{F00DC}"
        return "\u{F00DB}"
    }

    function show(kindValue, valueValue, mutedValue, iconValue) {
        kind = kindValue
        value = Math.max(0, Math.min(1, valueValue))
        isMuted = mutedValue
        icon = iconValue
        showing = true
        hideTimer.restart()
    }

    function showVolume() {
        const sink = Pipewire.defaultAudioSink
        if (!sink || !sink.audio) return
        show("volume", sink.audio.volume, sink.audio.muted,
             volumeIcon(sink.audio.volume, sink.audio.muted))
    }

    function showMic() {
        const source = Pipewire.defaultAudioSource
        if (!source || !source.audio) return
        show("mic", 1, source.audio.muted,
             source.audio.muted ? "\u{F036D}" : "\u{F036C}")
    }

    function showCaps() {
        capsEnabled = !capsEnabled
        show("caps", capsEnabled ? 1 : 0, false, "\u{F02A2}")
    }

    Process {
        id: brightnessProcess
        command: ["sh", "-c",
            "brightnessctl -m 2>/dev/null | " +
            "awk -F, 'NR==1 {gsub(/%/,\"\",$4); print $4/100}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const percent = parseFloat(text.trim())
                if (!isNaN(percent))
                    root.show("brightness", percent, false, root.brightnessIcon(percent))
            }
        }
    }

    IpcHandler {
        target: "osd"
        function volume(): void { root.showVolume() }
        function mic(): void { root.showMic() }
        function brightness(): void { brightnessProcess.running = true }
        function caps(): void { root.showCaps() }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            WlrLayershell.namespace: "quickshell-osd"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusiveZone: 0
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            anchors { left: true; right: true; bottom: true }
            margins { bottom: root.bottomOffset }
            color: "transparent"
            implicitHeight: root.cardHeight + 8
            visible: root.alive

            Rectangle {
                anchors.centerIn: parent
                width: root.cardWidth
                height: root.cardHeight
                color: root.bg
                border { color: root.line; width: 1 }
                radius: 4
                opacity: root.showing ? 1 : 0
                scale: root.showing ? 1 : 0.92

                Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: root.icon
                        color: root.isMuted ? root.muted : root.fg
                        font { family: root.fontFamily; pixelSize: 22; weight: Font.Bold }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 6

                        Text {
                            Layout.fillWidth: true
                            text: {
                                if (root.kind === "mic") return root.isMuted ? "MIC MUTED" : "MIC ON"
                                if (root.kind === "caps") return root.capsEnabled ? "CAPS LOCK ON" : "CAPS LOCK OFF"
                                if (root.kind === "brightness") return "BRIGHTNESS  " + Math.round(root.value * 100) + "%"
                                if (root.kind === "volume") return root.isMuted ? "MUTED" : "VOLUME  " + Math.round(root.value * 100) + "%"
                                return ""
                            }
                            color: root.fg
                            font { family: root.fontFamily; pixelSize: 10; weight: Font.Bold; letterSpacing: 0.9 }
                        }

                        Item {
                            Layout.fillWidth: true
                            implicitHeight: 4

                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                height: 3
                                radius: 1.5
                                color: "#27272A"
                            }
                            Rectangle {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width * (root.isMuted ? 0 : root.value)
                                height: 3
                                radius: 1.5
                                color: root.isMuted ? root.muted : root.accent
                                Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                            }
                        }
                    }
                }
            }
        }
    }
}
