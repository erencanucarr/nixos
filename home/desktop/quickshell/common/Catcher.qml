import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData

    readonly property string busy: Panels.popup !== "" ? Panels.popup.split("@")[1] : Panels.drawerOpen ? Panels.drawerScreen : Panels.wallsOpen ? Panels.wallsScreen : Panels.keysOpen ? Panels.keysScreen : ""

    screen: modelData
    visible: busy !== "" && busy !== modelData.name

    WlrLayershell.namespace: "can-catcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    margins.top: Theme.barHeight
    color: "transparent"

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onPressed: {
            Panels.popup = "";
            Panels.drawerOpen = false;
            Panels.wallsOpen = false;
            Panels.keysOpen = false;
        }
    }
}
