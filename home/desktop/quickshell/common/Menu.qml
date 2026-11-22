import QtQuick
import QtQuick.Layouts

Popup {
    id: root

    default property alias rows: body.data
    property alias rowSpacing: body.spacing

    contentWidth: Theme.menuWidth
    contentHeight: body.implicitHeight + Theme.pad * 2

    ColumnLayout {
        id: body

        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: Theme.pad + 2
            rightMargin: Theme.pad + 2
        }
        spacing: 7
    }
}
