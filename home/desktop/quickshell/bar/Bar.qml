import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.UPower
import qs.weather
import qs.common
import qs.media
import qs.notif
import qs.net

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

        MediaButton {
            screenName: root.modelData.name
        }
    }

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

        Bell {
            screenName: root.modelData.name
        }

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

        BarModule {
            id: powerButton

            readonly property bool open: Panels.popup === `power@${root.modelData.name}`

            selected: open
            onClicked: Panels.togglePopup("power", root.modelData.name)

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

    IdleInhibitor {
        window: root
        enabled: Panels.awake
    }
}
