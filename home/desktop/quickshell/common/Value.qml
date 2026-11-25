import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property string label
    property string value: ""
    property var copier: null
    property bool copyable: root.copier !== null
    property string action: ""

    signal acted

    Layout.fillWidth: true
    implicitHeight: 26

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: -6
        anchors.rightMargin: -6
        radius: Theme.radius
        color: ma.containsMouse ? Theme.hoverRaised : "transparent"
    }

    BarText {
        id: labelText
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        font.pixelSize: 11
        weight: 550
        color: Theme.dim
    }

    BarText {
        anchors.left: labelText.right
        anchors.leftMargin: 12
        anchors.right: actionTag.visible ? actionTag.left : copyGlyph.left
        anchors.rightMargin: actionTag.visible ? 10 : (copyGlyph.visible ? 6 : 0)
        anchors.verticalCenter: parent.verticalCenter
        horizontalAlignment: Text.AlignRight
        text: root.value || "—"
        elide: Text.ElideLeft
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 11
        color: ma.containsMouse && root.copyable ? Theme.bright : Theme.text
    }

    BarText {
        id: copyGlyph
        visible: root.copyable && ma.containsMouse && !actionTag.visible
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: Glyph.copy
        font.pixelSize: 12
        color: Theme.dim
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.copyable && root.value !== ""
        cursorShape: Qt.PointingHandCursor
        onClicked: root.copier(root.value)
    }

    Tag {
        id: actionTag
        visible: root.action !== ""
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        implicitHeight: 20
        text: root.action
        tone: Theme.text
        clickable: true
        onClicked: root.acted()
    }
}
