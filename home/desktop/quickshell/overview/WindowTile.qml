import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.common

Item {
    id: root

    required property var toplevel
    property bool selected: false

    readonly property int titleHeight: 28
    readonly property var ipc: toplevel?.lastIpcObject ?? {}
    readonly property string appClass: ipc.class ?? ""
    readonly property string icon: {
        const entry = DesktopEntries.heuristicLookup(root.appClass);
        return Quickshell.iconPath(entry?.icon ?? root.appClass.toLowerCase(), true);
    }
    readonly property bool hovered: ma.containsMouse

    property real dx: 0
    property real dy: 0
    readonly property bool dragging: ma.dragging

    signal activated
    signal closeRequested
    signal dragMoved(point at)
    signal dropped(point at)

    z: dragging ? 10 : 0

    Behavior on x {
        enabled: !root.dragging
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }
    Behavior on y {
        enabled: !root.dragging
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }
    Behavior on width {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }
    Behavior on height {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    Item {
        id: body

        width: parent.width
        height: parent.height
        transform: Translate {
            x: root.dx
            y: root.dy
        }
        scale: root.dragging ? 0.6 : root.hovered || root.selected ? 1.02 : 1
        transformOrigin: Item.Center
        opacity: root.dragging ? 0.9 : 1

        Behavior on scale {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }

        ClippingRectangle {
            id: card

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                bottom: parent.bottom
                bottomMargin: root.titleHeight
            }
            radius: 10
            color: Theme.raised

            ScreencopyView {
                id: view

                anchors.fill: parent
                captureSource: root.toplevel?.wayland ?? null
                live: true
                constraintSize: Qt.size(card.width, card.height)
            }

            IconImage {
                visible: !view.hasContent && root.icon !== ""
                anchors.centerIn: parent
                implicitSize: Math.min(64, parent.height / 3)
                source: root.icon
            }
        }

        Rectangle {
            anchors.fill: card
            radius: card.radius
            color: "transparent"
            border.width: root.hovered || root.selected ? 2 : 1
            border.color: root.hovered || root.selected ? Theme.bright : Theme.rule

            Behavior on border.color {
                ColorAnimation {
                    duration: Theme.anim
                }
            }
        }

        Row {
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: 2
            }
            width: Math.min(implicitWidth, parent.width)
            spacing: 7

            IconImage {
                visible: root.icon !== ""
                anchors.verticalCenter: parent.verticalCenter
                implicitSize: 16
                source: root.icon
            }

            BarText {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, body.width - 24)
                text: root.toplevel?.title || root.appClass
                elide: Text.ElideRight
                color: root.hovered || root.selected ? Theme.bright : Theme.text
            }
        }

        Rectangle {
            visible: root.hovered && !root.dragging
            anchors {
                top: card.top
                right: card.right
                margins: 8
            }
            width: 24
            height: 24
            radius: 12
            color: closeMa.containsMouse ? Theme.hot : Theme.raised
            border.width: 1
            border.color: Theme.edge
            z: 2

            BarText {
                anchors.centerIn: parent
                text: Glyph.close
                font.pixelSize: Theme.size + 2
                color: closeMa.containsMouse ? Theme.ground : Theme.text
            }

            MouseArea {
                id: closeMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.closeRequested()
            }
        }
    }

    MouseArea {
        id: ma

        property point start
        property bool dragging: false
        property bool moved: false

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: dragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor

        onPressed: e => {
            start = Qt.point(e.x, e.y);
            moved = false;
        }
        onPositionChanged: e => {
            if (!(e.buttons & Qt.LeftButton))
                return;
            if (!dragging && Math.hypot(e.x - start.x, e.y - start.y) > 8) {
                dragging = true;
                moved = true;
            }
            if (dragging) {
                root.dx = e.x - start.x;
                root.dy = e.y - start.y;
                root.dragMoved(mapToItem(null, e.x, e.y));
            }
        }
        onReleased: e => {
            if (dragging) {
                root.dropped(mapToItem(null, e.x, e.y));
                dragging = false;
                root.dx = 0;
                root.dy = 0;
            }
        }
        onClicked: e => {
            if (moved)
                return;
            if (e.button === Qt.MiddleButton)
                root.closeRequested();
            else
                root.activated();
        }
    }
}
