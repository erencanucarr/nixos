import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property Item anchorItem
    required property string key
    required property string screenName
    property bool alignRight: false

    property real contentWidth
    property real contentHeight

    default property alias content: surface.data

    readonly property bool wanted: Panels.popup === `${key}@${screenName}`
    readonly property int drift: 6

    function close(): void {
        Panels.popup = "";
    }

    property real buttonX: 0

    screen: Quickshell.screens.find(s => s.name === root.screenName) ?? null
    visible: wanted

    WlrLayershell.namespace: "can-menu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusionMode: ExclusionMode.Ignore
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    margins.top: Theme.barHeight
    color: "transparent"

    function opened(): void {
        root.buttonX = root.anchorItem.mapToItem(null, 0, 0).x;
        keys.forceActiveFocus();
        enter.restart();
    }

    onVisibleChanged: if (visible)
        opened()
    Component.onCompleted: if (visible)
        Qt.callLater(opened)

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: root.close()
    }

    Item {
        id: keys
        focus: true
        Keys.onEscapePressed: root.close()
    }

    Surface {
        id: surface

        x: Math.max(Theme.pad, Math.min(root.width - root.contentWidth - Theme.pad, root.alignRight ? root.buttonX + root.anchorItem.width - root.contentWidth : root.buttonX + (root.anchorItem.width - root.contentWidth) / 2))
        y: root.drift
        width: root.contentWidth
        height: root.contentHeight

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        NumberAnimation on y {
            id: enter
            from: 0
            to: root.drift
            duration: Theme.anim
            easing.type: Theme.ease
            running: false
        }
    }
}
