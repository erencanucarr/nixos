import Quickshell.I3
import QtQuick

ListView {
    required property var rootRef

    width: 220
    height: 20
    spacing: 16
    orientation: ListView.Horizontal
    interactive: false
    clip: false

    model: I3.workspaces

    delegate: Item {
            property var workspace: modelData
            readonly property bool focused: workspace !== null && workspace.focused
            readonly property bool urgent: workspace !== null && workspace.urgent

            visible: workspace !== null
            width: workspace === null ? 0 : Math.max(wsLabel.implicitWidth, 8)
            implicitWidth: Math.max(wsLabel.implicitWidth, 8)
            implicitHeight: 20

            Text {
                id: wsLabel
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                text: workspace === null ? "" : workspace.name
                color: urgent                ? rootRef.danger
                     : focused               ? rootRef.accent
                     : wsMouse.containsMouse ? rootRef.accent
                     :                         "#6A6A6A"
                font { family: rootRef.fontFamily; pixelSize: 13; weight: Font.Bold }
                Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
            }

            Rectangle {
                id: wsUnderline
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: -2
                width: focused ? Math.max(wsLabel.implicitWidth, 6) : 0
                height: 2
                radius: 1
                color: urgent ? rootRef.danger : rootRef.accent
                Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            }

            MouseArea {
                id: wsMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                enabled: workspace !== null
                onClicked: workspace && workspace.activate()
            }
    }
}
