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

    contentWidth: 344
    rowSpacing: 8

    required property var recorders

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    readonly property var sinks: Pipewire.nodes.values.filter(n => !n.isStream && (n.type & PwNodeType.AudioSink) === PwNodeType.AudioSink)
    readonly property var sources: Pipewire.nodes.values.filter(n => !n.isStream && (n.type & PwNodeType.AudioSource) === PwNodeType.AudioSource)
    readonly property int streams: Pipewire.nodes.values.filter(n => n.isStream && n.type === PwNodeType.AudioOutStream).length

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var headsets: root.adapter ? Bluetooth.devices.values.filter(d => d.paired && d.icon.startsWith("audio")).sort((a, b) => b.connected - a.connected) : []

    function btLabel(d: var): string {
        return d.deviceName || d.name || d.address;
    }

    function btDetail(d: var): string {
        if (d.state === BluetoothDeviceState.Connecting || d.state === BluetoothDeviceState.Disconnecting)
            return "···";
        if (d.connected && d.batteryAvailable)
            return `${Math.round(d.battery * 100)}%`;
        return d.connected ? "bağlı" : "bağlan";
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

    component Slider: Item {
        id: slider

        property real value: 0
        property bool dim: false
        signal moved(real fraction)

        function report(f: real): void {
            slider.moved(Math.max(0, Math.min(1, f)));
        }

        Layout.fillWidth: true
        implicitHeight: 18

        Rectangle {
            id: groove
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: 6
                rightMargin: 6
                verticalCenter: parent.verticalCenter
            }
            height: 4
            radius: 2
            color: Theme.rule

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, slider.value))
                height: parent.height
                radius: 2
                color: slider.dim ? Theme.dim : sliderMa.containsMouse || sliderMa.pressed ? Theme.bright : Theme.text
            }
        }

        Rectangle {
            x: groove.x + groove.width * Math.max(0, Math.min(1, slider.value)) - width / 2
            anchors.verticalCenter: parent.verticalCenter
            width: sliderMa.containsMouse || sliderMa.pressed ? 14 : 10
            height: width
            radius: width / 2
            color: slider.dim ? Theme.dim : Theme.bright
            border.width: 3
            border.color: Theme.raised

            Behavior on width {
                NumberAnimation {
                    duration: Theme.anim
                    easing.type: Theme.ease
                }
            }
        }

        MouseArea {
            id: sliderMa
            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: e => slider.report((e.x - 4 - groove.x) / groove.width)
            onPositionChanged: e => {
                if (pressed)
                    slider.report((e.x - 4 - groove.x) / groove.width);
            }
            onWheel: e => slider.report(slider.value + (e.angleDelta.y > 0 ? 0.05 : -0.05))
        }
    }

    component Channel: Card {
        id: dev

        required property var node
        required property string glyph
        required property string caption
        property bool appsButton: false
        required property var devices
        signal picked(var node)

        readonly property var audio: dev.node?.audio ?? null
        readonly property bool muted: dev.audio?.muted ?? false
        readonly property real volume: dev.audio?.volume ?? 0
        readonly property bool selectable: dev.devices.length > 1
        property bool expanded: false

        visible: !!dev.node

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Tile {
                glyph: dev.glyph
                lit: !dev.muted
                tone: dev.muted ? Theme.hot : Theme.bright
                clickable: true
                onClicked: if (dev.audio)
                    dev.audio.muted = !dev.muted
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                RowLayout {
                    spacing: 8

                    Caption {
                        text: dev.caption
                    }

                    Rectangle {
                        visible: dev.appsButton
                        implicitWidth: appsRow.implicitWidth + 12
                        implicitHeight: 16
                        radius: 8
                        color: appsMa.containsMouse ? Theme.selRaised : Theme.hoverRaised
                        border.width: 1
                        border.color: Theme.edge

                        Row {
                            id: appsRow
                            anchors.centerIn: parent
                            spacing: 4

                            BarText {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Glyph.apps
                                font.pixelSize: 10
                                color: appsMa.containsMouse ? Theme.bright : Theme.dim
                            }

                            BarText {
                                visible: root.streams > 0
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.streams
                                font.pixelSize: 9
                                weight: 650
                                color: appsMa.containsMouse ? Theme.bright : Theme.text
                            }
                        }

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

                Item {
                    Layout.fillWidth: true
                    implicitHeight: name.implicitHeight

                    BarText {
                        id: name
                        anchors.left: parent.left
                        width: Math.min(implicitWidth, parent.width - (chevron.visible ? chevron.width + 6 : 0))
                        text: dev.node?.description ?? ""
                        elide: Text.ElideRight
                        font.pixelSize: root.fs - 1
                        weight: 600
                        color: nameMa.containsMouse ? Theme.bright : Theme.text
                    }

                    BarText {
                        id: chevron
                        visible: dev.selectable
                        anchors.left: name.right
                        anchors.leftMargin: 6
                        anchors.verticalCenter: name.verticalCenter
                        text: dev.expanded ? Glyph.chevronUp : Glyph.chevronDown
                        font.pixelSize: root.fs - 2
                        color: Theme.dim
                    }

                    MouseArea {
                        id: nameMa
                        anchors.fill: parent
                        hoverEnabled: dev.selectable
                        enabled: dev.selectable
                        cursorShape: Qt.PointingHandCursor
                        onClicked: dev.expanded = !dev.expanded
                    }
                }
            }

            BarText {
                Layout.alignment: Qt.AlignBottom
                text: dev.muted ? "sessiz" : Math.round(dev.volume * 100)
                font.pixelSize: dev.muted ? root.fs - 1 : 24
                weight: dev.muted ? 600 : 300
                color: dev.muted ? Theme.hot : Theme.bright
            }
        }

        Slider {
            value: dev.muted ? 0 : dev.volume
            dim: dev.muted
            onMoved: fraction => {
                if (!dev.audio)
                    return;
                dev.audio.muted = false;
                dev.audio.volume = fraction;
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: dev.expanded
            spacing: 2

            Rule {}

            Repeater {
                model: dev.devices

                delegate: Rectangle {
                    id: option

                    required property var modelData
                    readonly property bool current: dev.node?.id === modelData.id

                    Layout.fillWidth: true
                    implicitHeight: 30
                    radius: Theme.radius
                    color: optionMa.containsMouse ? Theme.hoverRaised : "transparent"

                    Rectangle {
                        id: dot
                        anchors.left: parent.left
                        anchors.leftMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        width: 12
                        height: 12
                        radius: 6
                        color: "transparent"
                        border.width: option.current ? 4 : 1.5
                        border.color: option.current ? Theme.bright : Theme.edge
                    }

                    BarText {
                        anchors.left: dot.right
                        anchors.leftMargin: 10
                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        text: option.modelData.description || option.modelData.name
                        elide: Text.ElideRight
                        font.pixelSize: root.fs - 2
                        weight: option.current ? 600 : root.wt
                        color: option.current ? Theme.bright : Theme.text
                    }

                    MouseArea {
                        id: optionMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            dev.picked(option.modelData);
                            dev.expanded = false;
                        }
                    }
                }
            }
        }
    }

    Channel {
        id: out

        node: root.sink
        caption: "ÇIKIŞ"
        appsButton: true
        devices: root.sinks
        glyph: out.muted ? Glyph.volOff : out.volume > 0.66 ? Glyph.volHigh : out.volume > 0.33 ? Glyph.volMid : Glyph.volLow
        onPicked: node => Pipewire.preferredDefaultAudioSink = node
    }

    Channel {
        id: mic

        node: root.source
        caption: "GİRİŞ"
        devices: root.sources
        glyph: mic.muted ? Glyph.micOff : Glyph.mic
        onPicked: node => Pipewire.preferredDefaultAudioSource = node
    }

    Card {
        id: headset

        readonly property color tone: !Headset.online ? Theme.dim : Headset.charging ? Theme.green : Headset.level <= 25 ? Theme.hot : Theme.bright
        readonly property int cells: Headset.online ? Math.round(Math.max(0, Headset.level) / 25) : 0

        visible: Headset.present

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Tile {
                glyph: String.fromCodePoint(0xF02CE)
                lit: Headset.online
                tone: Headset.online ? Theme.bright : Theme.dim
                clickable: true
                onClicked: Headset.refresh()
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Caption {
                    text: "KULAKLIK"
                }

                BarText {
                    Layout.fillWidth: true
                    text: Headset.name || "Kulaklık"
                    elide: Text.ElideRight
                    font.pixelSize: root.fs - 1
                    weight: 600
                    color: Headset.online ? Theme.text : Theme.dim
                }
            }

            ColumnLayout {
                spacing: 4

                Row {
                    Layout.alignment: Qt.AlignRight
                    spacing: 2

                    Rectangle {
                        width: 38
                        height: 18
                        radius: 4
                        color: "transparent"
                        border.width: 1.5
                        border.color: Qt.alpha(headset.tone, 0.7)

                        Row {
                            anchors.fill: parent
                            anchors.margins: 3
                            spacing: 2

                            Repeater {
                                model: 4

                                Rectangle {
                                    required property int index

                                    width: (parent.width - 6) / 4
                                    height: parent.height
                                    radius: 1.5
                                    color: index < headset.cells ? headset.tone : Theme.rule
                                }
                            }
                        }

                        BarText {
                            visible: Headset.charging
                            anchors.centerIn: parent
                            text: String.fromCodePoint(0xF140B)
                            font.pixelSize: 13
                            color: Theme.ground
                            style: Text.Outline
                            styleColor: Theme.green
                        }
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 3
                        height: 7
                        radius: 1
                        color: Qt.alpha(headset.tone, 0.7)
                    }
                }

                BarText {
                    Layout.alignment: Qt.AlignRight
                    text: !Headset.online ? "kapalı" : Headset.charging ? `şarjda · ${Headset.level}%` : `${Headset.level}%`
                    font.pixelSize: root.fs - 4
                    weight: 600
                    color: headset.tone
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: Headset.mixing && Headset.online
            spacing: 8

            Rule {}

            RowLayout {
                Layout.fillWidth: true

                BarText {
                    text: `${String.fromCodePoint(0xF0297)}  Oyun`
                    font.pixelSize: root.fs - 3
                    weight: 600
                    color: Headset.balance <= 0.5 ? Theme.bright : Theme.dim
                }

                BarText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Headset.balance === 0.5 ? "dengede" : Headset.balance < 0.5 ? `sohbet %${Headset.chat}` : `oyun %${Headset.game}`
                    font.pixelSize: root.fs - 4
                    weight: root.wt
                    color: Theme.dim
                }

                BarText {
                    text: `Sohbet  ${String.fromCodePoint(0xF0369)}`
                    font.pixelSize: root.fs - 3
                    weight: 600
                    color: Headset.balance >= 0.5 ? Theme.bright : Theme.dim
                }
            }

            Item {
                id: bars

                readonly property int count: 25
                readonly property int mid: Math.floor(bars.count / 2)
                readonly property int lit: Math.round(Headset.balance * (bars.count - 1))

                Layout.fillWidth: true
                implicitHeight: 16

                Row {
                    anchors.centerIn: parent
                    spacing: (bars.width - bars.count * 3) / (bars.count - 1)

                    Repeater {
                        model: bars.count

                        Rectangle {
                            required property int index

                            readonly property bool on: index === bars.mid || (index >= Math.min(bars.mid, bars.lit) && index <= Math.max(bars.mid, bars.lit))

                            anchors.verticalCenter: parent.verticalCenter
                            width: 3
                            height: index === bars.lit ? 16 : index === bars.mid ? 12 : 8
                            radius: 1.5
                            color: index === bars.lit ? Theme.bright : on ? Theme.blue : Theme.rule

                            Behavior on color {
                                ColorAnimation {
                                    duration: Theme.anim
                                }
                            }
                            Behavior on height {
                                NumberAnimation {
                                    duration: Theme.anim
                                    easing.type: Theme.ease
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Card {
        id: bt

        visible: !!root.adapter
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            BarText {
                text: String.fromCodePoint(0xF00AF)
                font.pixelSize: root.fs + 2
                color: root.adapter?.enabled ? Theme.bright : Theme.dim
            }

            BarText {
                Layout.fillWidth: true
                text: "Bluetooth"
                font.pixelSize: root.fs - 1
                weight: 600
                color: root.adapter?.enabled ? Theme.text : Theme.dim
            }

            Toggle {
                on: root.adapter?.enabled ?? false
                onToggled: root.adapter.enabled = !root.adapter.enabled
            }
        }

        Repeater {
            model: root.adapter?.enabled ? root.headsets : []

            delegate: Rectangle {
                id: btRow

                required property var modelData

                Layout.fillWidth: true
                implicitHeight: 30
                radius: Theme.radius
                color: btMa.containsMouse ? Theme.hoverRaised : "transparent"

                Rectangle {
                    id: btDot
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: 6
                    height: 6
                    radius: 3
                    color: btRow.modelData.connected ? Theme.green : Theme.edge
                }

                BarText {
                    anchors.left: btDot.right
                    anchors.leftMargin: 10
                    anchors.right: btState.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.btLabel(btRow.modelData)
                    elide: Text.ElideRight
                    font.pixelSize: root.fs - 2
                    weight: root.wt
                    color: btRow.modelData.connected ? Theme.bright : Theme.text
                }

                BarText {
                    id: btState
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.btDetail(btRow.modelData)
                    font.pixelSize: root.fs - 3
                    weight: root.wt
                    color: Theme.dim
                }

                MouseArea {
                    id: btMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (btRow.modelData.connected)
                        btRow.modelData.disconnect();
                    else
                        btRow.modelData.connect()
                }
            }
        }
    }

    Card {
        id: micCard

        readonly property bool busy: root.recorders.length > 0

        padding: 10
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Item {
                implicitWidth: 18
                implicitHeight: 18

                Rectangle {
                    visible: micCard.busy
                    anchors.centerIn: parent
                    width: 18
                    height: 18
                    radius: 9
                    color: Qt.alpha(Theme.hot, 0.18)

                    SequentialAnimation on opacity {
                        running: parent.visible && root.visible
                        loops: Animation.Infinite
                        NumberAnimation {
                            to: 0.35
                            duration: 900
                            easing.type: Easing.InOutSine
                        }
                        NumberAnimation {
                            to: 1
                            duration: 900
                            easing.type: Easing.InOutSine
                        }
                    }
                }

                Rectangle {
                    visible: micCard.busy
                    anchors.centerIn: parent
                    width: 8
                    height: 8
                    radius: 4
                    color: Theme.hot
                }

                BarText {
                    visible: !micCard.busy
                    anchors.centerIn: parent
                    text: Glyph.micOff
                    font.pixelSize: root.fs + 1
                    color: Theme.dim
                }
            }

            BarText {
                Layout.fillWidth: true
                text: micCard.busy ? "Mikrofon kullanımda" : "Mikrofon boşta"
                font.pixelSize: root.fs - 2
                weight: 600
                color: micCard.busy ? Theme.text : Theme.dim
            }
        }

        Flow {
            Layout.fillWidth: true
            visible: micCard.busy
            spacing: 6

            Repeater {
                model: root.recorders

                delegate: Tag {
                    required property var modelData

                    text: root.appName(modelData)
                    dot: true
                    accent: true
                    tone: Theme.hot
                }
            }
        }
    }
}
