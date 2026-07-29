import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: audioShade

    required property var modelData
    required property var rootRef
    property int tab: 0

    screen: modelData
    WlrLayershell.namespace: "quickshell-audio-shade"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors { top: true; left: true; right: true; bottom: true }
    margins { top: 0 }
    color: "transparent"
    visible: rootRef.audioOpen

    MouseArea {
        anchors.fill: parent
        onClicked: rootRef.audioOpen = false
    }

    Rectangle {
        id: audioBox
        x: parent.width - width - 12
        y: 0
        width: 430
        height: rootRef.mediaPlayer ? 482 : 420
        color: rootRef.chip
        border { color: "#8A8A8A"; width: 2 }
        radius: 7
        focus: visible
        Keys.onEscapePressed: event => {
            rootRef.audioOpen = false
            event.accepted = true
        }
        MouseArea { anchors.fill: parent; onClicked: {} }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                Text {
                    Layout.fillWidth: true
                    text: "AUDIO"
                    color: rootRef.accent
                    font { family: rootRef.fontFamily; pixelSize: 20; weight: Font.Bold }
                }
                Rectangle {
                    property bool hover: false
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 28
                    color: hover ? rootRef.chipHover : "transparent"
                    border { color: "#6A6A6A"; width: 1 }
                    radius: 8
                    Text {
                        anchors.centerIn: parent
                        text: ""
                        color: rootRef.accent
                        font { family: rootRef.fontFamily; pixelSize: 13; weight: Font.Bold }
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: parent.hover = true
                        onExited: parent.hover = false
                        onClicked: {
                            rootRef.audioOpen = false
                            Quickshell.execDetached(["pavucontrol"])
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: rootRef.line }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                spacing: 5
                Repeater {
                    model: ["MIXER", "APPS", "MEDIA"]
                    delegate: Rectangle {
                        required property string modelData
                        required property int index
                        property bool hover: false
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28
                        Layout.minimumHeight: 28
                        Layout.maximumHeight: 28
                        color: audioShade.tab === index ? rootRef.accent : (hover ? rootRef.chipHover : "transparent")
                        border { color: audioShade.tab === index ? rootRef.accent : rootRef.line; width: 1 }
                        radius: 5
                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: audioShade.tab === index ? rootRef.bg : rootRef.fg
                            font { family: rootRef.fontFamily; pixelSize: 10; weight: Font.Bold }
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: parent.hover = true
                            onExited: parent.hover = false
                            onClicked: audioShade.tab = index
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: rootRef.line }

            StackLayout {
                id: pages
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: audioShade.tab
                clip: true

                Item {
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 8

                        Text { text: "MASTER OUTPUT"; color: rootRef.fg; font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold } }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text {
                                text: rootRef.audioDefaultSinkMuted ? "MUTED" : rootRef.audioDefaultSinkVol
                                color: rootRef.accent
                                Layout.preferredWidth: 58
                                font { family: rootRef.fontFamily; pixelSize: 18; weight: Font.Bold }
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 8
                                color: rootRef.line
                                radius: 4
                                Rectangle {
                                    width: parent.width * Math.min(1, Math.max(0, (parseInt(rootRef.audioDefaultSinkVol) || 0) / 100))
                                    height: parent.height
                                    color: rootRef.audioDefaultSinkMuted ? rootRef.muted : rootRef.accent
                                    radius: 4
                                }
                            }
                            Row {
                                spacing: 4
                                Repeater {
                                    model: ["-", "+", rootRef.audioDefaultSinkMuted ? "unmute" : "mute"]
                                    delegate: Rectangle {
                                        required property string modelData
                                        width: modelData.length > 1 ? 58 : 28
                                        height: 28
                                        color: "transparent"
                                        border { color: rootRef.line; width: 1 }
                                        radius: 5
                                        Text { anchors.centerIn: parent; text: modelData; color: rootRef.accent; font { family: rootRef.fontFamily; pixelSize: 10; weight: Font.Bold } }
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                if (modelData === "-") rootRef.changeAudioVolume("@DEFAULT_AUDIO_SINK@", "5%-")
                                                else if (modelData === "+") rootRef.changeAudioVolume("@DEFAULT_AUDIO_SINK@", "5%+")
                                                else rootRef.toggleAudioMute("@DEFAULT_AUDIO_SINK@")
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: rootRef.line }
                        Text { text: "OUTPUT DEVICES"; color: rootRef.fg; font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold } }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 5
                            Repeater {
                                model: rootRef.audioSinks
                                delegate: Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 32
                                    color: modelData.active ? rootRef.chipOn : "transparent"
                                    border { color: modelData.active ? rootRef.accent : rootRef.line; width: 1 }
                                    radius: 5
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 9
                                        anchors.rightMargin: 9
                                        Text { Layout.fillWidth: true; text: modelData.name; color: modelData.active ? rootRef.accent : rootRef.fg; elide: Text.ElideRight; font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold } }
                                        Text { text: rootRef.audioPercent(modelData.vol); color: rootRef.fg; font { family: rootRef.fontFamily; pixelSize: 10; weight: Font.Bold } }
                                    }
                                    MouseArea { anchors.fill: parent; onClicked: rootRef.setAudioDefault(modelData.id) }
                                }
                            }
                            Text { text: "no outputs"; visible: rootRef.audioSinks.length === 0; color: rootRef.muted; font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold } }
                        }

                        Text { text: "INPUT DEVICES"; color: rootRef.fg; font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold } }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 5
                            Repeater {
                                model: rootRef.audioSources
                                delegate: Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 32
                                    color: modelData.active ? rootRef.chipOn : "transparent"
                                    border { color: modelData.active ? rootRef.accent : rootRef.line; width: 1 }
                                    radius: 5
                                    Text { anchors.centerIn: parent; width: parent.width - 12; text: modelData.name; color: modelData.active ? rootRef.accent : rootRef.fg; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter; font { family: rootRef.fontFamily; pixelSize: 10; weight: Font.Bold } }
                                    MouseArea { anchors.fill: parent; onClicked: rootRef.setAudioDefault(modelData.id) }
                                }
                            }
                        }
                    }
                }

                Item {
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 8
                        Text { text: "APPLICATION STREAMS"; color: rootRef.fg; font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold } }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            Repeater {
                                model: rootRef.audioStreams.slice(0, 5)
                                delegate: Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 42
                                    color: "transparent"
                                    border { color: rootRef.line; width: 1 }
                                    radius: 5
                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 7
                                        spacing: 4
                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text { Layout.fillWidth: true; text: modelData.name; color: rootRef.fg; elide: Text.ElideRight; font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold } }
                                            Text { text: modelData.muted ? "MUTED" : rootRef.audioPercent(modelData.vol); color: rootRef.accent; font { family: rootRef.fontFamily; pixelSize: 10; weight: Font.Bold } }
                                        }
                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 5
                                            Rectangle {
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 5
                                                color: rootRef.line
                                                radius: 3
                                                Rectangle { width: parent.width * Math.min(1, Math.max(0, Number(modelData.vol) || 0)); height: parent.height; color: modelData.muted ? rootRef.muted : rootRef.accent; radius: 3 }
                                            }
                                            Text {
                                                text: "-"
                                                color: rootRef.fg
                                                font { family: rootRef.fontFamily; pixelSize: 13; weight: Font.Bold }
                                                MouseArea { anchors.fill: parent; onClicked: rootRef.changeAudioVolume(modelData.id, "5%-") }
                                            }
                                            Text {
                                                text: "+"
                                                color: rootRef.fg
                                                font { family: rootRef.fontFamily; pixelSize: 13; weight: Font.Bold }
                                                MouseArea { anchors.fill: parent; onClicked: rootRef.changeAudioVolume(modelData.id, "5%+") }
                                            }
                                            Text {
                                                text: modelData.muted ? "unmute" : "mute"
                                                color: rootRef.accent
                                                font { family: rootRef.fontFamily; pixelSize: 9; weight: Font.Bold }
                                                MouseArea { anchors.fill: parent; onClicked: rootRef.toggleAudioMute(modelData.id) }
                                            }
                                        }
                                    }
                                }
                            }
                            Text { text: "no active streams"; visible: rootRef.audioStreams.length === 0; color: rootRef.muted; font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold } }
                        }
                    }
                }

                Item {
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 10
                        Text { text: "MEDIA CONTROL"; color: rootRef.fg; font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold } }
                        Text {
                            Layout.fillWidth: true
                            text: rootRef.mediaPlayer ? (rootRef.mediaArtists ? rootRef.mediaArtists + "  —  " + rootRef.mediaTitle : rootRef.mediaTitle) : "no active player"
                            color: rootRef.mediaPlayer ? rootRef.accent : rootRef.muted
                            elide: Text.ElideRight
                            font { family: rootRef.fontFamily; pixelSize: 12; weight: Font.Bold }
                        }
                        Text { text: rootRef.mediaPlayer ? (rootRef.mediaPlaying ? "playing" : "paused") : ""; color: rootRef.fg; font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold } }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            Repeater {
                                model: ["prev", rootRef.mediaPlaying ? "pause" : "play", "stop", "next"]
                                delegate: Rectangle {
                                    required property string modelData
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 32
                                    color: "transparent"
                                    border { color: rootRef.line; width: 1 }
                                    radius: 5
                                    Text { anchors.centerIn: parent; text: modelData; color: rootRef.accent; font { family: rootRef.fontFamily; pixelSize: 10; weight: Font.Bold } }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            if (!rootRef.mediaPlayer) return
                                            if (modelData === "prev" && rootRef.mediaPlayer.previous) rootRef.mediaPlayer.previous()
                                            else if (modelData === "next" && rootRef.mediaPlayer.next) rootRef.mediaPlayer.next()
                                            else if (modelData === "stop") rootRef.stopMedia()
                                            else rootRef.toggleMedia()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
