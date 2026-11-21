import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower

// The power button's menu, in the shape of xeome's Power.qml: bordered rows
// of glyph, name and a dim detail. First the power profile, as xeome picks
// it (power-profiles-daemon serves the same D-Bus API as his tlp-pd; on this
// Ryzen it sets amd-pstate's energy preference), then the session actions,
// then xeome's idle inhibitor (Idle.qml, IdleMenu.qml) folded in: keep the
// screen awake for a while. Not a Menu: its width follows its rows.
Popup {
    id: root

    readonly property var profiles: [
        { profile: PowerProfile.Performance, glyph: Glyph.perf, name: "Performans", detail: "en hızlı tepki, daha çok güç" },
        { profile: PowerProfile.Balanced, glyph: Glyph.balanced, name: "Dengeli", detail: "varsayılan" },
        { profile: PowerProfile.PowerSaver, glyph: Glyph.saver, name: "Güç tasarrufu", detail: "daha az güç, daha serin" }
    ]

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
        Panels.popup = "";
        Quickshell.execDetached(a.cmd);
    }

    alignRight: true
    contentWidth: body.implicitWidth + 2 * Theme.pad
    contentHeight: body.implicitHeight + 2 * Theme.pad

    // One bordered row: glyph, name and a dim detail; `current` fills it.
    component Row: Rectangle {
        id: row

        required property string glyph
        required property string name
        required property string detail
        property bool current: false
        signal clicked

        Layout.fillWidth: true
        implicitWidth: 230
        implicitHeight: 38
        radius: Theme.radius
        color: row.current ? Theme.sel : rowMa.containsMouse ? Theme.hoverRaised : "transparent"
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
                text: row.glyph
                font.pixelSize: Theme.size + 4
                color: row.current || rowMa.containsMouse ? Theme.bright : Theme.text
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                BarText {
                    Layout.fillWidth: true
                    text: row.name
                    font.weight: Font.Medium
                    color: row.current || rowMa.containsMouse ? Theme.bright : Theme.text
                }

                BarText {
                    Layout.fillWidth: true
                    text: row.detail
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
            onClicked: row.clicked()
        }
    }

    ColumnLayout {
        id: body
        anchors.centerIn: parent
        spacing: 4

        Repeater {
            // Performance only where the daemon offers it.
            model: root.profiles.filter(p => p.profile !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile)

            delegate: Row {
                required property var modelData

                glyph: modelData.glyph
                name: modelData.name
                detail: modelData.detail
                current: PowerProfiles.profile === modelData.profile
                // A property write; polkit lets the logged-in user do it.
                onClicked: PowerProfiles.profile = modelData.profile
            }
        }

        // The firmware can cap the CPU whatever the profile; apps can hold one.
        BarText {
            Layout.fillWidth: true
            Layout.leftMargin: 2
            visible: PowerProfiles.degradationReason !== PerformanceDegradationReason.None
            text: `${Glyph.warn}  ${PowerProfiles.degradationReason === PerformanceDegradationReason.HighTemperature ? "yüksek sıcaklık: işlemci kısıldı" : "işlemci kısıldı"}`
            font.pixelSize: Theme.small
            color: Theme.warm
        }

        Repeater {
            model: PowerProfiles.holds

            delegate: BarText {
                required property var modelData

                Layout.fillWidth: true
                Layout.leftMargin: 2
                text: `${modelData.applicationId}: ${modelData.reason || "profili tutuyor"}`
                elide: Text.ElideRight
                font.pixelSize: Theme.small
                color: Theme.dim
            }
        }

        Rule {
            Layout.topMargin: 4
            Layout.bottomMargin: 2
        }

        Repeater {
            model: root.actions

            delegate: Row {
                required property var modelData

                glyph: modelData.glyph
                name: modelData.name
                detail: modelData.detail
                onClicked: root.run(modelData)
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
