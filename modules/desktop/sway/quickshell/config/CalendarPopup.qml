import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: calendarShade

    required property var modelData
    required property var rootRef
    required property var clockRef
    property int monthOffset: 0

    readonly property var shownDate: new Date(clockRef.date.getFullYear(), clockRef.date.getMonth() + monthOffset, 1)
    readonly property var weeks: {
        const first = shownDate
        const origin = new Date(first.getFullYear(), first.getMonth(), 1 - ((first.getDay() + 6) % 7))
        const result = []
        for (let week = 0; week < 6; week++) {
            const monday = new Date(origin.getFullYear(), origin.getMonth(), origin.getDate() + week * 7)
            const days = []
            for (let day = 0; day < 7; day++) {
                const date = new Date(monday.getFullYear(), monday.getMonth(), monday.getDate() + day)
                days.push({
                    day: date.getDate(),
                    inMonth: date.getMonth() === first.getMonth(),
                    today: date.toDateString() === clockRef.date.toDateString(),
                    weekend: day > 4
                })
            }
            result.push({ week: isoWeek(monday), days: days })
        }
        return result
    }

    function isoWeek(date) {
        const thursday = new Date(date.getFullYear(), date.getMonth(), date.getDate() + 3)
        const jan1 = new Date(thursday.getFullYear(), 0, 1)
        return Math.floor(Math.round((thursday - jan1) / 86400000) / 7) + 1
    }

    screen: modelData
    WlrLayershell.namespace: "quickshell-calendar"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors { top: true; left: true; right: true; bottom: true }
    margins { top: 0 }
    color: "transparent"
    visible: rootRef.calendarOpen

    onVisibleChanged: if (!visible) monthOffset = 0

    MouseArea {
        anchors.fill: parent
        onClicked: rootRef.calendarOpen = false
    }

    Rectangle {
        id: panel
        x: parent.width - width - 10
        y: 0
        width: 330
        height: 350
        color: "#0D0D0D"
        border { color: "#FFFFFF"; width: 1 }
        focus: visible
        Keys.onEscapePressed: event => {
            rootRef.calendarOpen = false
            event.accepted = true
        }
        MouseArea { anchors.fill: parent; onClicked: {} }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 9

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Rectangle {
                    width: 26
                    height: 26
                    color: previousArea.containsMouse ? "#242426" : "transparent"
                    border { color: "#333337"; width: 1 }
                    Text { anchors.centerIn: parent; text: "󰅁"; color: "#FFFFFF"; font { family: rootRef.fontFamily; pixelSize: 15; weight: Font.Bold } }
                    MouseArea { id: previousArea; anchors.fill: parent; hoverEnabled: true; onClicked: calendarShade.monthOffset-- }
                }
                Text {
                    Layout.fillWidth: true
                    text: Qt.formatDateTime(calendarShade.shownDate, "MMMM yyyy")
                    horizontalAlignment: Text.AlignHCenter
                    color: calendarShade.monthOffset === 0 ? "#FFFFFF" : "#A0A0A0"
                    font { family: rootRef.fontFamily; pixelSize: 16; weight: Font.Bold }
                    MouseArea { anchors.fill: parent; onClicked: calendarShade.monthOffset = 0 }
                }
                Rectangle {
                    width: 26
                    height: 26
                    color: nextArea.containsMouse ? "#242426" : "transparent"
                    border { color: "#333337"; width: 1 }
                    Text { anchors.centerIn: parent; text: "󰅂"; color: "#FFFFFF"; font { family: rootRef.fontFamily; pixelSize: 15; weight: Font.Bold } }
                    MouseArea { id: nextArea; anchors.fill: parent; hoverEnabled: true; onClicked: calendarShade.monthOffset++ }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#333337" }

            Column {
                Layout.alignment: Qt.AlignHCenter
                spacing: 2

                Row {
                    spacing: 2
                    Item { width: 24; height: 20 }
                    Repeater {
                        model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                        delegate: Text {
                            required property string modelData
                            required property int index
                            width: 36
                            height: 20
                            text: modelData
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            color: index > 4 ? "#555555" : "#A0A0A0"
                            font { family: rootRef.fontFamily; pixelSize: 10; weight: Font.Bold }
                        }
                    }
                }

                Repeater {
                    model: calendarShade.weeks
                    delegate: Row {
                        required property var modelData
                        spacing: 2
                        Text {
                            width: 24
                            height: 26
                            text: modelData.week
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            color: "#555555"
                            font { family: rootRef.fontFamily; pixelSize: 10; weight: Font.Bold }
                        }
                        Repeater {
                            model: modelData.days
                            delegate: Rectangle {
                                required property var modelData
                                width: 36
                                height: 26
                                color: modelData.today ? "#FFFFFF" : "transparent"
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.day
                                    color: modelData.today ? "#000000" : !modelData.inMonth ? "#444444" : modelData.weekend ? "#888888" : "#FFFFFF"
                                    font { family: rootRef.fontFamily; pixelSize: 11; weight: modelData.today ? Font.Bold : Font.Normal }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#333337" }
            Text {
                Layout.fillWidth: true
                text: Qt.formatDateTime(clockRef.date, "dddd, d MMMM yyyy") + "  ·  week " + calendarShade.isoWeek(clockRef.date)
                horizontalAlignment: Text.AlignHCenter
                color: "#A0A0A0"
                font { family: rootRef.fontFamily; pixelSize: 10; weight: Font.Bold }
            }
        }
    }
}
