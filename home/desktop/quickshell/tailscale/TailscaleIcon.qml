import QtQuick
import qs.common

Grid {
    id: root

    property bool lit: true
    property real dot: 3.4
    property color color: Theme.text

    columns: 3
    spacing: dot * 0.55

    Repeater {
        model: 9

        Rectangle {
            required property int index

            readonly property bool strong: index >= 3 && index <= 5 || index === 7

            width: root.dot
            height: root.dot
            radius: root.dot / 2
            color: root.color
            opacity: root.lit && strong ? 1 : 0.3
        }
    }
}
