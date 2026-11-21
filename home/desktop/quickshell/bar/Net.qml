import QtQuick
import Quickshell
import Quickshell.Networking
import qs.common

// The connection as one glyph (after xeome's Net.qml): the wifi signal ramp
// over wifi, a cable over ethernet, dim and crossed out with neither. Click
// for nm-connection-editor; nm-applet in the tray still has the full menu.
BarModule {
    id: root

    readonly property var wifi: Networking.devices.values.find(d => d.connected && d.type === DeviceType.Wifi) ?? null
    readonly property var wired: Networking.devices.values.find(d => d.connected && d.type === DeviceType.Wired) ?? null
    readonly property var network: wifi?.networks.values.find(n => n.connected) ?? null

    onClicked: Quickshell.execDetached(["nm-connection-editor"])

    BarText {
        anchors.verticalCenter: parent.verticalCenter
        text: root.wired ? Glyph.wired : root.wifi ? Glyph.wifi[Math.min(4, Math.floor((root.network?.signalStrength ?? 0) * 5))] : Glyph.wiredOff
        color: root.wired || root.wifi ? Theme.text : Theme.dim
        font.pixelSize: Theme.size + 1
    }
}
