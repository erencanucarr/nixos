import QtQuick
import Quickshell.Services.Notifications
import qs.common

Rectangle {
    id: root

    required property var notif
    property bool showAge: false

    signal dismissed

    readonly property int fs: 13
    readonly property int wt: 550

    readonly property bool hovered: ma.containsMouse || closeMa.containsMouse
    readonly property bool critical: notif?.urgency === NotificationUrgency.Critical
    readonly property string app: notif?.appName || "Bildirim"
    readonly property string age: root.showAge && root.notif ? Notifs.age(root.notif) : "şimdi"
    readonly property var defaultAction: notif?.actions.find(a => a.identifier === "default") ?? null
    readonly property var otherActions: notif?.actions.filter(a => a.identifier !== "default") ?? []

    readonly property var tints: ["#e6e7ea", "#e5ae52", "#b5c98f", "#8fb3d9", "#c3a1d9", "#d9a38f"]
    readonly property color tint: {
        if (root.critical)
            return Theme.hot;
        let h = 0;
        for (const c of root.app)
            h = (h * 31 + c.charCodeAt(0)) >>> 0;
        return root.tints[h % root.tints.length];
    }

    implicitWidth: 320
    implicitHeight: col.implicitHeight + 18
    radius: Theme.radius
    color: ma.containsMouse ? Theme.hoverRaised : Theme.raised
    border.width: 1
    border.color: Theme.edge

    Behavior on color {
        ColorAnimation {
            duration: Theme.anim
        }
    }

    Rectangle {
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
            leftMargin: 8
            topMargin: 9
            bottomMargin: 9
        }
        width: 3
        radius: 1.5
        color: root.tint
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.defaultAction ? root.defaultAction.invoke() : root.dismissed()
    }

    Column {
        id: col

        anchors {
            left: parent.left
            right: parent.right
            leftMargin: 20
            rightMargin: 12
            verticalCenter: parent.verticalCenter
        }
        spacing: 2

        Item {
            width: parent.width
            height: head.implicitHeight

            BarText {
                id: head
                anchors.left: parent.left
                anchors.right: close.left
                anchors.rightMargin: 6
                text: `${root.app}  ·  ${root.age}`
                elide: Text.ElideRight
                font.pixelSize: root.fs - 2
                weight: root.wt
                color: Theme.dim
            }

            BarText {
                id: close
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: String.fromCodePoint(0xF0156)
                font.pixelSize: root.fs + 1
                color: closeMa.containsMouse ? Theme.bright : Theme.dim
                opacity: root.hovered || root.showAge ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.anim
                    }
                }

                MouseArea {
                    id: closeMa
                    anchors.fill: parent
                    anchors.margins: -5
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.notif.dismiss()
                }
            }
        }

        BarText {
            width: parent.width
            visible: text !== ""
            text: root.notif?.summary ?? ""
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            font.pixelSize: root.fs
            weight: 600
            color: Theme.bright
        }

        BarText {
            width: parent.width
            visible: text !== ""
            text: root.notif?.body ?? ""
            textFormat: Text.StyledText
            wrapMode: Text.Wrap
            maximumLineCount: 3
            elide: Text.ElideRight
            font.pixelSize: root.fs - 1
            weight: 450
            color: Theme.text
            linkColor: Theme.bright
        }

        Row {
            visible: root.otherActions.length > 0
            topPadding: 4
            spacing: 14

            Repeater {
                model: root.otherActions

                delegate: BarText {
                    id: action

                    required property var modelData

                    text: action.modelData.text
                    font.pixelSize: root.fs - 1
                    weight: 600
                    color: actionMa.containsMouse ? Theme.bright : root.tint

                    MouseArea {
                        id: actionMa
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: action.modelData.invoke()
                    }
                }
            }
        }
    }
}
