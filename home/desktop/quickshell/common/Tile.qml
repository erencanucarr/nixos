import QtQuick

Rectangle {
    id: root

    property string glyph
    property color tone: Theme.bright
    property bool lit: true
    property bool clickable: false
    property int glyphSize: 18

    signal clicked

    implicitWidth: 38
    implicitHeight: 38
    radius: Theme.radius + 2
    color: root.lit ? (ma.containsMouse ? Theme.selRaised : Theme.hoverRaised) : (ma.containsMouse ? Theme.hoverRaised : "transparent")
    border.width: 1
    border.color: root.lit ? Theme.edge : Qt.alpha(root.tone, 0.35)

    Behavior on color {
        ColorAnimation {
            duration: Theme.anim
        }
    }

    BarText {
        anchors.centerIn: parent
        text: root.glyph
        font.pixelSize: root.glyphSize
        color: root.tone
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: root.clickable
        enabled: root.clickable
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
