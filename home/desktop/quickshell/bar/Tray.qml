import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.common

// A chevron card that reveals the tray icons on hover (after xeome's
// Tray.qml). Left click activates, right click opens the icon's menu;
// nm-applet only has a menu.
Rectangle {
    id: root

    // An open menu grabs the pointer and `hover` goes false; without menuOpen
    // the drawer would collapse and destroy the delegate holding the menu.
    readonly property bool expanded: hover.containsMouse || menuOpen
    property bool menuOpen: false

    // Bound eagerly: the tray service only starts syncing once referenced, so
    // a first read inside the Repeater leaves the drawer empty for seconds.
    readonly property var items: SystemTray.items.values

    // Ayatana indicators report onlyMenu=false yet have no Activate method.
    readonly property var menuOnlyIds: ["nm-applet"]

    implicitWidth: Math.max(implicitHeight, row.implicitWidth + 2 * (Theme.pad - 2))
    implicitHeight: Theme.barHeight - 2 * Theme.gap
    color: expanded ? Theme.hover : Theme.card
    radius: Theme.radius
    border.width: 1
    border.color: Theme.line

    CardEdges {}

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Theme.anim
            easing.type: Easing.OutCubic
        }
    }

    // Covers the whole drawer so it stays open over the icons. Declared first
    // so the per-icon click areas sit on top; those keep hoverEnabled off, or
    // they steal hover and the drawer flickers.
    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8

        BarText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.expanded ? Glyph.chevronRight : Glyph.chevronLeft
            color: root.expanded ? Theme.text : Theme.dim
            font.pixelSize: Theme.size + 1
        }

        Repeater {
            model: root.expanded ? root.items : []

            delegate: Item {
                id: item

                required property var modelData

                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: 15
                implicitHeight: 15

                IconImage {
                    anchors.fill: parent
                    source: item.modelData.icon
                    opacity: item.modelData.status === Status.Passive ? 0.5 : 1
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    onClicked: e => {
                        if (e.button === Qt.MiddleButton)
                            item.modelData.secondaryActivate();
                        else if (item.modelData.hasMenu && (e.button === Qt.RightButton || item.modelData.onlyMenu || root.menuOnlyIds.includes(item.modelData.id)))
                            menu.open();
                        else
                            item.modelData.activate();
                    }
                }

                QsMenuAnchor {
                    id: menu
                    menu: item.modelData.menu
                    anchor.item: item
                    anchor.edges: Edges.Bottom
                    anchor.gravity: Edges.Bottom
                    onVisibleChanged: root.menuOpen = visible
                }
            }
        }
    }
}
