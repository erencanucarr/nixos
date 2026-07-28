import Quickshell.Services.SystemTray
import QtQuick

Item {
    id: tray

    required property var rootRef
    required property var barRef
    property bool expanded: false

    implicitHeight: 20
    implicitWidth: trayRow.implicitWidth
    Behavior on implicitWidth { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        onEntered: tray.expanded = true
        onExited:  tray.expanded = false
    }

    Row {
        id: trayRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        Text {
            text: tray.expanded ? "\u{203A}" : "\u{2039}"
            color: hoverArea.containsMouse ? rootRef.accent : "#8A8A8A"
            font { family: rootRef.fontFamily; pixelSize: 15; weight: Font.Bold }
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: 180 } }
        }

        Row {
            spacing: 10
            visible: tray.expanded
            opacity: tray.expanded ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

            Repeater {
                model: SystemTray.items

                delegate: Item {
                    required property SystemTrayItem modelData
                    implicitWidth: 18
                    implicitHeight: 18
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        anchors.fill: parent
                        source: modelData.icon
                        smooth: true
                        fillMode: Image.PreserveAspectFit
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton && modelData.hasMenu)
                                modelData.display(barRef, mouse.x, mouse.y)
                            else
                                modelData.activate()
                        }
                    }
                }
            }
        }
    }
}
