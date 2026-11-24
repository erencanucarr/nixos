import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.common

Popup {
    id: root

    readonly property int fs: 14
    readonly property int wt: 550

    readonly property var profiles: [
        { profile: PowerProfile.PowerSaver, glyph: Glyph.saver, name: "Tasarruf", detail: "Daha az güç, daha serin ve sessiz." },
        { profile: PowerProfile.Balanced, glyph: Glyph.balanced, name: "Dengeli", detail: "Varsayılan, çoğu iş için yeterli." },
        { profile: PowerProfile.Performance, glyph: Glyph.perf, name: "Performans", detail: "En hızlı tepki, daha çok güç ve ısı." }
    ].filter(p => p.profile !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile)

    readonly property var actions: [
        { glyph: Glyph.lock, name: "Kilitle", cmd: ["loginctl", "lock-session"] },
        { glyph: Glyph.logout, name: "Çıkış", cmd: ["hyprctl", "dispatch", "hl.dsp.exit()"] },
        { glyph: Glyph.sleep, name: "Uyku", cmd: ["systemctl", "suspend"] },
        { glyph: Glyph.reboot, name: "Yeniden", cmd: ["systemctl", "reboot"] },
        { glyph: Glyph.power, name: "Kapat", cmd: ["systemctl", "poweroff"], danger: true }
    ]

    readonly property var spans: [
        { name: "30 dk", minutes: 30 },
        { name: "1 sa", minutes: 60 },
        { name: "2 sa", minutes: 120 },
        { name: "Sürekli", minutes: 0 }
    ]

    readonly property var current: root.profiles.find(p => p.profile === PowerProfiles.profile) ?? null

    property real uptime: 0

    function run(a: var): void {
        Panels.popup = "";
        Quickshell.execDetached(a.cmd);
    }

    function since(seconds: real): string {
        const m = Math.floor(seconds / 60);
        const d = Math.floor(m / 1440);
        const h = Math.floor(m % 1440 / 60);
        if (d > 0)
            return `${d} gün ${h} sa`;
        if (h > 0)
            return `${h} sa ${m % 60} dk`;
        return `${m} dk`;
    }

    alignRight: true
    contentWidth: 340
    contentHeight: body.implicitHeight + 2 * Theme.pad + 4

    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        onLoaded: root.uptime = Number(text().split(" ")[0]) || 0
    }

    FileView {
        id: hostFile
        path: "/proc/sys/kernel/hostname"
    }

    Timer {
        interval: 60000
        running: root.visible
        repeat: true
        onTriggered: uptimeFile.reload()
    }

    ColumnLayout {
        id: body

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            topMargin: Theme.pad + 2
            leftMargin: Theme.pad + 2
            rightMargin: Theme.pad + 2
        }
        spacing: 8

        Card {
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Tile {
                    glyph: (Quickshell.env("USER") || "?").charAt(0).toUpperCase()
                    glyphSize: 17
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Caption {
                        text: "OTURUM"
                    }

                    BarText {
                        Layout.fillWidth: true
                        text: `${Quickshell.env("USER")}@${hostFile.text().trim()}`
                        elide: Text.ElideRight
                        font.pixelSize: root.fs - 1
                        weight: 600
                        color: Theme.bright
                    }
                }

                ColumnLayout {
                    spacing: 2

                    Caption {
                        Layout.alignment: Qt.AlignRight
                        text: "AÇIK"
                    }

                    BarText {
                        Layout.alignment: Qt.AlignRight
                        text: root.since(root.uptime)
                        font.pixelSize: root.fs - 2
                        weight: 600
                        color: Theme.text
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: root.actions

                    delegate: Rectangle {
                        id: action

                        required property var modelData
                        readonly property bool danger: modelData.danger === true
                        readonly property color tone: action.danger ? Theme.hot : Theme.bright

                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        implicitHeight: 58
                        radius: Theme.radius + 2
                        color: action.danger ? Qt.alpha(Theme.hot, actionMa.containsMouse ? 0.16 : 0.06) : actionMa.containsMouse ? Theme.selRaised : Theme.hoverRaised
                        border.width: 1
                        border.color: action.danger ? Qt.alpha(Theme.hot, actionMa.containsMouse ? 0.5 : 0.25) : Theme.edge

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.anim
                            }
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 5

                            BarText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: action.modelData.glyph
                                font.pixelSize: 17
                                color: action.danger ? Theme.hot : actionMa.containsMouse ? Theme.bright : Theme.text
                            }

                            BarText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: action.modelData.name
                                font.pixelSize: root.fs - 4
                                weight: 600
                                color: action.danger ? Theme.hot : actionMa.containsMouse ? Theme.bright : Theme.dim
                            }
                        }

                        MouseArea {
                            id: actionMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.run(action.modelData)
                        }
                    }
                }
            }
        }

        Card {
            padding: 10
            spacing: 8

            RowLayout {
                Layout.fillWidth: true

                Caption {
                    Layout.fillWidth: true
                    text: "GÜÇ PROFİLİ"
                }

                BarText {
                    visible: !!root.current
                    text: root.current?.glyph ?? ""
                    font.pixelSize: root.fs
                    color: PowerProfiles.profile === PowerProfile.Performance ? Theme.warm : Theme.text
                }
            }

            Segments {
                options: root.profiles
                selected: o => PowerProfiles.profile === o.profile
                onPicked: o => PowerProfiles.profile = o.profile
            }

            BarText {
                Layout.fillWidth: true
                Layout.leftMargin: 2
                text: root.current?.detail ?? ""
                wrapMode: Text.Wrap
                font.pixelSize: root.fs - 4
                weight: root.wt
                color: Theme.dim
            }

            Rectangle {
                Layout.fillWidth: true
                visible: PowerProfiles.degradationReason !== PerformanceDegradationReason.None
                implicitHeight: 30
                radius: Theme.radius
                color: Qt.alpha(Theme.warm, 0.08)
                border.width: 1
                border.color: Qt.alpha(Theme.warm, 0.25)

                BarText {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: `${Glyph.warn}  ${PowerProfiles.degradationReason === PerformanceDegradationReason.HighTemperature ? "Yüksek sıcaklık, işlemci kısıldı" : "İşlemci kısıldı"}`
                    font.pixelSize: root.fs - 3
                    weight: 600
                    color: Theme.warm
                }
            }

            Repeater {
                model: PowerProfiles.holds

                delegate: BarText {
                    required property var modelData

                    Layout.fillWidth: true
                    Layout.leftMargin: 2
                    text: `${modelData.applicationId}: ${modelData.reason || "profili tutuyor"}`
                    elide: Text.ElideRight
                    font.pixelSize: root.fs - 4
                    weight: root.wt
                    color: Theme.dim
                }
            }
        }

        Card {
            padding: 10
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                BarText {
                    text: Panels.awake ? Glyph.awake : Glyph.sleepAllowed
                    font.pixelSize: root.fs + 2
                    color: Panels.awake ? Theme.bright : Theme.dim
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    BarText {
                        text: "Uyanık kal"
                        font.pixelSize: root.fs - 1
                        weight: 600
                        color: Panels.awake ? Theme.text : Theme.dim
                    }

                    BarText {
                        text: !Panels.awake ? "Ekran kapanabilir, sistem uyuyabilir" : Panels.awakeUntil > 0 ? `${Panels.awakeLeft()} kaldı` : "Sen kapatana kadar"
                        font.pixelSize: root.fs - 4
                        weight: root.wt
                        color: Theme.dim
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                Toggle {
                    on: Panels.awake
                    onToggled: Panels.setAwake(Panels.awake ? Panels.awakeSpan : 0)
                }
            }

            Segments {
                options: root.spans
                selected: o => Panels.awakeSpan === o.minutes
                onPicked: o => Panels.setAwake(o.minutes)
            }
        }
    }
}
