import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Output volume, plus a warm mic glyph while something records (after
// xeome's Audio.qml). Click for AudioMenu, right click for the mixer
// (pavucontrol), middle click to mute, scroll to change the volume.
BarModule {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property int volume: Math.round((sink?.audio?.volume ?? 0) * 100)
    readonly property bool muted: sink?.audio?.muted ?? false
    // bluez5 names every sink `bluez_output.<mac>.<profile>`.
    readonly property bool overBluetooth: sink?.name.startsWith("bluez_output.") ?? false
    // A noise-suppression filter chain holds a `capture.*` stream open
    // permanently; that is not someone recording.
    readonly property var recorders: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioInStream && !n.name.startsWith("capture."))

    required property string screenName

    // Room for "100%", so the strip does not shift as the volume changes.
    minWidth: 56
    selected: menu.visible

    onClicked: button => {
        if (button === Qt.LeftButton) {
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

    // Volume and mute are unreadable until the node is bound.
    PwObjectTracker {
        objects: [root.sink]
    }

    BarText {
        visible: root.recorders.length > 0
        anchors.verticalCenter: parent.verticalCenter
        text: Glyph.mic
        color: Theme.warm
        font.pixelSize: Theme.size + 1
    }

    BarText {
        anchors.verticalCenter: parent.verticalCenter
        // Over bluetooth the headset glyph replaces the volume ramp.
        text: root.muted ? Glyph.volOff : `${root.overBluetooth ? Glyph.headset : root.volume > 66 ? Glyph.volHigh : root.volume > 33 ? Glyph.volMid : Glyph.volLow} ${root.volume}%`
        color: root.muted ? Theme.dim : Theme.text
        // The volume glyphs are drawn small next to Inter's figures.
        font.pixelSize: Theme.size + 1
        // Every space in this label separates a glyph from a value.
        font.wordSpacing: Theme.glyphGap
    }

    AudioMenu {
        id: menu
        key: "audio"
        anchorItem: root
        screenName: root.screenName
        alignRight: true
        recorders: root.recorders
    }
}
