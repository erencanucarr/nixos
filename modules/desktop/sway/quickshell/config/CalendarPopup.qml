import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    required property var modelData
    required property var rootRef
    required property var clockRef

    screen: modelData
    WlrLayershell.namespace: "quickshell-calendar-shade"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    anchors { top: true; left: true; right: true; bottom: true }
    margins { top: 34 }
    color: "transparent"
    visible: rootRef.calendarOpen

    MouseArea {
        anchors.fill: parent
        onClicked: rootRef.calendarOpen = false
    }

    Rectangle {
        id: calendarBox
        x: parent.width - width - 12
        y: 8
        width: 300
        height: 286
        color: rootRef.chip
        border { color: "#8A8A8A"; width: 2 }
        radius: 7
        MouseArea { anchors.fill: parent; onClicked: {} }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    Layout.fillWidth: true
                    text: Qt.formatDateTime(clockRef.date, "MMMM yyyy")
                    color: rootRef.accent
                    font { family: rootRef.fontFamily; pixelSize: 19; weight: Font.Bold }
                }

                Text {
                    text: Qt.formatDateTime(clockRef.date, "HH:mm")
                    color: rootRef.fg
                    font { family: rootRef.fontFamily; pixelSize: 13; weight: Font.Bold }
                }
            }

            Text {
                Layout.fillWidth: true
                text: Qt.formatDateTime(clockRef.date, "dddd, d MMMM")
                color: rootRef.fg
                font { family: rootRef.fontFamily; pixelSize: 12; weight: Font.Bold }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: rootRef.line }

            GridLayout {
                Layout.fillWidth: true
                columns: 7
                rowSpacing: 6
                columnSpacing: 6

                Repeater {
                    model: ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"]
                    delegate: Text {
                        required property string modelData
                        Layout.preferredWidth: 32
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        color: rootRef.fg
                        font { family: rootRef.fontFamily; pixelSize: 10; weight: Font.Bold }
                    }
                }

                Repeater {
                    model: 42
                    delegate: Rectangle {
                        required property int index
                        readonly property int first: rootRef.firstDayOffset(clockRef.date)
                        readonly property int day: index - first + 1
                        readonly property bool valid: day > 0 && day <= rootRef.daysInMonth(clockRef.date)
                        readonly property bool today: valid && day === clockRef.date.getDate()
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 26
                        color: today ? rootRef.chipOn : "transparent"
                        border { color: today ? rootRef.accent : "transparent"; width: 1 }
                        radius: 5

                        Text {
                            anchors.centerIn: parent
                            text: parent.valid ? String(parent.day) : ""
                            color: parent.today ? rootRef.accent : rootRef.fg
                            font { family: rootRef.fontFamily; pixelSize: 12; weight: parent.today ? Font.Bold : Font.Normal }
                        }
                    }
                }
            }
        }
    }
}
