import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    required property var options
    required property var selected
    property int textSize: 11

    signal picked(var option)

    Layout.fillWidth: true
    implicitHeight: 32
    radius: Theme.radius + 2
    color: Theme.ground
    border.width: 1
    border.color: Theme.edge

    RowLayout {
        anchors.fill: parent
        anchors.margins: 3
        spacing: 3

        Repeater {
            model: root.options

            delegate: Rectangle {
                id: option

                required property var modelData
                readonly property bool current: root.selected(modelData)

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                radius: Theme.radius
                color: option.current ? Theme.selRaised : ma.containsMouse ? Theme.hoverRaised : "transparent"
                border.width: option.current ? 1 : 0
                border.color: Theme.edge

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.anim
                    }
                }

                BarText {
                    anchors.centerIn: parent
                    width: Math.min(implicitWidth, parent.width - 8)
                    elide: Text.ElideRight
                    text: option.modelData.glyph ? `${option.modelData.glyph}  ${option.modelData.name}` : option.modelData.name
                    font.pixelSize: root.textSize
                    weight: option.current ? 650 : 550
                    color: option.current ? Theme.bright : Theme.dim
                }

                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(option.modelData)
                }
            }
        }
    }
}
