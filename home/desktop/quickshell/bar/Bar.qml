import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.UPower
import qs.weather
import qs.common
import qs.net

// A 30px top bar on every screen, its modules laid out like xeome's in small
// graphite cards: apps and workspaces on the left, the clock and Ankara's
// weather (weather/) in the middle, the tray drawer, a network and volume
// strip and power on the right; volume and power open xeome-style menus
// under them (AudioMenu, Power). The bar
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

    // The clock stays centred; the weather hangs on its right.
    Clock {
        id: clock
        anchors.centerIn: parent
        screenName: root.modelData.name
    }

    WeatherButton {
        anchors {
            left: clock.right
            leftMargin: 4
            verticalCenter: parent.verticalCenter
        }
        screenName: root.modelData.name
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

                NetButton {
                    bordered: false
                    screenName: root.modelData.name
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
                    screenName: root.modelData.name
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

        // Power (lock, log out, sleep, restart, shut down, keep awake). The
        // coffee glyph joins it while the idle inhibitor is on.
        BarModule {
            id: powerButton

            readonly property bool open: Panels.popup === `power@${root.modelData.name}`

            selected: open
            onClicked: Panels.togglePopup("power", root.modelData.name)

            // The power profile, only when it is not the default.
            BarText {
                visible: PowerProfiles.profile !== PowerProfile.Balanced
                anchors.verticalCenter: parent.verticalCenter
                text: PowerProfiles.profile === PowerProfile.Performance ? Glyph.perf : Glyph.saver
                color: PowerProfiles.profile === PowerProfile.Performance ? Theme.warm : Theme.text
                font.pixelSize: Theme.size + 1
            }

            BarText {
                visible: Panels.awake
                anchors.verticalCenter: parent.verticalCenter
                text: Glyph.awake
                color: Theme.text
                font.pixelSize: Theme.size + 1
            }

            BarText {
                anchors.verticalCenter: parent.verticalCenter
                text: Glyph.power
                color: powerButton.open ? Theme.bright : Theme.dim
                font.pixelSize: Theme.size + 1
            }

            LazyLoader {
                active: powerButton.open

                Power {
                    key: "power"
                    anchorItem: powerButton
                    screenName: root.modelData.name
                }
            }
        }
    }

    // Power's "keep awake": hypridle honours the inhibitor, so neither the
    // lock nor the screens-off timeout fires. Every bar holds one; the bar
    // is always mapped, which the protocol requires.
    IdleInhibitor {
        window: root
        enabled: Panels.awake
    }
}
