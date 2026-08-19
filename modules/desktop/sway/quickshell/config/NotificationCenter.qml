import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: notifShade

    required property var modelData
    required property var rootRef
    required property var notificationServer
    property bool reminderTab: false
    property bool historyTab: false
    property int reminderTick: 0
    property string reminderError: ""
    property string repeatMode: "none"

    function submitReminder() {
        const message = reminderMessageInput.text
        const dueAt = rootRef.parseReminderDate(reminderDateInput.text, reminderTimeInput.text)
        if (dueAt === 0) {
            reminderError = "Use 18 Ağustos 2026 and 18:00"
            return
        }
        const added = dueAt === null
            ? rootRef.addReminder(reminderMinutesInput.text, message, repeatMode)
            : rootRef.addReminderAt(dueAt, message, repeatMode)
        if (!added) {
            reminderError = dueAt === null ? "Enter a message" : "That time is in the past"
            return
        }
        reminderError = ""
        reminderMessageInput.text = ""
        reminderDateInput.text = ""
        reminderTimeInput.text = ""
        reminderMinutesInput.text = "10"
        repeatMode = "none"
    }

    screen: modelData
    WlrLayershell.namespace: "quickshell-notifications"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors { top: true; left: true; right: true; bottom: true }
    margins { top: 0 }
    color: "transparent"
    visible: rootRef.notifOpen

    MouseArea {
        anchors.fill: parent
        onClicked: rootRef.notifOpen = false
    }

    Rectangle {
        id: panel
        x: parent.width - width - 10
        y: 0
        width: 420
        height: Math.min(parent.height - 20, 520)
        color: "#0D0D0D"
        border { color: "#FFFFFF"; width: 1 }
        focus: visible
        Keys.onEscapePressed: event => {
            rootRef.notifOpen = false
            event.accepted = true
        }
        MouseArea { anchors.fill: parent; onClicked: {} }

        Timer {
            interval: 1000
            running: notifShade.visible && notifShade.reminderTab
            repeat: true
            onTriggered: notifShade.reminderTick++
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: historyTab ? "󰋼  HISTORY" : reminderTab ? "󰃰  REMINDERS" : "󰂚  NOTIFICATIONS"
                    color: "#FFFFFF"
                    font { family: rootRef.fontFamily; pixelSize: 16; weight: Font.Bold }
                }
                Text {
                    text: historyTab ? rootRef.notificationHistory.length + " SAVED" : reminderTab ? rootRef.reminders.length + " ACTIVE" : notificationServer.trackedNotifications.values.length + " ACTIVE"
                    color: "#A0A0A0"
                    font { family: rootRef.fontFamily; pixelSize: 10; weight: Font.Bold }
                }
                Rectangle {
                    Layout.preferredWidth: clearLabel.implicitWidth + 20
                    Layout.preferredHeight: 28
                    visible: !reminderTab && !historyTab
                    color: clearArea.containsMouse ? "#2E2E30" : "transparent"
                    border { color: "#333337"; width: 1 }
                    Text {
                        id: clearLabel
                        anchors.centerIn: parent
                        text: "󰎟  CLEAR"
                        color: "#FFFFFF"
                        font { family: rootRef.fontFamily; pixelSize: 10; weight: Font.Bold }
                    }
                    MouseArea {
                        id: clearArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            for (const n of notificationServer.trackedNotifications.values.slice()) n.dismiss()
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#333337" }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    color: !reminderTab && !historyTab ? "#FFFFFF" : "transparent"
                    border { color: "#555555"; width: 1 }
                    Text {
                        anchors.centerIn: parent
                        text: "NOTIFICATIONS"
                        color: !reminderTab && !historyTab ? "#0D0D0D" : "#A0A0A0"
                        font { family: rootRef.fontFamily; pixelSize: 10; weight: Font.Bold }
                    }
                    MouseArea { anchors.fill: parent; onClicked: { reminderTab = false; historyTab = false } }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    color: reminderTab ? "#FFFFFF" : "transparent"
                    border { color: "#555555"; width: 1 }
                    Text {
                        anchors.centerIn: parent
                        text: "REMINDERS"
                        color: reminderTab ? "#0D0D0D" : "#A0A0A0"
                        font { family: rootRef.fontFamily; pixelSize: 10; weight: Font.Bold }
                    }
                    MouseArea { anchors.fill: parent; onClicked: { reminderTab = true; historyTab = false } }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    color: historyTab ? "#FFFFFF" : "transparent"
                    border { color: "#555555"; width: 1 }
                    Text {
                        anchors.centerIn: parent
                        text: "HISTORY"
                        color: historyTab ? "#0D0D0D" : "#A0A0A0"
                        font { family: rootRef.fontFamily; pixelSize: 10; weight: Font.Bold }
                    }
                    MouseArea { anchors.fill: parent; onClicked: { reminderTab = false; historyTab = true } }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                visible: !reminderTab && !historyTab
                color: dndArea.containsMouse ? "#202022" : "transparent"
                border { color: "#333337"; width: 1 }
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: "DO NOT DISTURB"
                    color: "#FFFFFF"
                    font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold }
                }
                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: 40
                    height: 20
                    color: "transparent"
                    border { color: "#555555"; width: 1 }
                    Rectangle {
                        x: rootRef.dnd ? 22 : 2
                        y: 2
                        width: 16
                        height: 16
                        color: rootRef.dnd ? "#FFFFFF" : "#777777"
                        Behavior on x { NumberAnimation { duration: 180 } }
                    }
                }
                MouseArea {
                    id: dndArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: rootRef.dnd = !rootRef.dnd
                }
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: !reminderTab && !historyTab
                clip: true
                spacing: 6
                model: notificationServer.trackedNotifications

                delegate: Rectangle {
                    required property var modelData
                    width: ListView.view.width
                    implicitHeight: Math.max(66, notificationColumn.implicitHeight + 24)
                    color: notificationArea.containsMouse ? "#2E2E30" : "#141416"
                    border { color: "#333337"; width: 1 }

                    Rectangle {
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                        width: 2
                        color: "#FFFFFF"
                        opacity: modelData.urgency === NotificationUrgency.Critical ? 1 : 0.35
                    }

                    MouseArea {
                        id: notificationArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            const action = modelData.actions.find(a => a.identifier === "default")
                            if (action) action.invoke()
                            else modelData.dismiss()
                        }
                    }

                    Item {
                        id: iconItem
                        anchors.left: parent.left
                        anchors.leftMargin: 18
                        anchors.verticalCenter: parent.verticalCenter
                        width: 32
                        height: 32
                        visible: iconImage.status === Image.Ready && iconImage.source !== ""
                        Image {
                            id: iconImage
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectFit
                            sourceSize.width: 32
                            sourceSize.height: 32
                            source: {
                                if (!modelData || modelData.summary === "Screenshot" || modelData.appName === "Screenshot") return ""
                                if (modelData.image) return modelData.image
                                const appIcon = modelData.appIcon || ""
                                if (!appIcon) return ""
                                if (appIcon.charAt(0) === "/" || appIcon.indexOf("file:") === 0) return appIcon
                                return Quickshell.iconPath(appIcon, true)
                            }
                        }
                    }

                    ColumnLayout {
                        id: notificationColumn
                        anchors.left: iconItem.visible ? iconItem.right : parent.left
                        anchors.right: closeButton.left
                        anchors.leftMargin: iconItem.visible ? 12 : 18
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3

                        Text {
                            Layout.fillWidth: true
                            text: modelData.appName || ""
                            color: "#A0A0A0"
                            font { family: rootRef.fontFamily; pixelSize: 10; weight: Font.Bold }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: modelData.summary || ""
                            color: "#FFFFFF"
                            elide: Text.ElideRight
                            font { family: rootRef.fontFamily; pixelSize: 12; weight: Font.Bold }
                        }
                        Text {
                            Layout.fillWidth: true
                            visible: text.length > 0
                            text: modelData.body || ""
                            color: "#A0A0A0"
                            wrapMode: Text.WordWrap
                            maximumLineCount: 5
                            elide: Text.ElideRight
                            textFormat: Text.StyledText
                            font { family: rootRef.fontFamily; pixelSize: 10 }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 5
                            visible: modelData.actions && modelData.actions.length > 0
                            Repeater {
                                model: modelData.actions
                                delegate: Rectangle {
                                    required property var modelData
                                    Layout.preferredHeight: 24
                                    Layout.preferredWidth: actionLabel.implicitWidth + 16
                                    color: actionArea.containsMouse ? "#2E2E30" : "transparent"
                                    border { color: "#333337"; width: 1 }
                                    Text {
                                        id: actionLabel
                                        anchors.centerIn: parent
                                        text: modelData.text || modelData.identifier || "ACTION"
                                        color: "#FFFFFF"
                                        font { family: rootRef.fontFamily; pixelSize: 9; weight: Font.Bold }
                                    }
                                     MouseArea {
                                         id: actionArea
                                         anchors.fill: parent
                                         hoverEnabled: true
                                         onClicked: {
                                             const isView = (modelData.text || "").toLowerCase() === "view"
                                             modelData.invoke()
                                             if (isView && modelData.appName) {
                                                 Quickshell.execDetached(["focus-notification-app", modelData.appName])
                                                 modelData.dismiss()
                                             }
                                         }
                                     }
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: closeButton
                        anchors { right: parent.right; top: parent.top; rightMargin: 8; topMargin: 8 }
                        width: 22
                        height: 22
                        color: closeArea.containsMouse ? "#2E2E30" : "transparent"
                        Text { anchors.centerIn: parent; text: "×"; color: "#777777"; font { family: rootRef.fontFamily; pixelSize: 15; weight: Font.Bold } }
                        MouseArea {
                            id: closeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: modelData.dismiss()
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: notificationServer.trackedNotifications.values.length === 0
                    text: "NO NOTIFICATIONS"
                    color: "#555555"
                    font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: reminderTab
                spacing: 8

                Text {
                    text: "ADD A REMINDER"
                    color: "#A0A0A0"
                    font { family: rootRef.fontFamily; pixelSize: 10; weight: Font.Bold }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Rectangle {
                        Layout.preferredWidth: 62
                        Layout.preferredHeight: 32
                        color: "#080808"
                        border { color: "#333337"; width: 1 }
                        TextInput {
                            id: reminderMinutesInput
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            verticalAlignment: TextInput.AlignVCenter
                            color: "#FFFFFF"
                            text: "10"
                            inputMethodHints: Qt.ImhDigitsOnly
                            font { family: rootRef.fontFamily; pixelSize: 10 }
                        }
                    }

                    Text { text: "MIN"; color: "#555555"; font { family: rootRef.fontFamily; pixelSize: 9; weight: Font.Bold } }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        color: "#080808"
                        border { color: "#333337"; width: 1 }
                        TextInput {
                            id: reminderMessageInput
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            verticalAlignment: TextInput.AlignVCenter
                            color: "#FFFFFF"
                            clip: true
                            font { family: rootRef.fontFamily; pixelSize: 10 }
                            Keys.onReturnPressed: notifShade.submitReminder()
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 58
                        Layout.preferredHeight: 32
                        color: addReminderArea.containsMouse ? "#FFFFFF" : "transparent"
                        border { color: "#FFFFFF"; width: 1 }
                        Text {
                            anchors.centerIn: parent
                            text: "ADD"
                            color: addReminderArea.containsMouse ? "#0D0D0D" : "#FFFFFF"
                            font { family: rootRef.fontFamily; pixelSize: 9; weight: Font.Bold }
                        }
                        MouseArea {
                            id: addReminderArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                notifShade.submitReminder()
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text { Layout.fillWidth: true; text: "OPTIONAL DATE"; color: "#555555"; font { family: rootRef.fontFamily; pixelSize: 9; weight: Font.Bold } }
                    Text { text: "TIME"; color: "#555555"; font { family: rootRef.fontFamily; pixelSize: 9; weight: Font.Bold } }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        color: "#080808"
                        border { color: "#333337"; width: 1 }
                        TextInput {
                            id: reminderDateInput
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            verticalAlignment: TextInput.AlignVCenter
                            color: "#FFFFFF"
                            clip: true
                            font { family: rootRef.fontFamily; pixelSize: 10 }
                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: "18 Ağustos 2026 / 18.08.2026"
                                color: "#333333"
                                visible: !parent.text
                                font { family: rootRef.fontFamily; pixelSize: 9 }
                            }
                        }
                    }
                    Rectangle {
                        Layout.preferredWidth: 92
                        Layout.preferredHeight: 32
                        color: "#080808"
                        border { color: "#333337"; width: 1 }
                        TextInput {
                            id: reminderTimeInput
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            verticalAlignment: TextInput.AlignVCenter
                            color: "#FFFFFF"
                            clip: true
                            inputMethodHints: Qt.ImhDigitsOnly
                            font { family: rootRef.fontFamily; pixelSize: 10 }
                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: "18:00"
                                color: "#333333"
                                visible: !parent.text
                                font { family: rootRef.fontFamily; pixelSize: 10 }
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: reminderError.length > 0
                    text: reminderError
                    color: "#e46876"
                    elide: Text.ElideRight
                    font { family: rootRef.fontFamily; pixelSize: 9; weight: Font.Bold }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text { Layout.fillWidth: true; text: "REPEAT"; color: "#555555"; font { family: rootRef.fontFamily; pixelSize: 9; weight: Font.Bold } }
                    Repeater {
                        model: ["none", "daily", "weekly"]
                        delegate: Rectangle {
                            required property string modelData
                            Layout.preferredWidth: 58
                            Layout.preferredHeight: 26
                            color: repeatMode === modelData ? "#FFFFFF" : "transparent"
                            border { color: "#555555"; width: 1 }
                            Text {
                                anchors.centerIn: parent
                                text: modelData === "none" ? "ONCE" : modelData.toUpperCase()
                                color: repeatMode === modelData ? "#0D0D0D" : "#A0A0A0"
                                font { family: rootRef.fontFamily; pixelSize: 8; weight: Font.Bold }
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: repeatMode = modelData
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text { Layout.fillWidth: true; text: "ACTIVE REMINDERS"; color: "#A0A0A0"; font { family: rootRef.fontFamily; pixelSize: 10; weight: Font.Bold } }
                    Text {
                        text: "CLEAR ALL"
                        color: clearRemindersArea.containsMouse ? "#FFFFFF" : "#555555"
                        font { family: rootRef.fontFamily; pixelSize: 9; weight: Font.Bold }
                        MouseArea {
                            id: clearRemindersArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: rootRef.clearReminders()
                        }
                    }
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 6
                    model: rootRef.reminders

                    delegate: Rectangle {
                        required property var modelData
                        property var reminderData: modelData
                        width: ListView.view.width
                        height: 78
                        color: "#141416"
                        border { color: "#333337"; width: 1 }

                        ColumnLayout {
                            anchors.left: parent.left
                            anchors.right: removeReminderButton.left
                            anchors.leftMargin: 12
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3
                            Text {
                                Layout.fillWidth: true
                                text: modelData.message
                                color: "#FFFFFF"
                                elide: Text.ElideRight
                                font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold }
                            }
                            Text {
                                readonly property int remaining: Math.max(0, Number(modelData.dueAt) - Date.now())
                                text: {
                                    void notifShade.reminderTick
                                    const totalSeconds = Math.ceil(remaining / 1000)
                                    const minutes = Math.floor(totalSeconds / 60)
                                    const seconds = totalSeconds % 60
                                    return minutes + ":" + (seconds < 10 ? "0" : "") + seconds
                                }
                                color: "#A0A0A0"
                                font { family: rootRef.fontFamily; pixelSize: 9; weight: Font.Bold }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.repeat === "daily" ? "DAILY" : modelData.repeat === "weekly" ? "WEEKLY" : "ONCE"
                                    color: "#555555"
                                    font { family: rootRef.fontFamily; pixelSize: 8; weight: Font.Bold }
                                }
                                Repeater {
                                    model: [5, 10, 30]
                                    delegate: Rectangle {
                                        required property int modelData
                                        Layout.preferredWidth: 34
                                        Layout.preferredHeight: 20
                                        color: "transparent"
                                        border { color: "#333337"; width: 1 }
                                        Text { anchors.centerIn: parent; text: "+" + modelData + "m"; color: "#A0A0A0"; font { family: rootRef.fontFamily; pixelSize: 8; weight: Font.Bold } }
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: rootRef.snoozeReminder(reminderData.id, modelData)
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            id: removeReminderButton
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.top: parent.top
                            anchors.topMargin: 8
                            width: 24
                            height: 24
                            color: removeArea.containsMouse ? "#2E2E30" : "transparent"
                            Text { anchors.centerIn: parent; text: "×"; color: "#777777"; font { family: rootRef.fontFamily; pixelSize: 15; weight: Font.Bold } }
                            MouseArea {
                                id: removeArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: rootRef.removeReminder(modelData.id)
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: rootRef.reminders.length === 0
                        text: "NO REMINDERS"
                        color: "#555555"
                        font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: historyTab
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Text { Layout.fillWidth: true; text: "SAVED NOTIFICATIONS"; color: "#A0A0A0"; font { family: rootRef.fontFamily; pixelSize: 10; weight: Font.Bold } }
                    Text {
                        text: "CLEAR HISTORY"
                        color: clearHistoryArea.containsMouse ? "#FFFFFF" : "#555555"
                        font { family: rootRef.fontFamily; pixelSize: 9; weight: Font.Bold }
                        MouseArea {
                            id: clearHistoryArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: rootRef.clearNotificationHistory()
                        }
                    }
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 6
                    model: rootRef.notificationHistory

                    delegate: Rectangle {
                        required property var modelData
                        width: ListView.view.width
                        implicitHeight: Math.max(62, historyColumn.implicitHeight + 20)
                        color: "#141416"
                        border { color: "#333337"; width: 1 }

                        ColumnLayout {
                            id: historyColumn
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 3
                            RowLayout {
                                Layout.fillWidth: true
                                Text { Layout.fillWidth: true; text: modelData.appName || "Notification"; color: "#A0A0A0"; elide: Text.ElideRight; font { family: rootRef.fontFamily; pixelSize: 9; weight: Font.Bold } }
                                Text { text: Qt.formatDateTime(new Date(modelData.createdAt), "dd.MM HH:mm"); color: "#555555"; font { family: rootRef.fontFamily; pixelSize: 8 } }
                            }
                            Text { Layout.fillWidth: true; text: modelData.summary || ""; color: "#FFFFFF"; elide: Text.ElideRight; font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold } }
                            Text { Layout.fillWidth: true; visible: text.length > 0; text: modelData.body || ""; color: "#A0A0A0"; wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight; font { family: rootRef.fontFamily; pixelSize: 9 } }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: rootRef.notificationHistory.length === 0
                        text: "NO HISTORY"
                        color: "#555555"
                        font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold }
                    }
                }
            }
        }
    }
}
