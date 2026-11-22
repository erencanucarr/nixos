import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Widgets
import qs.common

Menu {
    id: root

    readonly property int fs: 14
    readonly property int wt: 550

    required property var player

    signal picked(string id)

    readonly property var players: Mpris.players.values
    readonly property real length: root.player?.lengthSupported ? root.player.length : 0
    readonly property bool seekable: root.length > 0 && (root.player?.positionSupported ?? false)

    function mmss(t: real): string {
        const s = Math.max(0, Math.floor(t));
        return s >= 3600 ? `${Math.floor(s / 3600)}:${String(Math.floor(s / 60) % 60).padStart(2, "0")}:${String(s % 60).padStart(2, "0")}` : `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }

    contentWidth: 340
    rowSpacing: 10

    Timer {
        interval: 1000
        repeat: true
        running: root.player?.isPlaying ?? false
        onTriggered: root.player.positionChanged()
    }

    component Button: Rectangle {
        id: btn

        property string glyph
        property bool big: false

        signal activated

        implicitWidth: big ? 52 : 42
        implicitHeight: big ? 42 : 36
        radius: Theme.radius
        color: big ? (btnMa.containsMouse ? Theme.bright : Theme.text) : btnMa.containsMouse ? Theme.hoverRaised : "transparent"
        border.width: big ? 0 : 1
        border.color: Theme.edge
        opacity: btn.enabled ? 1 : 0.3

        Behavior on color {
            ColorAnimation {
                duration: Theme.anim
            }
        }

        BarText {
            anchors.centerIn: parent
            text: btn.glyph
            font.pixelSize: btn.big ? root.fs + 8 : root.fs + 4
            color: btn.big ? Theme.ground : Theme.text
        }

        MouseArea {
            id: btnMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.activated()
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 14

        CoverArt {}

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            BarText {
                Layout.fillWidth: true
                text: root.player?.trackTitle || "Bilinmeyen parça"
                elide: Text.ElideRight
                font.pixelSize: root.fs + 1
                weight: 650
                color: Theme.bright
            }

            BarText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.player?.trackArtist ?? ""
                elide: Text.ElideRight
                font.pixelSize: root.fs - 1
                weight: root.wt
                color: Theme.text
            }

            BarText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.player?.trackAlbum ?? ""
                elide: Text.ElideRight
                font.pixelSize: root.fs - 3
                weight: root.wt
                color: Theme.dim
            }

            BarText {
                Layout.fillWidth: true
                text: root.player?.identity ?? ""
                elide: Text.ElideRight
                font.pixelSize: root.fs - 4
                weight: root.wt
                color: Theme.dim
                opacity: 0.7
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2
        visible: root.seekable

        Track {
            thickness: 6
            value: root.length > 0 ? (root.player?.position ?? 0) / root.length : 0
            onMoved: fraction => {
                if (root.player?.canSeek)
                    root.player.position = fraction * root.length;
            }
        }

        RowLayout {
            Layout.fillWidth: true

            BarText {
                Layout.fillWidth: true
                text: root.mmss(root.player?.position ?? 0)
                font.pixelSize: root.fs - 4
                weight: root.wt
                color: Theme.dim
            }

            BarText {
                text: root.mmss(root.length)
                font.pixelSize: root.fs - 4
                weight: root.wt
                color: Theme.dim
            }
        }
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 8

        Button {
            glyph: String.fromCodePoint(0xF04AE)
            enabled: root.player?.canGoPrevious ?? false
            onActivated: root.player.previous()
        }

        Button {
            big: true
            glyph: String.fromCodePoint(root.player?.isPlaying ? 0xF03E4 : 0xF040A)
            enabled: root.player?.canTogglePlaying ?? false
            onActivated: root.player.togglePlaying()
        }

        Button {
            glyph: String.fromCodePoint(0xF04AD)
            enabled: root.player?.canGoNext ?? false
            onActivated: root.player.next()
        }
    }

    Rule {
        visible: list.visible
    }

    ColumnLayout {
        id: list

        property bool expanded: false

        Layout.fillWidth: true
        spacing: 2
        visible: root.players.length > 1

        Pick {
            implicitHeight: 30
            textSize: root.fs - 2
            weight: root.wt
            label: root.player?.identity ?? ""
            suffix: `${root.players.length} oynatıcı  ${list.expanded ? Glyph.chevronUp : Glyph.chevronDown}`
            onClicked: list.expanded = !list.expanded
        }

        Repeater {
            model: list.expanded ? root.players : []

            delegate: Pick {
                required property var modelData

                implicitHeight: 30
                textSize: root.fs - 2
                weight: root.wt
                label: modelData.identity
                suffix: modelData.isPlaying ? "çalıyor" : ""
                current: root.player?.uniqueId === modelData.uniqueId
                onClicked: {
                    root.picked(String(modelData.uniqueId));
                    list.expanded = false;
                }
            }
        }
    }

    component CoverArt: ClippingRectangle {
        Layout.preferredWidth: 76
        Layout.preferredHeight: 76
        radius: Theme.radius + 2
        color: Theme.ground
        border.width: 1
        border.color: Theme.edge

        BarText {
            anchors.centerIn: parent
            visible: cover.status !== Image.Ready
            text: String.fromCodePoint(0xF075A)
            font.pixelSize: 28
            color: Theme.dim
        }

        Image {
            id: cover
            anchors.fill: parent
            anchors.margins: 1
            source: root.player?.trackArtUrl ?? ""
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(152, 152)
            asynchronous: true
            visible: status === Image.Ready
        }
    }
}
