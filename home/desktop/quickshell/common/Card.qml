import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    default property alias content: inner.data
    property alias spacing: inner.spacing
    property int padding: 12

    Layout.fillWidth: true
    implicitHeight: inner.implicitHeight + root.padding * 2
    radius: Theme.radiusLg
    color: Theme.card
    border.width: 1
    border.color: Theme.edge

    ColumnLayout {
        id: inner

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: root.padding
        }
        spacing: 10
    }
}
