import QtQuick
import Quickshell
import Quickshell.Hyprland

// A bar popup hung under its button on a Surface (after xeome's Popup.qml).
// Derived popups set contentWidth and contentHeight; their children go onto
// the Surface. The Surface drifts down into place on the way in.
//
// Which popup is open lives in Panels.popup as "<key>@<screen>", so the bar
// buttons and IPC (Super+Esc) open the same one. A click outside the popup
// and its bar closes it: HyprlandFocusGrab, not xeome's grabFocus, because an
// xdg_popup grab needs a fresh input serial on the bar, which a keybind
// (IPC) open does not have, so Qt refuses to map the popup at all. Without
// that grab the popup never gets the keyboard either, so Esc is the bar's
// (Bar.qml takes the keyboard while one of its popups is open).
PopupWindow {
    id: root

    required property Item anchorItem
    // The Panels slot this popup follows ("power", "audio") on this screen.
    required property string key
    required property string screenName
    // Hang from the button's right edge instead of its centre, for buttons at
    // the screen's right end.
    property bool alignRight: false

    property real contentWidth
    property real contentHeight

    default property alias content: surface.data

    readonly property bool wanted: Panels.popup === `${key}@${screenName}`
    // The window is this much taller than the Surface, which rests at its
    // bottom: the drift has room without clipping the Surface's top edge.
    readonly property int drift: 6

    anchor.item: anchorItem
    anchor.edges: alignRight ? Edges.Bottom | Edges.Right : Edges.Bottom
    anchor.gravity: alignRight ? Edges.Bottom | Edges.Left : Edges.Bottom

    implicitWidth: contentWidth
    implicitHeight: contentHeight + drift
    color: "transparent"
    visible: false

    onWantedChanged: visible = wanted

    onVisibleChanged: {
        if (visible) {
            enter.restart();
        } else if (wanted) {
            // Closed by the grab: clear the slot so the button and IPC agree.
            Panels.popup = "";
        }
    }

    HyprlandFocusGrab {
        // The bar too, so its buttons and its Esc (Bar.qml) work while this
        // is open. Only once the bar holds the keyboard: a grab that starts
        // before Hyprland has applied the bar's Exclusive focus finds no
        // whitelisted surface to focus and is cleared at once.
        windows: [root.anchorItem.QsWindow.window, root]
        active: root.visible && root.anchorItem.QsWindow.window.holdsKeyboard
        onCleared: root.visible = false
    }

    Surface {
        id: surface

        width: parent.width
        height: root.contentHeight
        y: root.drift

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
