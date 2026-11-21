import QtQuick
import Quickshell
import Quickshell.Wayland

// A bar menu hung under its button on a Surface (after xeome's Popup.qml).
// Derived menus set contentWidth and contentHeight; their children go onto
// the Surface, which drifts down into place on the way in.
//
// Which menu is open lives in Panels.popup as "<key>@<screen>", so the bar
// buttons and IPC (Super+Esc) open the same one.
//
// Not a PopupWindow: closing it on a click outside needs either an xdg_popup
// grab (which wants a fresh input serial, so a keybind could not open it) or
// HyprlandFocusGrab, and under that grab Hyprland never delivered the mouse
// to the menu, so its sliders and pickers did nothing. Instead, like the app
// drawer, an overlay layer covers the screen below the bar: clicks outside
// the card close it, Esc closes it, and the bar stays clickable above it.
PanelWindow {
    id: root

    required property Item anchorItem
    // The Panels slot this menu follows ("power", "audio") on this screen.
    required property string key
    required property string screenName
    // Line the card's right edge up with the button's instead of centring it,
    // for buttons at the screen's right end.
    property bool alignRight: false

    property real contentWidth
    property real contentHeight

    default property alias content: surface.data

    readonly property bool wanted: Panels.popup === `${key}@${screenName}`
    readonly property int drift: 6

    function close(): void {
        Panels.popup = "";
    }

    // The button's left edge in screen pixels: the bar spans the screen from
    // x = 0, so its scene coordinates are the screen's. Re-read on each open.
    property real buttonX: 0

    screen: Quickshell.screens.find(s => s.name === root.screenName) ?? null
    visible: wanted

    WlrLayershell.namespace: "can-menu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    margins.top: Theme.barHeight
    color: "transparent"

    onVisibleChanged: {
        if (!visible)
            return;
        root.buttonX = root.anchorItem.mapToItem(null, 0, 0).x;
        keys.forceActiveFocus();
        enter.restart();
    }

    // A click anywhere outside the card.
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

        // Clicks on the card's empty parts stay on the card. First child, so
        // the menu's own controls sit above it.
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
