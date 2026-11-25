import QtQuick
import QtQuick.Layouts

Rectangle {
    property bool vertical: false

    Layout.fillWidth: !vertical
    Layout.leftMargin: vertical ? 4 : Layout.margins
    Layout.rightMargin: vertical ? 4 : Layout.margins
    implicitWidth: vertical ? 1 : 0
    implicitHeight: vertical ? 18 : 1
    color: vertical ? Theme.rule : Theme.edge
}
