import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    required property var modelData
    required property var rootRef
    required property var notificationServer

    screen: modelData
    WlrLayershell.namespace: "quickshell-notif-shade"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors { top: true; left: true; right: true; bottom: true }
    margins { top: 34 }
    color: "transparent"
    visible: rootRef.notifOpen

    MouseArea {
        anchors.fill: parent
        onClicked: rootRef.notifOpen = false
    }

    Rectangle {
        id: notifBox
        x: parent.width - width - 12
        y: 6
        width: 380
        height: Math.min(parent.height - 20, 100 + notifCol.implicitHeight)
        color: rootRef.chip
        border { color: rootRef.line; width: 1 }
        focus: visible
        Keys.onEscapePressed: event => {
            rootRef.notifOpen = false
            event.accepted = true
        }
        MouseArea { anchors.fill: parent; onClicked: {} }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Text {
                    Layout.fillWidth: true
                    text: "Notifications"
                    color: rootRef.accent
                    font { family: rootRef.fontFamily; pixelSize: 14; weight: Font.Bold }
                }
                Rectangle {
                    id: dndBtn
                    property bool hover: false
                    implicitHeight: 24
                    implicitWidth: dndLbl.implicitWidth + 18
                    color: rootRef.dnd
                        ? rootRef.accent
                        : (hover ? rootRef.chipHover : rootRef.chipOn)
                    border { color: rootRef.dnd ? rootRef.accent : rootRef.line; width: 1 }
                    radius: 3
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text {
                        id: dndLbl
                        anchors.centerIn: parent
                        text: rootRef.dnd ? "DND ON" : "DND"
                        color: rootRef.dnd ? rootRef.bg : rootRef.fg
                        font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold }
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: parent.hover = true
                        onExited:  parent.hover = false
                        onClicked: rootRef.dnd = !rootRef.dnd
                    }
                }
                Text {
                    text: "clear"
                    color: rootRef.fg
                    font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: parent.color = rootRef.accent
                        onExited:  parent.color = rootRef.fg
                        onClicked: {
                            for (const n of notificationServer.trackedNotifications.values.slice())
                                n.dismiss()
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: rootRef.line }

            ColumnLayout {
                id: notifCol
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: notificationServer.trackedNotifications
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: Math.max(60, nCol.implicitHeight + 20)
                        color: rootRef.chip
                        border { color: rootRef.line; width: 1 }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            Item {
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                Layout.alignment: Qt.AlignTop
                                visible: iconImg.status === Image.Ready && iconImg.source != ""
                                Image {
                                    id: iconImg
                                    anchors.fill: parent
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    sourceSize.width: 32
                                    sourceSize.height: 32
                                    source: {
                                        const md = parent.parent.parent.modelData
                                        if (!md || md.summary === "Screenshot" || md.appName === "Screenshot") return ""
                                        if (md.image) return md.image
                                        const a = md.appIcon || ""
                                        if (!a) return ""
                                        if (a.charAt(0) === "/" || a.indexOf("file:") === 0) return a
                                        return Quickshell.iconPath(a, true)
                                    }
                                }
                            }

                            ColumnLayout {
                                id: nCol
                                Layout.fillWidth: true
                                spacing: 6

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6
                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.summary || modelData.appName || ""
                                        color: rootRef.accent
                                        font { family: rootRef.fontFamily; pixelSize: 13; weight: Font.Bold }
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        text: "×"
                                        color: rootRef.fg
                                        font { family: rootRef.fontFamily; pixelSize: 14; weight: Font.Bold }
                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onEntered: parent.color = rootRef.accent
                                            onExited:  parent.color = rootRef.fg
                                            onClicked: modelData.dismiss()
                                        }
                                    }
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.body || ""
                                    color: rootRef.fg
                                    font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold }
                                    wrapMode: Text.WordWrap
                                    textFormat: Text.RichText
                                    visible: text.length > 0
                                }
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6
                                    visible: modelData.actions && modelData.actions.length > 0
                                    Repeater {
                                        model: modelData.actions
                                        delegate: Rectangle {
                                            required property var modelData
                                            property bool hover: false
                                            implicitHeight: 22
                                            implicitWidth: aLabel.implicitWidth + 14
                                            color: hover ? rootRef.chipHover : rootRef.chipOn
                                            border { color: rootRef.line; width: 1 }
                                            Text {
                                                id: aLabel
                                                anchors.centerIn: parent
                                                text: modelData.text || modelData.identifier || "action"
                                                color: hover ? rootRef.accent : rootRef.fg
                                                font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold }
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onEntered: parent.hover = true
                                                onExited:  parent.hover = false
                                                onClicked: modelData.invoke()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "no notifications"
                    color: rootRef.muted
                    font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold }
                    visible: notificationServer.trackedNotifications.values.length === 0
                    Layout.margins: 12
                }
            }
        }
    }
}
