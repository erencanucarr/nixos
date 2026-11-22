import QtQuick
import QtQuick.Layouts
import qs.common

Menu {
    id: root

    readonly property int fs: 14
    readonly property int wt: 550

    contentWidth: 360
    rowSpacing: 8

    RowLayout {
        Layout.fillWidth: true

        BarText {
            Layout.fillWidth: true
            text: "Bildirimler"
            font.pixelSize: root.fs + 1
            weight: 650
            color: Theme.bright
        }

        BarText {
            visible: Notifs.history.length > 0
            text: "Tümünü temizle"
            font.pixelSize: root.fs - 2
            weight: root.wt
            color: clearMa.containsMouse ? Theme.bright : Theme.dim

            MouseArea {
                id: clearMa
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Notifs.clearAll()
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 44
        radius: Theme.radius
        color: Notifs.dnd ? Theme.sel : dndMa.containsMouse ? Theme.hoverRaised : "transparent"
        border.width: 1
        border.color: Theme.edge

        Behavior on color {
            ColorAnimation {
                duration: Theme.anim
            }
        }

        BarText {
            id: dndGlyph
            anchors {
                left: parent.left
                leftMargin: 12
                verticalCenter: parent.verticalCenter
            }
            text: String.fromCodePoint(Notifs.dnd ? 0xF009B : 0xF009A)
            font.pixelSize: root.fs + 3
            color: Notifs.dnd ? Theme.bright : Theme.dim
        }

        Column {
            anchors {
                left: dndGlyph.right
                leftMargin: 10
                verticalCenter: parent.verticalCenter
            }
            spacing: 0

            BarText {
                text: "Rahatsız etme"
                font.pixelSize: root.fs - 1
                weight: root.wt
                color: Notifs.dnd ? Theme.bright : Theme.text
            }

            BarText {
                text: Notifs.dnd ? "bildirimler sessizce birikiyor, acil olanlar hariç" : "kapalı"
                font.pixelSize: root.fs - 4
                weight: root.wt
                color: Theme.dim
            }
        }

        Rectangle {
            anchors {
                right: parent.right
                rightMargin: 12
                verticalCenter: parent.verticalCenter
            }
            implicitWidth: 40
            implicitHeight: 22
            radius: height / 2
            color: Notifs.dnd ? Theme.text : "transparent"
            border.width: 1
            border.color: Notifs.dnd ? Theme.text : Theme.edge

            Behavior on color {
                ColorAnimation {
                    duration: Theme.anim
                }
            }

            Rectangle {
                y: 3
                x: Notifs.dnd ? 21 : 3
                width: 16
                height: 16
                radius: 8
                color: Notifs.dnd ? Theme.ground : Theme.dim

                Behavior on x {
                    NumberAnimation {
                        duration: Theme.anim
                        easing.type: Theme.ease
                    }
                }
            }
        }

        MouseArea {
            id: dndMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Notifs.setDnd(!Notifs.dnd)
        }
    }

    ListView {
        Layout.fillWidth: true
        Layout.preferredHeight: Notifs.history.length === 0 ? 70 : Math.min(contentHeight, 470)
        clip: true
        spacing: 6
        boundsBehavior: Flickable.StopAtBounds
        model: Notifs.history

        delegate: NotifCard {
            id: card

            required property var modelData

            width: ListView.view.width
            notif: modelData
            showAge: true
            onDismissed: card.modelData.dismiss()
        }

        BarText {
            anchors.centerIn: parent
            visible: Notifs.history.length === 0
            text: "Bildirim yok"
            font.pixelSize: root.fs - 1
            weight: root.wt
            color: Theme.dim
        }
    }
}
