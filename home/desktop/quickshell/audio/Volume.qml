import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.common

BarModule {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property int volume: Math.round((sink?.audio?.volume ?? 0) * 100)
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property bool overBluetooth: sink?.name.startsWith("bluez_output.") ?? false
    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool micMuted: source?.audio?.muted ?? false

    required property string screenName

    minWidth: 56

    readonly property string open: Panels.popup.endsWith(`@${root.screenName}`) ? Panels.popup.split("@")[0] : ""

    selected: open === "audio" || open === "audio-apps"

    onClicked: button => {
        if (button === Qt.LeftButton) {
            if (root.open === "audio-apps")
                Panels.popup = "";
            else
                Panels.togglePopup("audio", root.screenName);
        } else if (button === Qt.RightButton) {
            Quickshell.execDetached(["pavucontrol"]);
        } else if (root.sink?.audio)
            root.sink.audio.muted = !root.sink.audio.muted;
    }

    onScrolled: delta => {
        if (root.sink?.audio)
            root.sink.audio.volume = Math.max(0, Math.min(1, root.sink.audio.volume + (delta > 0 ? 0.05 : -0.05)));
    }

    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    BarText {
        visible: root.micMuted || AudioNodes.recorders.length > 0
        anchors.verticalCenter: parent.verticalCenter
        text: root.micMuted ? Glyph.micOff : Glyph.mic
        color: root.micMuted ? Theme.hot : Theme.warm
        font.pixelSize: Theme.size + 1
    }

    BarText {
        anchors.verticalCenter: parent.verticalCenter
        text: root.muted ? Glyph.volOff : `${root.overBluetooth ? Glyph.headset : root.volume > 66 ? Glyph.volHigh : root.volume > 33 ? Glyph.volMid : Glyph.volLow} ${root.volume}%`
        color: root.muted ? Theme.dim : Theme.text
        font.pixelSize: Theme.size + 1
        font.wordSpacing: Theme.glyphGap
    }

    LazyLoader {
        active: root.open === "audio"

        AudioMenu {
            key: "audio"
            anchorItem: root
            screenName: root.screenName
            alignRight: true
        }
    }

    LazyLoader {
        active: root.open === "audio-apps"

        AppsMenu {
            key: "audio-apps"
            anchorItem: root
            screenName: root.screenName
            alignRight: true
        }
    }
}
