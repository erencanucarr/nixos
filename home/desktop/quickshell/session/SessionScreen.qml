import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.common

PanelWindow {
    id: root

    required property var modelData

    readonly property var actions: [
        { glyph: Glyph.lock, name: "Kilitle", key: "L", cmd: ["loginctl", "lock-session"] },
        { glyph: Glyph.logout, name: "Oturumu kapat", key: "O", cmd: ["hyprctl", "dispatch", "hl.dsp.exit()"] },
        { glyph: Glyph.sleep, name: "Uyku", key: "U", cmd: ["systemctl", "suspend"] },
        { glyph: Glyph.reboot, name: "Yeniden başlat", key: "R", cmd: ["systemctl", "reboot"], confirm: true },
        { glyph: Glyph.power, name: "Kapat", key: "P", cmd: ["systemctl", "poweroff"], confirm: true }
    ]

    property bool main: false
    property bool shown: false
    property int selected: 0
    property int armed: -1

    function press(i: int): void {
        const a = root.actions[i];
        root.selected = i;
        if (a.confirm && root.armed !== i) {
            root.armed = i;
            disarm.restart();
            return;
        }
        Panels.sessionOpen = false;
        Quickshell.execDetached(a.cmd);
    }

    screen: modelData
    visible: true

    WlrLayershell.namespace: "ecu-power"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.main ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: Qt.alpha(Theme.ground, 0.7)

    Component.onCompleted: {
        root.main = Hyprland.focusedMonitor?.name === root.modelData.name;
        if (root.main)
            keys.forceActiveFocus();
        root.shown = true;
    }

    Timer {
        id: disarm
        interval: 4000
        onTriggered: root.armed = -1
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Panels.sessionOpen = false
    }

    Item {
        id: keys

        focus: true
        Keys.onPressed: e => {
            const n = root.actions.length;
            const letter = e.text.toUpperCase();
            const byKey = root.actions.findIndex(a => a.key === letter);
            if (e.key === Qt.Key_Escape) {
                Panels.sessionOpen = false;
            } else if (e.key === Qt.Key_Right || e.key === Qt.Key_Tab) {
                root.selected = (root.selected + 1) % n;
                root.armed = -1;
            } else if (e.key === Qt.Key_Left || e.key === Qt.Key_Backtab) {
                root.selected = (root.selected - 1 + n) % n;
                root.armed = -1;
            } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) {
                root.press(root.selected);
            } else if (byKey >= 0) {
                root.press(byKey);
            } else
                return;
            e.accepted = true;
        }
    }

    Column {
        visible: root.main
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.shown ? -20 : 0
        spacing: 0
        opacity: root.shown ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }
        Behavior on anchors.verticalCenterOffset {
            NumberAnimation {
                duration: 260
                easing.type: Easing.OutCubic
            }
        }

        BarText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "HH:mm")
            font.pixelSize: 96
            font.weight: Font.Light
            color: Theme.bright
        }

        BarText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.locale("tr_TR").toString(clock.date, "dddd, d MMMM")
            font.pixelSize: 18
            color: Theme.dim
        }

        Item {
            width: 1
            height: 56
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 14

            Repeater {
                model: root.actions

                delegate: Item {
                    id: action

                    required property var modelData
                    required property int index
                    readonly property bool lit: root.selected === index || ma.containsMouse
                    readonly property bool hot: root.armed === index

                    width: 116
                    height: 132

                    Surface {
                        id: card

                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                        }
                        height: 104
                        fill: action.hot ? Theme.hot : action.lit ? Theme.hoverRaised : Theme.raised
                        scale: action.lit ? 1.04 : 1

                        Behavior on scale {
                            NumberAnimation {
                                duration: 140
                                easing.type: Easing.OutCubic
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: card.radius
                            color: "transparent"
                            border.width: root.selected === action.index ? 2 : 0
                            border.color: action.hot ? Theme.bright : Theme.dim
                        }

                        BarText {
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: -8
                            text: action.modelData.glyph
                            font.pixelSize: 30
                            color: action.hot ? Theme.ground : action.lit ? Theme.bright : Theme.text
                        }

                        BarText {
                            anchors {
                                horizontalCenter: parent.horizontalCenter
                                bottom: parent.bottom
                                bottomMargin: 12
                            }
                            text: action.hot ? "tekrar bas" : action.modelData.key
                            font.pixelSize: Theme.small
                            font.weight: Font.Medium
                            color: action.hot ? Theme.ground : Theme.dim
                        }
                    }

                    BarText {
                        anchors {
                            horizontalCenter: parent.horizontalCenter
                            bottom: parent.bottom
                        }
                        text: action.modelData.name
                        color: action.hot ? Theme.hot : action.lit ? Theme.bright : Theme.text
                    }

                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.press(action.index)
                    }
                }
            }
        }

        Item {
            width: 1
            height: 28
        }

        BarText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "←/→ seç · Enter onayla · harfler kısayol · Esc kapat"
            font.pixelSize: Theme.small
            color: Theme.dim
            opacity: 0.7
        }
    }
}
