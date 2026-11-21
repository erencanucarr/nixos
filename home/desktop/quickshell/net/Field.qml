import QtQuick
import QtQuick.Layouts
import qs.common

// A one-line text box on `raised`, bordered like Pick; brighter edged while
// typing. Enter fires `accepted`.
Rectangle {
    id: root

    property alias text: input.text
    property string placeholder: ""
    property bool secret: false
    property alias input: input

    signal accepted

    Layout.fillWidth: true
    implicitHeight: 26
    radius: Theme.radius
    color: Theme.ground
    border.width: 1
    border.color: input.activeFocus ? Theme.dim : Theme.edge

    TextInput {
        id: input

        anchors {
            fill: parent
            leftMargin: 9
            rightMargin: 9
        }
        verticalAlignment: TextInput.AlignVCenter
        color: Theme.text
        selectionColor: Theme.text
        selectedTextColor: Theme.ground
        font.family: Theme.family
        font.pixelSize: Theme.small
        echoMode: root.secret ? TextInput.Password : TextInput.Normal
        clip: true
        onAccepted: root.accepted()
    }

    BarText {
        anchors {
            left: parent.left
            leftMargin: 9
            verticalCenter: parent.verticalCenter
        }
        visible: input.text === "" && !input.activeFocus
        text: root.placeholder
        font.pixelSize: Theme.small
        color: Theme.dim
    }
}
