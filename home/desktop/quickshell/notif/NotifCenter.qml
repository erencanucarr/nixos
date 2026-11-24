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

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: Notifs.history.length === 0 ? 150 : Math.min(list.implicitHeight, 520)

        Row {
            z: 5
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: Notifs.history.length === 0 ? 8 : -3
            anchors.rightMargin: Notifs.history.length === 0 ? 8 : 0
            spacing: 2

            Tile {
                implicitWidth: 28
                implicitHeight: 28
                glyphSize: 14
                glyph: String.fromCodePoint(Notifs.dnd ? 0xF009B : 0xF009A)
                lit: Notifs.dnd
                tone: Notifs.dnd ? Theme.warm : Theme.dim
                border.color: Notifs.dnd ? Qt.alpha(Theme.warm, 0.35) : "transparent"
                clickable: true
                onClicked: Notifs.setDnd(!Notifs.dnd)
            }

            Tile {
                visible: Notifs.history.length > 0
                implicitWidth: 28
                implicitHeight: 28
                glyphSize: 14
                glyph: String.fromCodePoint(0xF0A7A)
                lit: false
                tone: Theme.dim
                border.color: "transparent"
                clickable: true
                onClicked: Notifs.clearAll()
            }
        }


        Rectangle {
            anchors.fill: parent
            visible: Notifs.history.length === 0
            radius: Theme.radiusLg
            color: Theme.card
            border.width: 1
            border.color: Theme.edge

            Column {
                anchors.centerIn: parent
                spacing: 8

                Tile {
                    anchors.horizontalCenter: parent.horizontalCenter
                    glyph: String.fromCodePoint(0xF009E)
                    lit: true
                    tone: Theme.dim
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
                        required property int index

                        readonly property bool open: root.expanded[modelData.app] === true
                        readonly property int extra: modelData.items.length - 1

                        width: list.width
                        spacing: 6

                        Item {
                            width: parent.width
                            height: 22

                            Caption {
                                id: groupName
                                anchors.left: parent.left
                                anchors.leftMargin: 2
                                anchors.verticalCenter: parent.verticalCenter
                                text: group.modelData.app === "Bildirim" ? "BİLDİRİM" : group.modelData.app.toUpperCase()
                            }

                            Tag {
                                visible: group.extra > 0
                                anchors.left: groupName.right
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                implicitHeight: 20
                                text: group.open ? "daralt" : `+${group.extra} daha`
                                tone: Theme.blue
                                accent: true
                                clickable: true
                                onClicked: root.toggleGroup(group.modelData.app)
                            }

                            Tag {
                                anchors.right: parent.right
                                anchors.rightMargin: group.index === 0 ? 66 : 0
                                anchors.verticalCenter: parent.verticalCenter
                                implicitHeight: 20
                                text: "temizle"
                                tone: Theme.dim
                                clickable: true
                                onClicked: root.clearGroup(group.modelData.items)
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

    Rectangle {
        Layout.fillWidth: true
        visible: Notifs.dnd
        implicitHeight: 34
        radius: Theme.radiusLg
        color: Qt.alpha(Theme.warm, 0.08)
        border.width: 1
        border.color: Qt.alpha(Theme.warm, 0.25)

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 9

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 6
                height: 6
                radius: 3
                color: Theme.warm
            }

            BarText {
                anchors.verticalCenter: parent.verticalCenter
                text: "Rahatsız etme açık  ·  sadece acil olanlar görünür"
                font.pixelSize: root.fs - 3
                weight: 600
                color: Theme.warm
            }
        }
    }
}
