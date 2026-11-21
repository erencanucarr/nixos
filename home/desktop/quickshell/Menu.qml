import QtQuick
import QtQuick.Layouts

// The popup most bar buttons share (after xeome's Menu.qml): one width and
// padding. Children go straight into the column.
Popup {
    id: root

    default property alias rows: body.data

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
