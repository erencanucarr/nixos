import QtQuick
import Quickshell
import Quickshell.Wayland

// A clear layer over every other screen while a bar menu or the app drawer
// is open on one: a click there closes it, as a click beside it on its own
// screen does (otherwise it would stay open on the other screen).
// The bar stays uncovered, so another bar button opens its menu at once.
PanelWindow {
    id: root

    required property var modelData

    // The screen the open menu or drawer is on, or "".
    readonly property string busy: Panels.popup !== "" ? Panels.popup.split("@")[1] : Panels.drawerOpen ? Panels.drawerScreen : ""

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
        }
    }
}
