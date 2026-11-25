import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property real value: 0
    property int thickness: 6
    property bool knob: false
    property bool dim: false
    signal moved(real fraction)

    readonly property real filled: Math.max(0, Math.min(1, root.value))
    readonly property bool hot: ma.containsMouse || root.knob && ma.pressed

    function report(f: real): void {
        root.moved(Math.max(0, Math.min(1, f)));
    }

    Layout.fillWidth: true
    implicitHeight: root.knob ? root.thickness + 14 : root.thickness + 10

    Rectangle {
        id: groove
        anchors {
            left: parent.left
            right: parent.right
            leftMargin: root.knob ? 6 : 0
            rightMargin: root.knob ? 6 : 0
            verticalCenter: parent.verticalCenter
        }
        height: root.thickness
        radius: height / 2
        color: Theme.rule

        Rectangle {
            width: parent.width * root.filled
            height: parent.height
            radius: height / 2
            color: root.dim ? Theme.dim : root.hot ? Theme.bright : Theme.text
        }
    }

    Rectangle {
        visible: root.knob
        x: groove.x + groove.width * root.filled - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: ma.containsMouse || ma.pressed ? 14 : 10
        height: width
        radius: width / 2
        color: root.dim ? Theme.dim : Theme.bright
        border.width: 3
        border.color: Theme.raised

        Behavior on width {
            NumberAnimation {
                duration: Theme.anim
                easing.type: Theme.ease
            }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        anchors.margins: root.knob ? -4 : 0
        hoverEnabled: true
        cursorShape: root.knob ? Qt.PointingHandCursor : Qt.ArrowCursor
        onPressed: e => root.report((e.x + ma.x - groove.x) / groove.width)
        onPositionChanged: e => {
            if (pressed)
                root.report((e.x + ma.x - groove.x) / groove.width);
        }
        onWheel: e => root.report(root.value + (e.angleDelta.y > 0 ? 0.05 : -0.05))
    }
}
