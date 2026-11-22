import QtQuick
import QtQuick.Layouts
import qs.common

// A slider (after xeome's Track.qml): a 6px bar in a 16px hit area. Drag,
// click and scroll report a fraction in 0..1 through moved(); the owner
// decides whether `value` follows.
Item {
    id: root

    property real value: 0
    // The bar's thickness; the hit area is 10px taller.
    property int thickness: 6
    signal moved(real fraction)

    function report(f: real): void {
        root.moved(Math.max(0, Math.min(1, f)));
    }

    Layout.fillWidth: true
    implicitHeight: root.thickness + 10

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        height: root.thickness
        radius: height / 2
        color: Theme.rule

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.value))
            height: parent.height
            radius: height / 2
            color: ma.containsMouse ? Theme.bright : Theme.text
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        onPressed: e => root.report(e.x / root.width)
        onPositionChanged: e => {
            if (pressed)
                root.report(e.x / root.width);
        }
        onWheel: e => root.report(root.value + (e.angleDelta.y > 0 ? 0.05 : -0.05))
    }
}
