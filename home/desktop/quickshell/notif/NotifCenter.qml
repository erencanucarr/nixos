import QtQuick
import QtQuick.Layouts
import qs.common

Menu {
    id: root

    readonly property int fs: 14
    readonly property int wt: 550

    property var expanded: ({})

    readonly property var groups: {
        const order = [];
        const byApp = {};
        for (const n of Notifs.history) {
            const app = n.appName || "Bildirim";
            if (!byApp[app]) {
                byApp[app] = [];
                order.push(app);
            }
            byApp[app].push(n);
        }
        return order.map(app => ({
                    app,
                    items: byApp[app]
                }));
    }

    function toggleGroup(app: string): void {
        const next = Object.assign({}, root.expanded);
        next[app] = !next[app];
        root.expanded = next;
    }

    function clearGroup(items: var): void {
        for (const n of items)
            n.dismiss();
    }

    Component.onCompleted: Notifs.popups = []

    contentWidth: 380
    rowSpacing: 10

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 2
        spacing: 8

        BarText {
            text: "Bildirimler"
            font.pixelSize: root.fs + 2
            weight: 680
            color: Theme.bright
        }

        Rectangle {
            visible: Notifs.history.length > 0
            implicitWidth: countText.implicitWidth + 12
            implicitHeight: 18
            radius: 9
            color: Theme.sel

            BarText {
                id: countText
                anchors.centerIn: parent
                text: Notifs.history.length
                font.pixelSize: root.fs - 3
                weight: 650
                color: Theme.text
            }
        }

        Item {
            Layout.fillWidth: true
        }

        IconButton {
            glyph: Notifs.dnd ? 0xF009B : 0xF009A
            active: Notifs.dnd
            onClicked: Notifs.setDnd(!Notifs.dnd)
        }

        IconButton {
            glyph: 0xF0A7A
            enabled: Notifs.history.length > 0
            onClicked: Notifs.clearAll()
        }
    }

    Rectangle {
        Layout.fillWidth: true
        visible: Notifs.dnd
        implicitHeight: 32
        radius: Theme.radius
        color: Qt.alpha(Theme.warm, 0.08)
        border.width: 1
        border.color: Qt.alpha(Theme.warm, 0.25)

        BarText {
            anchors {
                left: parent.left
                leftMargin: 10
                verticalCenter: parent.verticalCenter
            }
            text: `${String.fromCodePoint(0xF009B)}   Rahatsız etme açık  ·  sadece acil olanlar görünür`
            font.pixelSize: root.fs - 3
            weight: root.wt
            color: Theme.warm
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 1
        color: Theme.line
    }

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: Notifs.history.length === 0 ? 150 : Math.min(list.implicitHeight, 520)

        Column {
            anchors.centerIn: parent
            visible: Notifs.history.length === 0
            spacing: 6

            BarText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: String.fromCodePoint(0xF009E)
                font.pixelSize: 34
                color: Theme.edge
            }

            BarText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Her şey sessiz"
                font.pixelSize: root.fs
                weight: 600
                color: Theme.text
            }

            BarText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Yeni bildirim yok"
                font.pixelSize: root.fs - 3
                weight: root.wt
                color: Theme.dim
            }
        }

        Flickable {
            anchors.fill: parent
            visible: Notifs.history.length > 0
            clip: true
            contentHeight: list.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: list

                width: parent.width
                spacing: 14

                Repeater {
                    model: root.groups

                    delegate: Column {
                        id: group

                        required property var modelData

                        readonly property bool open: root.expanded[modelData.app] === true
                        readonly property int extra: modelData.items.length - 1

                        width: list.width
                        spacing: 6

                        Item {
                            width: parent.width
                            height: 20

                            BarText {
                                id: groupName
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: group.modelData.app.toUpperCase()
                                font.pixelSize: root.fs - 4
                                font.letterSpacing: 0.8
                                weight: 650
                                color: Theme.dim
                            }

                            BarText {
                                visible: group.extra > 0
                                anchors.left: groupName.right
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                text: group.open ? "daralt" : `+${group.extra} daha`
                                font.pixelSize: root.fs - 4
                                weight: 600
                                color: moreMa.containsMouse ? Theme.bright : Theme.blue

                                MouseArea {
                                    id: moreMa
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.toggleGroup(group.modelData.app)
                                }
                            }

                            BarText {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: "temizle"
                                font.pixelSize: root.fs - 4
                                weight: 600
                                color: clearMa.containsMouse ? Theme.bright : Theme.dim

                                MouseArea {
                                    id: clearMa
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.clearGroup(group.modelData.items)
                                }
                            }
                        }

                        Item {
                            width: parent.width
                            height: stack.height + (!group.open && group.extra > 0 ? Math.min(group.extra, 2) * 5 : 0)

                            Repeater {
                                model: !group.open ? Math.min(group.extra, 2) : 0

                                Rectangle {
                                    required property int index

                                    x: (index + 1) * 8
                                    y: stack.height - Theme.radiusLg + (index + 1) * 5
                                    z: -index - 1
                                    width: parent.width - (index + 1) * 16
                                    height: Theme.radiusLg + 1
                                    radius: Theme.radiusLg
                                    color: Theme.raised
                                    border.width: 1
                                    border.color: Theme.edge
                                    opacity: 1 - index * 0.35
                                }
                            }

                            Column {
                                id: stack

                                width: parent.width
                                spacing: 6

                                Repeater {
                                    model: group.open ? group.modelData.items : group.modelData.items.slice(0, 1)

                                    delegate: NotifCard {
                                        id: card

                                        required property var modelData

                                        width: stack.width
                                        notif: modelData
                                        showAge: true
                                        showApp: false
                                        onDismissed: card.modelData.dismiss()
                                    }
                                }
                            }

                            MouseArea {
                                visible: !group.open && group.extra > 0
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: Math.min(group.extra, 2) * 5 + 2
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.toggleGroup(group.modelData.app)
                            }
                        }
                    }
                }
            }
        }
    }

    component IconButton: Rectangle {
        id: btn

        property int glyph
        property bool active: false

        signal clicked

        implicitWidth: 28
        implicitHeight: 28
        radius: Theme.radius
        opacity: enabled ? 1 : 0.35
        color: btn.active ? Theme.selRaised : btnMa.containsMouse ? Theme.hoverRaised : "transparent"
        border.width: 1
        border.color: btn.active || btnMa.containsMouse ? Theme.edge : "transparent"

        Behavior on color {
            ColorAnimation {
                duration: Theme.anim
            }
        }

        BarText {
            anchors.centerIn: parent
            text: String.fromCodePoint(btn.glyph)
            font.pixelSize: root.fs + 2
            color: btn.active ? Theme.warm : btnMa.containsMouse ? Theme.bright : Theme.dim
        }

        MouseArea {
            id: btnMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }
}
