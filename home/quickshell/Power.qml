import QtQuick
import QtQuick.Layouts
import Quickshell

// The power button's menu, in the shape of xeome's Power.qml: bordered rows
// of glyph, name and a dim detail, then a section under a rule. xeome's rows
// pick a power profile (this desktop runs no profile daemon); here they are
// the session actions, and the section below is xeome's idle inhibitor
// (Idle.qml, IdleMenu.qml) folded in: keep the screen awake for a while.
// Not a Menu: its width follows its rows.
Popup {
    id: root

    readonly property var actions: [
        { glyph: Glyph.lock, name: "Kilitle", detail: "Super+L", cmd: ["loginctl", "lock-session"] },
        { glyph: Glyph.logout, name: "Oturumu kapat", detail: "Hyprland'den çık", cmd: ["hyprctl", "dispatch", "hl.dsp.exit()"] },
        { glyph: Glyph.sleep, name: "Uyku", detail: "belleğe askıya al", cmd: ["systemctl", "suspend"] },
        { glyph: Glyph.reboot, name: "Yeniden başlat", detail: "sistemi yeniden başlat", cmd: ["systemctl", "reboot"] },
        { glyph: Glyph.power, name: "Kapat", detail: "sistemi kapat", cmd: ["systemctl", "poweroff"] }
    ]

    // -1 is never picked; 0 is "until I turn it off".
    readonly property var spans: [
        { label: "30 dk", minutes: 30 },
        { label: "1 sa", minutes: 60 },
        { label: "2 sa", minutes: 120 },
        { label: "Sürekli", minutes: 0 }
    ]

    function run(a: var): void {
        root.visible = false;
        Quickshell.execDetached(a.cmd);
    }

    alignRight: true
    contentWidth: body.implicitWidth + 2 * Theme.pad
    contentHeight: body.implicitHeight + 2 * Theme.pad

    ColumnLayout {
        id: body
        anchors.centerIn: parent
        spacing: 4

        Repeater {
            model: root.actions

            delegate: Rectangle {
                id: row

                required property var modelData

                Layout.fillWidth: true
                implicitWidth: 230
                implicitHeight: 38
                radius: Theme.radius
                color: rowMa.containsMouse ? Theme.hoverRaised : "transparent"
                border.width: 1
                border.color: Theme.edge

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.anim
                        easing.type: Theme.ease
                    }
                }

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 10
                        rightMargin: 10
                    }
                    spacing: 8

                    BarText {
                        Layout.preferredWidth: 20
                        horizontalAlignment: Text.AlignHCenter
                        text: row.modelData.glyph
                        font.pixelSize: Theme.size + 4
                        color: rowMa.containsMouse ? Theme.bright : Theme.text
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        BarText {
                            Layout.fillWidth: true
                            text: row.modelData.name
                            font.weight: Font.Medium
                            color: rowMa.containsMouse ? Theme.bright : Theme.text
                        }

                        BarText {
                            Layout.fillWidth: true
                            text: row.modelData.detail
                            font.pixelSize: Theme.small - 1
                            color: Theme.dim
                        }
                    }
                }

                MouseArea {
                    id: rowMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.run(row.modelData)
                }
            }
        }

        Rule {
            Layout.topMargin: 4
            Layout.bottomMargin: 2
        }

        BarText {
            Layout.fillWidth: true
            Layout.leftMargin: 2
            text: !Panels.awake ? `${Glyph.sleepAllowed}  Uykuya izin var` : Panels.awakeUntil > 0 ? `${Glyph.awake}  Uyanık kalıyor · ${Panels.awakeLeft()} kaldı` : `${Glyph.awake}  Uyanık kalıyor`
            font.pixelSize: Theme.small
            color: Panels.awake ? Theme.text : Theme.dim
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Repeater {
                model: root.spans

                delegate: Pick {
                    required property var modelData

                    label: modelData.label
                    align: Text.AlignHCenter
                    current: Panels.awakeSpan === modelData.minutes
                    onClicked: Panels.setAwake(modelData.minutes)
                }
            }
        }
    }
}
