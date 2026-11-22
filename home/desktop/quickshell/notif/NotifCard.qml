import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.common
import qs.tailscale

Rectangle {
    id: root

    required property var notif
    property bool showAge: false
    property int lifetime: 0

    signal dismissed
    signal expired

    readonly property int fs: 13
    readonly property int wt: 550
    readonly property int iconSize: 38

    readonly property bool hovered: ma.containsMouse || closeMa.containsMouse || actionsHovered
    property bool actionsHovered: false
    readonly property bool critical: notif?.urgency === NotificationUrgency.Critical
    readonly property string app: notif?.appName || "Bildirim"
    readonly property string age: root.showAge && root.notif ? Notifs.age(root.notif) : "şimdi"
    readonly property var defaultAction: notif?.actions.find(a => a.identifier === "default") ?? null
    readonly property var otherActions: notif?.actions.filter(a => a.identifier !== "default") ?? []

    readonly property var aliases: ({
            "discord": "equibop",
            "vesktop": "equibop",
            "webcord": "equibop"
        })
    readonly property var glyphs: ({
            "ekran görüntüsü": 0xF0100,
            "ekran kaydı": 0xF044A,
            "notify-send": 0xF009A
        })
    readonly property bool tailscale: root.app.toLowerCase() === "tailscale"

    readonly property string picture: notif?.image ?? ""
    readonly property string appIcon: {
        const raw = root.notif?.appIcon ?? "";
        if (raw.startsWith("/"))
            return `file://${raw}`;
        if (raw.startsWith("file://") || raw.startsWith("image://"))
            return raw;
        const key = root.app.toLowerCase();
        const entry = DesktopEntries.heuristicLookup(root.notif?.desktopEntry || root.aliases[key] || root.app);
        for (const name of [raw, entry?.icon, root.aliases[key], key]) {
            const path = name ? Quickshell.iconPath(name, true) : "";
            if (path)
                return path;
        }
        return "";
    }

    readonly property var tints: [Theme.text, Theme.warm, Theme.green, Theme.blue, Theme.magenta, Theme.cyan]
    readonly property color tint: {
        if (root.critical)
            return Theme.hot;
        let h = 0;
        for (const c of root.app)
            h = (h * 31 + c.charCodeAt(0)) >>> 0;
        return root.tints[h % root.tints.length];
    }

    property real remaining: 1

    implicitWidth: 340
    implicitHeight: Math.max(col.implicitHeight, root.iconSize) + 24
    radius: Theme.radiusLg
    color: ma.containsMouse ? Theme.hoverRaised : Theme.raised
    border.width: 1
    border.color: root.critical ? Qt.alpha(Theme.hot, 0.55) : Theme.edge

    Behavior on color {
        ColorAnimation {
            duration: Theme.anim
        }
    }

    NumberAnimation on remaining {
        from: 1
        to: 0
        duration: Math.max(1, root.lifetime)
        running: root.lifetime > 0 && root.visible
        paused: running && root.hovered
        onFinished: root.expired()
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: e => {
            if (e.button === Qt.MiddleButton)
                root.notif.dismiss();
            else if (root.defaultAction)
                root.defaultAction.invoke();
            else
                root.dismissed();
        }
    }

    Item {
        id: avatar

        anchors {
            left: parent.left
            top: parent.top
            leftMargin: 12
            topMargin: 12
        }
        width: root.iconSize
        height: root.iconSize

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius
            color: root.tailscale ? Theme.selRaised : Qt.alpha(root.tint, 0.12)
            border.width: 1
            border.color: root.tailscale ? Theme.edge : Qt.alpha(root.tint, 0.22)
            visible: !picture.visible && !icon.visible

            TailscaleIcon {
                visible: root.tailscale
                anchors.centerIn: parent
                dot: 5
                color: Theme.bright
            }

            BarText {
                visible: !root.tailscale
                anchors.centerIn: parent
                text: root.glyphs[root.app.toLowerCase()] ? String.fromCodePoint(root.glyphs[root.app.toLowerCase()]) : root.app.charAt(0).toUpperCase()
                font.pixelSize: 17
                weight: 650
                color: root.tint
            }
        }

        ClippingRectangle {
            id: picture

            anchors.fill: parent
            radius: Theme.radius
            color: "transparent"
            visible: root.picture !== "" && pictureImage.status === Image.Ready

            Image {
                id: pictureImage
                anchors.fill: parent
                source: root.picture
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(root.iconSize * 2, root.iconSize * 2)
                asynchronous: true
                cache: false
            }
        }

        IconImage {
            id: icon

            anchors.centerIn: parent
            implicitSize: root.iconSize - 6
            source: root.appIcon
            visible: !picture.visible && root.appIcon !== "" && status === Image.Ready
        }

        Rectangle {
            visible: picture.visible && root.appIcon !== "" && !/^image:\/\/icon\/[^/]/.test(root.picture)
            anchors {
                right: parent.right
                bottom: parent.bottom
                rightMargin: -4
                bottomMargin: -4
            }
            width: 18
            height: 18
            radius: 9
            color: Theme.raised
            border.width: 1
            border.color: Theme.edge

            IconImage {
                anchors.centerIn: parent
                implicitSize: 12
                source: root.appIcon
            }
        }
    }

    Column {
        id: col

        anchors {
            left: avatar.right
            right: parent.right
            top: parent.top
            leftMargin: 12
            rightMargin: 12
            topMargin: 11
        }
        spacing: 3

        Item {
            width: parent.width
            height: head.implicitHeight

            BarText {
                id: head
                anchors.left: parent.left
                anchors.right: ageText.left
                anchors.rightMargin: 8
                text: root.app
                elide: Text.ElideRight
                font.pixelSize: root.fs - 2
                weight: 600
                color: root.tint
            }

            BarText {
                id: ageText
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: root.age
                font.pixelSize: root.fs - 2
                weight: root.wt
                color: Theme.dim
                opacity: root.hovered ? 0 : 1

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.anim
                    }
                }
            }

            Rectangle {
                id: close

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: -4
                width: 22
                height: 22
                radius: Theme.radius
                color: closeMa.containsMouse ? Theme.sel : "transparent"
                opacity: root.hovered ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.anim
                    }
                }

                BarText {
                    anchors.centerIn: parent
                    text: String.fromCodePoint(0xF0156)
                    font.pixelSize: root.fs + 1
                    color: closeMa.containsMouse ? Theme.bright : Theme.dim
                }

                MouseArea {
                    id: closeMa
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: root.hovered
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
            font.pixelSize: root.fs + 1
            weight: 620
            color: Theme.bright
        }

        BarText {
            width: parent.width
            visible: text !== ""
            text: root.notif?.body ?? ""
            textFormat: Text.StyledText
            wrapMode: Text.Wrap
            maximumLineCount: 4
            elide: Text.ElideRight
            font.pixelSize: root.fs
            weight: 450
            lineHeight: 1.1
            color: Theme.text
            linkColor: Theme.blue
        }

        Item {
            width: 1
            height: 4
            visible: root.otherActions.length > 0
        }

        Row {
            width: parent.width
            visible: root.otherActions.length > 0
            spacing: 6

            Repeater {
                model: root.otherActions

                delegate: Rectangle {
                    id: action

                    required property var modelData

                    width: (parent.width - 6 * (root.otherActions.length - 1)) / root.otherActions.length
                    height: 28
                    radius: Theme.radius
                    color: actionMa.containsMouse ? Theme.selRaised : Theme.lift
                    border.width: 1
                    border.color: actionMa.containsMouse ? Qt.alpha(root.tint, 0.5) : Theme.edge

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.anim
                        }
                    }

                    BarText {
                        anchors.centerIn: parent
                        width: parent.width - 12
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: action.modelData.text
                        font.pixelSize: root.fs - 1
                        weight: 600
                        color: actionMa.containsMouse ? Theme.bright : Theme.text
                    }

                    MouseArea {
                        id: actionMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onContainsMouseChanged: root.actionsHovered = containsMouse
                        onClicked: action.modelData.invoke()
                    }
                }
            }
        }
    }

    Rectangle {
        visible: root.lifetime > 0
        anchors {
            left: parent.left
            bottom: parent.bottom
            leftMargin: Theme.radiusLg
            bottomMargin: 1
        }
        width: (parent.width - 2 * Theme.radiusLg) * root.remaining
        height: 2
        color: Qt.alpha(root.tint, root.hovered ? 0.35 : 0.7)

        Behavior on color {
            ColorAnimation {
                duration: Theme.anim
            }
        }
    }
}
