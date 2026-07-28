import Quickshell.Services.Mpris
import QtQuick

Item {
    id: m

    required property var rootRef

    readonly property var player: {
        const list = Mpris.players ? Mpris.players.values : []
        for (const p of list) {
            if (p && (p.canControl === undefined || p.canControl)) return p
        }
        return null
    }
    readonly property string _title: player && player.trackTitle ? player.trackTitle : ""
    readonly property string _artists: {
        if (!player) return ""
        const a = player.trackArtists
        if (Array.isArray(a)) return a.join(", ")
        return a || ""
    }
    readonly property bool _playing: player && (player.isPlaying === true
        || (player.playbackState !== undefined && player.playbackState === MprisPlaybackState.Playing))

    visible: player !== null && (_title.length > 0 || _artists.length > 0)
    implicitHeight: 20
    implicitWidth: mprisRow.implicitWidth

    Row {
        id: mprisRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Text {
            text: m._playing ? "\u{F03E4}" : "\u{F040A}"
            color: rootRef.accent
            font { family: rootRef.fontFamily; pixelSize: 13; weight: Font.Bold }
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: m._artists ? (m._artists + "  —  " + m._title) : m._title
            color: rootRef.accent
            elide: Text.ElideRight
            width: Math.min(implicitWidth, 260)
            font { family: rootRef.fontFamily; pixelSize: 13; weight: Font.Bold }
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: mMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (!m.player) return
            if (mouse.button === Qt.RightButton) {
                if (m.player.next) m.player.next()
            } else if (m.player.togglePlaying) {
                m.player.togglePlaying()
            } else if (m._playing && m.player.pause) {
                m.player.pause()
            } else if (m.player.play) {
                m.player.play()
            }
        }
    }
}
