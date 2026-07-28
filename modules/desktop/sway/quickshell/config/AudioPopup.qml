import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: audioShade

    required property var modelData
    required property var rootRef

    screen: modelData
    WlrLayershell.namespace: "quickshell-audio-shade"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    anchors { top: true; left: true; right: true; bottom: true }
    margins { top: 34 }
    color: "transparent"
    visible: rootRef.audioOpen

    MouseArea {
        anchors.fill: parent
        onClicked: rootRef.audioOpen = false
    }

    Rectangle {
        id: audioBox
        x: parent.width - width - 12
        y: 8
        width: 430
        height: rootRef.mediaPlayer ? 482 : 420
        color: rootRef.chip
        border { color: "#8A8A8A"; width: 2 }
        radius: 7
        MouseArea { anchors.fill: parent; onClicked: {} }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Text {
                    Layout.fillWidth: true
                    text: "Audio"
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

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: rootRef.mediaPlayer !== null

                Text {
                    Layout.fillWidth: true
                    text: rootRef.mediaArtists ? (rootRef.mediaArtists + "  —  " + rootRef.mediaTitle) : rootRef.mediaTitle
                    color: rootRef.accent
                    elide: Text.ElideRight
                    font { family: rootRef.fontFamily; pixelSize: 12; weight: Font.Bold }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        Layout.fillWidth: true
                        text: rootRef.mediaPlaying ? "playing" : "paused"
                        color: rootRef.fg
                        font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold }
                    }

                    Repeater {
                        model: ["prev", rootRef.mediaPlaying ? "pause" : "play", "stop", "next"]
                        delegate: Rectangle {
                            required property string modelData
                            property bool hover: false
                            Layout.preferredWidth: modelData.length > 4 ? 54 : 42
                            Layout.preferredHeight: 28
                            color: hover ? rootRef.chipHover : "transparent"
                            border { color: "#6A6A6A"; width: 1 }
                            radius: 7

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: rootRef.accent
                                font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: parent.hover = true
                                onExited: parent.hover = false
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

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: rootRef.line
                visible: rootRef.mediaPlayer !== null
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                Text {
                    text: rootRef.audioDefaultSinkName
                    color: rootRef.fg
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    font { family: rootRef.fontFamily; pixelSize: 12; weight: Font.Bold }
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Text {
                        text: rootRef.audioDefaultSinkMuted ? "muted" : rootRef.audioDefaultSinkVol
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
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width * Math.min(1, Math.max(0, (parseInt(rootRef.audioDefaultSinkVol) || 0) / 100))
                            height: parent.height
                            radius: 4
                            color: rootRef.audioDefaultSinkMuted ? rootRef.muted : rootRef.accent
                        }
                    }
                    Repeater {
                        model: ["-", "+", rootRef.audioDefaultSinkMuted ? "unmute" : "mute"]
                        delegate: Rectangle {
                            required property string modelData
                            property bool hover: false
                            Layout.preferredWidth: modelData.length > 1 ? 56 : 30
                            Layout.preferredHeight: 28
                            color: hover ? rootRef.chipHover : "transparent"
                            border { color: "#6A6A6A"; width: 1 }
                            radius: 7
                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: rootRef.accent
                                font { family: rootRef.fontFamily; pixelSize: 12; weight: Font.Bold }
                            }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: parent.hover = true
                                onExited: parent.hover = false
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

            Text { text: "OUTPUT"; color: rootRef.fg; font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold } }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                Repeater {
                    model: rootRef.audioSinks
                    delegate: Rectangle {
                        required property var modelData
                        property bool hover: false
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        color: modelData.active ? rootRef.chipOn : (hover ? rootRef.chipHover : "transparent")
                        border { color: modelData.active ? rootRef.accent : rootRef.line; width: 1 }
                        radius: 6
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 9
                            anchors.rightMargin: 9
                            Text {
                                Layout.fillWidth: true
                                text: modelData.name
                                color: modelData.active ? rootRef.accent : rootRef.fg
                                elide: Text.ElideRight
                                font { family: rootRef.fontFamily; pixelSize: 12; weight: Font.Bold }
                            }
                            Text {
                                text: rootRef.audioPercent(modelData.vol)
                                color: rootRef.fg
                                font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: parent.hover = true
                            onExited: parent.hover = false
                            onClicked: rootRef.setAudioDefault(modelData.id)
                        }
                    }
                }
                Text {
                    text: "no outputs"
                    color: rootRef.muted
                    visible: rootRef.audioSinks.length === 0
                    font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold }
                }
            }

            Text { text: "INPUT"; color: rootRef.fg; font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold } }
            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: rootRef.audioSources
                    delegate: Rectangle {
                        required property var modelData
                        property bool hover: false
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        color: modelData.active ? rootRef.chipOn : (hover ? rootRef.chipHover : "transparent")
                        border { color: modelData.active ? rootRef.accent : rootRef.line; width: 1 }
                        radius: 6
                        Text {
                            anchors.centerIn: parent
                            width: parent.width - 12
                            text: modelData.name
                            color: modelData.active ? rootRef.accent : rootRef.fg
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                            font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold }
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: parent.hover = true
                            onExited: parent.hover = false
                            onClicked: rootRef.setAudioDefault(modelData.id)
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: rootRef.line }

            Text { text: "APPS"; color: rootRef.fg; font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold } }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                Repeater {
                    model: rootRef.audioStreams.slice(0, 3)
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        color: "transparent"
                        border { color: rootRef.line; width: 1 }
                        radius: 6
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 9
                            anchors.rightMargin: 6
                            spacing: 6
                            Text {
                                Layout.fillWidth: true
                                text: modelData.name
                                color: rootRef.fg
                                elide: Text.ElideRight
                                font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold }
                            }
                            Text {
                                text: modelData.muted ? "muted" : rootRef.audioPercent(modelData.vol)
                                color: rootRef.accent
                                font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold }
                            }
                            Text {
                                text: "-"
                                color: rootRef.accent
                                font { family: rootRef.fontFamily; pixelSize: 13; weight: Font.Bold }
                                MouseArea { anchors.fill: parent; onClicked: rootRef.changeAudioVolume(modelData.id, "5%-") }
                            }
                            Text {
                                text: "+"
                                color: rootRef.accent
                                font { family: rootRef.fontFamily; pixelSize: 13; weight: Font.Bold }
                                MouseArea { anchors.fill: parent; onClicked: rootRef.changeAudioVolume(modelData.id, "5%+") }
                            }
                            Text {
                                text: modelData.muted ? "unmute" : "mute"
                                color: rootRef.accent
                                font { family: rootRef.fontFamily; pixelSize: 10; weight: Font.Bold }
                                MouseArea { anchors.fill: parent; onClicked: rootRef.toggleAudioMute(modelData.id) }
                            }
                        }
                    }
                }
                Text {
                    text: "no active streams"
                    color: rootRef.muted
                    visible: rootRef.audioStreams.length === 0
                    font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold }
                }
            }
        }
    }
}
