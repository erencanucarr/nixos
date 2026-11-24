import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import qs.common

Menu {
    id: root

    readonly property int fs: 14
    readonly property int wt: 550

    required property var player

    signal picked(string id)

    readonly property var players: Mpris.players.values
    readonly property real length: (root.player?.lengthSupported && root.player.length > 0) ? root.player.length : Math.max(0, Lengths.get(root.player?.metadata?.["xesam:url"] ?? ""))
    readonly property bool hasLength: root.length > 0
    readonly property real position: Math.min(Positions.get(root.player), root.length > 0 ? root.length : Infinity)
    readonly property bool canSeek: root.player?.canSeek ?? false
    readonly property bool canPrev: root.player?.canGoPrevious ?? false
    readonly property bool canNext: root.player?.canGoNext ?? false

    readonly property var stream: {
        const p = root.player;
        if (!p)
            return null;
        const keys = [p.desktopEntry, p.identity, (p.identity ?? "").split(" ").pop()].filter(k => !!k).map(k => k.toLowerCase());
        return Pipewire.nodes.values.find(n => {
            if (!n.isStream || n.type !== PwNodeType.AudioOutStream || !n.audio)
                return false;
            const props = n.properties;
            const names = [props["application.name"], props["application.process.binary"], props["application.id"]].filter(k => !!k).map(k => k.toLowerCase());
            return names.some(a => keys.some(k => a === k || a.includes(k) || k.includes(a)));
        }) ?? null;
    }
    readonly property bool streamVolume: !!root.stream?.audio
    readonly property real volume: root.player?.volumeSupported ? root.player.volume : root.stream?.audio?.volume ?? 0
    readonly property bool hasVolume: (root.player?.volumeSupported ?? false) || root.streamVolume

    function setVolume(v: real): void {
        if (root.player?.volumeSupported)
            root.player.volume = v;
        else if (root.stream?.audio) {
            root.stream.audio.muted = false;
            root.stream.audio.volume = v;
        }
    }

    function mmss(t: real): string {
        const s = Math.max(0, Math.floor(t));
        return s >= 3600 ? `${Math.floor(s / 3600)}:${String(Math.floor(s / 60) % 60).padStart(2, "0")}:${String(s % 60).padStart(2, "0")}` : `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }

    function goToWindow(): void {
        const p = root.player;
        if (!p)
            return;
        const keys = [p.desktopEntry, (p.identity ?? "").split(" ").pop()].filter(k => !!k).map(k => k.toLowerCase());
        const win = Hyprland.toplevels.values.find(t => keys.includes((t.lastIpcObject?.class ?? "").toLowerCase()));
        if (win)
            Hyprland.dispatch(`hl.dsp.focus({ window = "address:0x${win.address}" })`);
        else if (p.canRaise)
            p.raise();
        Panels.popup = "";
    }

    contentWidth: 340
    rowSpacing: 10

    Component.onCompleted: Hyprland.refreshToplevels()

    PwObjectTracker {
        objects: root.stream ? [root.stream] : []
    }

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
        property bool on: false
        property string hint: ""

        signal activated

        implicitWidth: big ? 54 : 40
        implicitHeight: big ? 46 : 38
        radius: big ? implicitHeight / 2 : Theme.radius
        color: big ? (btnMa.containsMouse ? Theme.bright : Theme.text) : btn.on ? Theme.sel : btnMa.containsMouse ? Theme.hoverRaised : "transparent"
        border.width: big ? 0 : 1
        border.color: btn.on ? Theme.dim : Theme.edge
        opacity: btn.enabled ? 1 : 0.3
        scale: btnMa.pressed ? 0.92 : 1

        Behavior on color {
            ColorAnimation {
                duration: Theme.anim
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 120
            }
        }

        BarText {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: btn.hint ? -4 : 0
            text: btn.glyph
            font.pixelSize: btn.big ? root.fs + 9 : root.fs + 4
            color: btn.big ? Theme.ground : btn.on ? Theme.bright : Theme.text
        }

        BarText {
            visible: btn.hint !== ""
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: 3
            }
            text: btn.hint
            font.pixelSize: root.fs - 6
            weight: 650
            color: Theme.dim
        }

        MouseArea {
            id: btnMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.activated()
        }
    }

    ClippingRectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: width * 0.56
        radius: Theme.radius + 4
        color: Theme.ground
        border.width: 1
        border.color: Theme.edge

        BarText {
            anchors.centerIn: parent
            visible: cover.status !== Image.Ready
            text: String.fromCodePoint(0xF075A)
            font.pixelSize: 46
            color: Theme.rule
        }

        Image {
            id: cover
            anchors.fill: parent
            anchors.margins: 1
            source: root.player?.trackArtUrl ?? ""
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(640, 360)
            asynchronous: true
            visible: status === Image.Ready
        }

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                margins: 1
            }
            height: 34
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: "transparent"
                }
                GradientStop {
                    position: 1
                    color: Theme.alpha(Theme.ground, 0.8)
                }
            }
        }

        Rectangle {
            anchors {
                left: parent.left
                bottom: parent.bottom
                margins: 9
            }
            implicitWidth: who.implicitWidth + 14
            implicitHeight: 22
            radius: 11
            color: Theme.alpha(Theme.ground, 0.7)
            border.width: 1
            border.color: Theme.edge

            BarText {
                id: who
                anchors.centerIn: parent
                text: `${String.fromCodePoint(root.player?.isPlaying ? 0xF040A : 0xF03E4)}  ${root.player?.identity ?? ""}`
                font.pixelSize: root.fs - 4
                weight: 600
                color: Theme.text
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        BarText {
            Layout.fillWidth: true
            text: root.player?.trackTitle || "Bilinmeyen parça"
            elide: Text.ElideRight
            font.pixelSize: root.fs + 2
            weight: 650
            color: Theme.bright
        }

        BarText {
            Layout.fillWidth: true
            visible: text !== ""
            text: [root.player?.trackArtist ?? "", root.player?.trackAlbum ?? ""].filter(s => s).join("  ·  ")
            elide: Text.ElideRight
            font.pixelSize: root.fs - 1
            weight: root.wt
            color: Theme.dim
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Track {
            visible: root.hasLength
            thickness: 6
            value: root.length > 0 ? root.position / root.length : 0
            onMoved: fraction => {
                if (!root.canSeek)
                    return;
                Positions.seek(root.player, fraction * root.length);
                if (root.player.positionSupported)
                    root.player.position = fraction * root.length;
                else
                    root.player.seek(fraction * root.length - root.position);
            }
        }

        RowLayout {
            Layout.fillWidth: true

            BarText {
                text: root.mmss(root.position)
                font.pixelSize: root.fs - 3
                weight: root.wt
                color: Theme.dim
            }

            Item {
                Layout.fillWidth: true
            }

            BarText {
                text: root.hasLength ? `-${root.mmss(root.length - root.position)}` : "süre bilinmiyor"
                font.pixelSize: root.fs - 3
                weight: root.wt
                color: Theme.dim
            }
        }
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 8

        Button {
            visible: root.player?.shuffleSupported ?? false
            glyph: String.fromCodePoint(0xF049D)
            on: root.player?.shuffle ?? false
            onActivated: root.player.shuffle = !root.player.shuffle
        }

        Button {
            visible: root.canPrev
            glyph: String.fromCodePoint(0xF04AE)
            onActivated: root.player.previous()
        }

        Button {
            visible: root.canSeek
            glyph: String.fromCodePoint(0xF045F)
            hint: "10"
            onActivated: {
                Positions.seek(root.player, root.position - 10);
                root.player.seek(-10);
            }
        }

        Button {
            big: true
            glyph: String.fromCodePoint(root.player?.isPlaying ? 0xF03E4 : 0xF040A)
            enabled: root.player?.canTogglePlaying ?? false
            onActivated: root.player.togglePlaying()
        }

        Button {
            visible: root.canSeek
            glyph: String.fromCodePoint(0xF0211)
            hint: "10"
            onActivated: {
                Positions.seek(root.player, root.position + 10);
                root.player.seek(10);
            }
        }

        Button {
            visible: root.canNext
            glyph: String.fromCodePoint(0xF04AD)
            onActivated: root.player.next()
        }

        Button {
            visible: root.player?.loopSupported ?? false
            glyph: String.fromCodePoint(root.player?.loopState === MprisLoopState.Track ? 0xF0458 : 0xF0456)
            on: (root.player?.loopState ?? MprisLoopState.None) !== MprisLoopState.None
            onActivated: root.player.loopState = root.player.loopState === MprisLoopState.None ? MprisLoopState.Playlist : root.player.loopState === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None
        }
    }

    RowLayout {
        Layout.fillWidth: true
        visible: root.hasVolume
        spacing: 10

        BarText {
            text: root.volume <= 0.001 ? Glyph.volOff : root.volume > 0.66 ? Glyph.volHigh : root.volume > 0.33 ? Glyph.volMid : Glyph.volLow
            font.pixelSize: root.fs + 2
            color: Theme.dim

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: root.setVolume(root.volume > 0 ? 0 : 1)
            }
        }

        Track {
            thickness: 6
            value: root.volume
            onMoved: fraction => root.setVolume(fraction)
        }

        BarText {
            Layout.preferredWidth: 38
            horizontalAlignment: Text.AlignRight
            text: `${Math.round(root.volume * 100)}%`
            font.pixelSize: root.fs - 2
            weight: root.wt
            color: Theme.text
        }
    }

    Rule {}

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        BarText {
            Layout.fillWidth: true
            text: !root.canNext && root.canSeek ? "Bu oynatıcı sonraki parçayı desteklemiyor; 10 sn sarabilirsin" : ""
            elide: Text.ElideRight
            font.pixelSize: root.fs - 4
            weight: root.wt
            color: Theme.dim
        }

        BarText {
            text: `Pencereye git ${Glyph.chevronRight}`
            font.pixelSize: root.fs - 2
            weight: root.wt
            color: goMa.containsMouse ? Theme.bright : Theme.dim

            MouseArea {
                id: goMa
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.goToWindow()
            }
        }
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
}
