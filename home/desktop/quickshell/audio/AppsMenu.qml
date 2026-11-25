import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import qs.common

Menu {
    id: root

    readonly property int fs: Theme.menuSize
    readonly property int wt: Theme.menuWeight

    contentWidth: 324
    rowSpacing: 8

    readonly property var players: AudioNodes.outStreams.filter(n => !!n.audio)

    function appIcon(n: var): string {
        const p = n.properties;
        const bin = (p["application.process.binary"] ?? "").replace(/^\./, "").replace(/-wrapped$/, "").toLowerCase();
        for (const name of [p["application.icon-name"], bin, (p["application.name"] ?? "").toLowerCase()]) {
            const path = name ? Quickshell.iconPath(name, true) : "";
            if (path)
                return path;
        }
        return "";
    }

    PwObjectTracker {
        objects: root.players
    }

    RowLayout {
        Layout.fillWidth: true

        Link {
            text: `${Glyph.chevronLeft} Ses`
            font.pixelSize: root.fs - 2
            weight: root.wt
            onClicked: Panels.popup = `audio@${root.screenName}`
        }

        Item {
            Layout.fillWidth: true
        }

        BarText {
            text: "Uygulamalar"
            font.pixelSize: root.fs
            weight: root.wt
            color: Theme.bright
        }
    }

    Rule {}

    BarText {
        visible: root.players.length === 0
        text: "Şu an ses çalan uygulama yok."
        font.pixelSize: root.fs - 2
        weight: root.wt
        color: Theme.dim
    }

    Repeater {
        model: root.players

        delegate: ColumnLayout {
            id: app

            required property var modelData
            readonly property var audio: modelData.audio
            readonly property bool muted: app.audio?.muted ?? false
            readonly property real volume: app.audio?.volume ?? 0
            readonly property string icon: root.appIcon(modelData)
            readonly property string media: modelData.properties["media.name"] ?? ""

            Layout.fillWidth: true
            spacing: 1

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Item {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 18

                    IconImage {
                        visible: app.icon !== ""
                        anchors.centerIn: parent
                        implicitSize: 18
                        source: app.icon
                        opacity: app.muted ? 0.35 : 1
                    }

                    BarText {
                        visible: app.icon === ""
                        anchors.centerIn: parent
                        text: app.muted ? Glyph.volOff : Glyph.volMid
                        font.pixelSize: Theme.size + 2
                        color: app.muted ? Theme.dim : Theme.text
                    }

                    BarText {
                        visible: app.icon !== "" && app.muted
                        anchors {
                            right: parent.right
                            bottom: parent.bottom
                            rightMargin: -3
                            bottomMargin: -3
                        }
                        text: Glyph.volOff
                        font.pixelSize: Theme.small - 1
                        color: Theme.hot
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (app.audio)
                            app.audio.muted = !app.muted
                    }
                }

                BarText {
                    text: AudioNodes.appName(app.modelData)
                    font.pixelSize: root.fs - 1
                    weight: root.wt
                    color: app.muted ? Theme.dim : Theme.text
                }

                BarText {
                    Layout.fillWidth: true
                    visible: app.media !== "" && app.media !== AudioNodes.appName(app.modelData)
                    text: app.media
                    elide: Text.ElideRight
                    font.pixelSize: root.fs - 3
                    weight: root.wt
                    color: Theme.dim
                }

                Item {
                    Layout.fillWidth: true
                    visible: !(app.media !== "" && app.media !== AudioNodes.appName(app.modelData))
                }

                BarText {
                    text: app.muted ? "sessiz" : `${Math.round(app.volume * 100)}%`
                    font.pixelSize: root.fs - 1
                    weight: root.wt
                    color: app.muted ? Theme.dim : Theme.text
                }
            }

            Track {
                thickness: 8
                Layout.leftMargin: 34
                value: app.muted ? 0 : app.volume
                onMoved: fraction => {
                    if (!app.audio)
                        return;
                    app.audio.muted = false;
                    app.audio.volume = fraction;
                }
            }
        }
    }
}
