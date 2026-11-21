import QtQuick
import Quickshell
import Quickshell.Wayland

// A 30px top bar on every screen, its modules laid out like xeome's in small
// graphite cards: apps and workspaces on the left, the clock in the middle,
// the tray drawer, a network and volume strip and power on the right. The bar
// itself stays flat and square, with one hairline under it.
PanelWindow {
    id: root

    required property var modelData
    screen: modelData

    WlrLayershell.namespace: "can-bar"
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.barHeight
    color: Theme.ground

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: 1
        color: Theme.line
    }

    Row {
        anchors {
            left: parent.left
            leftMargin: Theme.gap + 2
            verticalCenter: parent.verticalCenter
        }
        spacing: 4

        BarModule {
            selected: Panels.drawerOpen
            onClicked: Panels.toggleDrawer()

            BarText {
                anchors.verticalCenter: parent.verticalCenter
                text: Glyph.apps
                color: Panels.drawerOpen ? Theme.bright : Theme.text
                font.pixelSize: Theme.size + 2
            }
        }

        Workspaces {
            screen: root.modelData
        }
    }

    Clock {
        anchors.centerIn: parent
    }

    Row {
        anchors {
            right: parent.right
            rightMargin: Theme.gap + 2
            verticalCenter: parent.verticalCenter
        }
        spacing: 4

        Tray {}

        // One connected strip, bordered once over the group because
        // per-module borders seam at every junction. The end modules round
        // their own outer corners; a hairline divides them.
        Item {
            implicitWidth: strip.implicitWidth
            implicitHeight: strip.implicitHeight

            Row {
                id: strip

                Net {
                    bordered: false
                    topLeftRadius: Theme.radius
                    bottomLeftRadius: Theme.radius
                }

                Rectangle {
                    width: 1
                    height: parent.height
                    color: Theme.line
                }

                Volume {
                    bordered: false
                    topRightRadius: Theme.radius
                    bottomRightRadius: Theme.radius
                }
            }

            Rectangle {
                anchors.fill: parent
                color: "transparent"
                radius: Theme.radius
                border.width: 1
                border.color: Theme.line

                CardEdges {}
            }
        }

        BarModule {
            selected: Panels.powerOpen
            onClicked: Panels.togglePower()

            BarText {
                anchors.verticalCenter: parent.verticalCenter
                text: Glyph.power
                color: Panels.powerOpen ? Theme.bright : Theme.dim
                font.pixelSize: Theme.size + 1
            }
        }
    }
}
