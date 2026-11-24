import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import qs.common
import qs.headset

Menu {
    id: root

    readonly property int fs: 14
    readonly property int wt: 550

    Component.onCompleted: Headset.watch(true)
    Component.onDestruction: Headset.watch(false)

    contentWidth: 324
    rowSpacing: 8

    required property var recorders

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    readonly property var sinks: Pipewire.nodes.values.filter(n => !n.isStream && (n.type & PwNodeType.AudioSink) === PwNodeType.AudioSink)
    readonly property var sources: Pipewire.nodes.values.filter(n => !n.isStream && (n.type & PwNodeType.AudioSource) === PwNodeType.AudioSource)

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var headsets: root.adapter ? Bluetooth.devices.values.filter(d => d.paired && d.icon.startsWith("audio")).sort((a, b) => b.connected - a.connected) : []

    function btLabel(d: var): string {
        return d.deviceName || d.name || d.address;
    }

    function btDetail(d: var): string {
        if (d.state === BluetoothDeviceState.Connecting || d.state === BluetoothDeviceState.Disconnecting)
            return "···";
        if (d.connected && d.batteryAvailable)
            return `${Glyph.battery} ${Math.round(d.battery * 100)}%`;
        return d.connected ? "bağlı" : "";
    }

    function appName(n: var): string {
        return n.properties["application.name"] || n.description || n.name;
    }

    onVisibleChanged: if (!visible) {
        out.expanded = false;
        mic.expanded = false;
    }

    PwObjectTracker {
        objects: [root.sink, root.source].concat(root.recorders)
    }

    component Device: ColumnLayout {
        id: dev

        required property var node
        required property string glyph
        required property string label
        required property var devices
        signal picked(var node)

        readonly property var audio: dev.node?.audio ?? null
        readonly property bool muted: dev.audio?.muted ?? false
        readonly property real volume: dev.audio?.volume ?? 0
        readonly property bool selectable: dev.devices.length > 1
        property bool expanded: false

        Layout.fillWidth: true
        spacing: 2
        visible: !!dev.node

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            BarText {
                Layout.preferredWidth: 24
                horizontalAlignment: Text.AlignHCenter
                text: dev.glyph
                font.pixelSize: root.fs + 5
                color: dev.muted ? Theme.dim : Theme.text

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (dev.audio)
                        dev.audio.muted = !dev.muted
                }
            }

            BarText {
                Layout.fillWidth: true
                text: dev.label
                font.pixelSize: root.fs
                weight: root.wt
                color: dev.muted ? Theme.dim : Theme.text
            }

            BarText {
                text: dev.muted ? "sessiz" : `${Math.round(dev.volume * 100)}%`
                font.pixelSize: root.fs
                weight: root.wt
                color: dev.muted ? Theme.dim : Theme.text
            }
        }

        Track {
            thickness: 8
            value: dev.muted ? 0 : dev.volume
            onMoved: fraction => {
                if (!dev.audio)
                    return;
                dev.audio.muted = false;
                dev.audio.volume = fraction;
            }
        }

        Pick {
            Layout.topMargin: 4
            implicitHeight: 30
            textSize: root.fs - 2
            weight: root.wt
            label: dev.node?.description ?? ""
            suffix: dev.selectable ? (dev.expanded ? Glyph.chevronUp : Glyph.chevronDown) : ""
            selectable: dev.selectable
            onClicked: dev.expanded = !dev.expanded
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            visible: dev.expanded

            Repeater {
                model: dev.devices

                delegate: Pick {
                    required property var modelData

                    implicitHeight: 30
                    textSize: root.fs - 2
                    weight: root.wt
                    label: modelData.description || modelData.name
                    current: dev.node?.id === modelData.id
                    onClicked: {
                        dev.picked(modelData);
                        dev.expanded = false;
                    }
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.bottomMargin: -2

        Item {
            Layout.fillWidth: true
        }

        BarText {
            readonly property int count: Pipewire.nodes.values.filter(n => n.isStream && n.type === PwNodeType.AudioOutStream).length

            text: count > 0 ? `Uygulamalar ${count} ${Glyph.chevronRight}` : `Uygulamalar ${Glyph.chevronRight}`
            font.pixelSize: root.fs - 2
            weight: root.wt
            color: appsMa.containsMouse ? Theme.bright : Theme.dim

            MouseArea {
                id: appsMa
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Panels.popup = `audio-apps@${root.screenName}`
            }
        }
    }

    Device {
        id: out

        node: root.sink
        label: "Çıkış"
        devices: root.sinks
        glyph: out.muted ? Glyph.volOff : out.volume > 0.66 ? Glyph.volHigh : out.volume > 0.33 ? Glyph.volMid : Glyph.volLow
        onPicked: node => Pipewire.preferredDefaultAudioSink = node
    }

    Rule {}

    Device {
        id: mic

        node: root.source
        label: "Giriş"
        devices: root.sources
        glyph: mic.muted ? Glyph.micOff : Glyph.mic
        onPicked: node => Pipewire.preferredDefaultAudioSource = node
    }

    Rule {
        visible: bt.visible
    }

    Rectangle {
        id: headset

        readonly property color tone: Headset.charging ? Theme.green : Headset.level >= 0 && Headset.level <= 25 ? Theme.hot : Theme.text
        readonly property string batteryGlyph: {
            if (Headset.charging)
                return String.fromCodePoint(0xF0084);
            const l = Headset.level;
            return String.fromCodePoint(l <= 0 ? 0xF008E : l <= 25 ? 0xF007B : l <= 50 ? 0xF007E : l <= 75 ? 0xF0080 : 0xF0079);
        }

        Layout.fillWidth: true
        visible: Headset.present
        implicitHeight: 34
        radius: Theme.radius
        color: headsetMa.containsMouse ? Theme.hoverRaised : "transparent"
        border.width: 1
        border.color: Theme.edge

        RowLayout {
            anchors {
                fill: parent
                leftMargin: 10
                rightMargin: 10
            }
            spacing: 8

            BarText {
                text: String.fromCodePoint(0xF02CE)
                font.pixelSize: root.fs + 1
                color: Headset.online ? Theme.bright : Theme.dim
            }

            BarText {
                Layout.fillWidth: true
                text: Headset.name || "Kulaklık"
                elide: Text.ElideRight
                font.pixelSize: root.fs - 2
                weight: root.wt
                color: Headset.online ? Theme.bright : Theme.text
            }

            BarText {
                visible: Headset.online
                text: headset.batteryGlyph
                font.pixelSize: root.fs + 1
                color: headset.tone
            }

            BarText {
                text: !Headset.online ? "kapalı" : Headset.charging ? `şarj oluyor  ${Headset.level}%` : `${Headset.level}%`
                font.pixelSize: root.fs - 2
                weight: root.wt
                color: Headset.online ? headset.tone : Theme.dim
            }
        }

        MouseArea {
            id: headsetMa
            anchors.fill: parent
            hoverEnabled: true
            onClicked: Headset.refresh()
        }
    }

    Item {
        id: mix

        Layout.fillWidth: true
        visible: Headset.present && Headset.mixing
        implicitHeight: 38

        BarText {
            id: gameLabel
            anchors.left: parent.left
            anchors.leftMargin: 2
            anchors.top: parent.top
            text: `Oyun  ${Headset.game}%`
            font.pixelSize: root.fs - 4
            weight: root.wt
            color: Headset.balance <= 0.5 ? Theme.text : Theme.dim
        }

        BarText {
            anchors.right: parent.right
            anchors.rightMargin: 2
            anchors.top: parent.top
            text: `${Headset.chat}%  Sohbet`
            font.pixelSize: root.fs - 4
            weight: root.wt
            color: Headset.balance >= 0.5 ? Theme.text : Theme.dim
        }

        Item {
            id: track

            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                leftMargin: 7
                rightMargin: 7
                bottomMargin: 6
            }
            height: 4

            Rectangle {
                anchors.fill: parent
                radius: 2
                color: Theme.edge
            }

            Rectangle {
                x: Math.min(track.width / 2, knob.x + knob.width / 2)
                width: Math.abs(knob.x + knob.width / 2 - track.width / 2)
                height: parent.height
                radius: 2
                color: Theme.blue
                opacity: 0.6
            }

            Rectangle {
                x: track.width / 2 - 1
                y: -3
                width: 2
                height: 10
                radius: 1
                color: Theme.dim
                opacity: 0.6
            }

            Rectangle {
                id: knob

                x: Headset.balance * track.width - width / 2
                anchors.verticalCenter: parent.verticalCenter
                width: 12
                height: 12
                radius: 6
                color: Theme.bright
                border.width: 2
                border.color: Theme.raised

                Behavior on x {
                    NumberAnimation {
                        duration: Theme.anim
                        easing.type: Theme.ease
                    }
                }
            }
        }
    }

    ColumnLayout {
        id: bt

        Layout.fillWidth: true
        spacing: 2
        visible: !!root.adapter

        Pick {
            implicitHeight: 30
            textSize: root.fs - 2
            weight: root.wt
            label: "Bluetooth"
            suffix: root.adapter?.enabled ? "açık" : "kapalı"
            current: root.adapter?.enabled ?? false
            onClicked: root.adapter.enabled = !root.adapter.enabled
        }

        Repeater {
            model: root.headsets

            delegate: Pick {
                required property var modelData

                implicitHeight: 30
                textSize: root.fs - 2
                weight: root.wt
                label: root.btLabel(modelData)
                suffix: root.btDetail(modelData)
                current: modelData.connected
                onClicked: if (modelData.connected)
                    modelData.disconnect();
                else
                    modelData.connect()
            }
        }
    }

    Rule {}

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        BarText {
            text: `${root.recorders.length > 0 ? Glyph.mic : Glyph.micOff}  ${root.recorders.length > 0 ? "Mikrofonu kullanan" : "Mikrofon kullanılmıyor"}`
            font.pixelSize: root.fs - 2
            weight: root.wt
            color: root.recorders.length > 0 ? Theme.text : Theme.dim
        }

        Repeater {
            model: root.recorders

            delegate: BarText {
                required property var modelData

                Layout.fillWidth: true
                Layout.leftMargin: 22
                text: root.appName(modelData)
                elide: Text.ElideRight
                font.pixelSize: root.fs - 3
                weight: root.wt
                color: Theme.dim
            }
        }
    }
}
