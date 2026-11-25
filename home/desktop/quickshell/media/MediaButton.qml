import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.common

BarModule {
    id: root

    required property string screenName

    readonly property bool open: Panels.popup === `media@${root.screenName}`
    property string selectedId: ""
    readonly property var player: Mpris.players.values.find(p => String(p.uniqueId) === root.selectedId) ?? Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null

    function clip(s: string, n: int): string {
        return s.length > n ? s.slice(0, n - 1) + "…" : s;
    }

    visible: player !== null
    selected: open

    onClicked: button => {
        if (button === Qt.MiddleButton)
            root.player?.togglePlaying();
        else
            Panels.togglePopup("media", root.screenName);
    }
    onScrolled: delta => {
        const p = root.player;
        if (!p)
            return;
        if (delta > 0)
            p.canGoPrevious ? p.previous() : p.canSeek && p.seek(-5);
        else
            p.canGoNext ? p.next() : p.canSeek && p.seek(5);
    }

    onVisibleChanged: if (!visible && root.open)
        Panels.popup = ""

    BarText {
        readonly property var p: root.player
        readonly property string label: root.clip([p?.trackArtist ?? "", p?.trackTitle ?? ""].filter(s => s !== "").join(" - "), 32)

        anchors.verticalCenter: parent.verticalCenter
        text: `${p?.isPlaying ? Glyph.play : Glyph.pause} ${label}`
        color: p?.isPlaying ? Theme.text : Theme.dim
        font.italic: !(p?.isPlaying ?? false)
        font.wordSpacing: Theme.glyphGap
    }

    LazyLoader {
        active: root.open

        MediaMenu {
            key: "media"
            anchorItem: root
            screenName: root.screenName
            player: root.player
            onPicked: id => root.selectedId = id
        }
    }
}
