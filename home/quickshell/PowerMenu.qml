import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// Lock, log out, sleep, restart, shut down. The bar's power button or
// Super+Esc opens it; Esc or a click outside closes it.
PanelWindow {
    id: root

    readonly property var actions: [
        { glyph: Glyph.lock, label: "Kilitle", cmd: ["loginctl", "lock-session"] },
        { glyph: Glyph.logout, label: "Oturumu kapat", cmd: ["hyprctl", "dispatch", "hl.dsp.exit()"] },
        { glyph: Glyph.sleep, label: "Uyku", cmd: ["systemctl", "suspend"] },
        { glyph: Glyph.reboot, label: "Yeniden başlat", cmd: ["systemctl", "reboot"] },
        { glyph: Glyph.power, label: "Kapat", cmd: ["systemctl", "poweroff"] }
    ]

    function run(action: var): void {
        Panels.powerOpen = false;
        Quickshell.execDetached(action.cmd);
    }

    visible: Panels.powerOpen
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    WlrLayershell.namespace: "can-power"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "#990a0a0c"

    onVisibleChanged: if (visible)
        keys.forceActiveFocus()

    MouseArea {
        anchors.fill: parent
        onClicked: Panels.powerOpen = false
    }

    Item {
        id: keys
        Keys.onEscapePressed: Panels.powerOpen = false
    }

    Row {
        anchors.centerIn: parent
        spacing: 12

        Repeater {
            model: root.actions

            delegate: Rectangle {
                id: button

                required property var modelData

                width: 112
                height: 112
                radius: 12
                color: area.containsMouse ? Theme.hoverRaised : Theme.raised
                border.width: 1
                border.color: Theme.edge

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.anim
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 10

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: button.modelData.glyph
                        color: area.containsMouse ? Theme.bright : Theme.text
                        font.family: Theme.family
                        font.pixelSize: 28
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: button.modelData.label
                        color: Theme.dim
                        font.family: Theme.family
                        font.pixelSize: 12
                    }
                }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.run(button.modelData)
                }
            }
        }
    }
}
