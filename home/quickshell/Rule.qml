import QtQuick
import QtQuick.Layouts

// The hairline that divides a menu's sections (after xeome's Rule.qml).
// Menus sit on `raised`, so it is `edge`, the line over that ground.
Rectangle {
    Layout.fillWidth: true
    implicitHeight: 1
    color: Theme.edge
}
