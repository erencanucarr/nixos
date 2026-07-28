import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: keybindsShade

    required property var modelData
    required property var rootRef
    property int category: 0

    readonly property var categories: ["NAV", "LAUNCH", "WINDOWS", "LAYOUT", "MEDIA", "TOOLS"]

    function visibleRows() {
        const query = searchField.text.trim().toLowerCase()
        if (!query) return rows(category)

        let result = []
        for (let i = 0; i < categories.length; i++) {
            for (const row of rows(i)) {
                if ((row[0] + " " + row[1]).toLowerCase().indexOf(query) >= 0)
                    result.push([row[0], row[1], categories[i]])
            }
        }
        return result
    }

    function rows(index) {
        const data = [
            [
                ["Mod4 + 1..9 / 0", "Workspace 1..10"],
                ["Ctrl + Left / Right", "Previous / next workspace"],
                ["Ctrl + Tab", "Next workspace"],
                ["Ctrl + Shift + Tab", "Previous workspace"],
                ["Mod4 + Tab", "Next workspace"],
                ["Mod4 + Shift + 1..9", "Move window to workspace"],
                ["Mod4 + arrows / hjkl", "Focus direction"],
                ["Mod4 + Shift + arrows", "Move window"]
            ],
            [
                ["Mod4 + Return", "Open Alacritty"],
                ["Alt + Space", "Open Fuzzel launcher"],
                ["Mod4 + e", "Open Thunar"],
                ["Mod4 + Shift + Space", "Toggle floating"]
            ],
            [
                ["Mod4 + q", "Close focused window"],
                ["Mod4 + f", "Fullscreen"],
                ["Mod4 + r", "Resize mode"],
                ["Mod4 + Space", "Toggle focus mode"],
                ["Mod4 + Escape / p", "Power menu"],
                ["Mod4 + l", "Lock screen"]
            ],
            [
                ["Mod4 + s", "Stacking layout"],
                ["Mod4 + w", "Tabbed layout"],
                ["Mod4 + b", "Horizontal split"],
                ["Mod4 + v", "Vertical split"],
                ["Mod4 + grave", "Scratchpad toggle"],
                ["Mod4 + minus", "Show scratchpad"]
            ],
            [
                ["XF86AudioRaise", "Volume up"],
                ["XF86AudioLower", "Volume down"],
                ["XF86AudioMute", "Mute output"],
                ["XF86AudioMicMute", "Mute microphone"],
                ["XF86AudioNext / Prev", "Next / previous track"],
                ["XF86AudioPlay", "Play / pause"],
                ["XF86MonBrightness + / -", "Brightness"],
                ["Caps Lock", "Caps Lock OSD"]
            ],
            [
                ["Mod4 + k", "Open this keybinds menu"],
                ["Mod4 + m", "Notification center"],
                ["Mod4 + Shift + s", "Screenshot to clipboard"],
                ["Print / Mod4 + Print", "Region / fullscreen screenshot"],
                ["Mod4 + c", "Clipboard history"],
                ["Mod4 + Shift + a", "OCR selected region"],
                ["Mod4 + Shift + i", "System information"],
                ["Mod4 + Shift + r", "Toggle screen recording"]
            ]
        ]
        return data[index] || []
    }

    screen: modelData
    WlrLayershell.namespace: "quickshell-keybinds"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    anchors { top: true; left: true; right: true; bottom: true }
    margins { top: 34 }
    color: "transparent"
    visible: rootRef.keybindsOpen

    MouseArea {
        anchors.fill: parent
        onClicked: rootRef.keybindsOpen = false
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 620
        height: 500
        color: rootRef.chip
        border { color: "#8A8A8A"; width: 2 }
        radius: 8
        focus: rootRef.keybindsOpen
        Keys.onEscapePressed: event => {
            rootRef.keybindsOpen = false
            event.accepted = true
        }
        MouseArea { anchors.fill: parent; onClicked: {} }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: "KEYBINDS"
                    color: rootRef.accent
                    font { family: rootRef.fontFamily; pixelSize: 22; weight: Font.Bold }
                }
                Text {
                    text: "MOD4 + K"
                    color: rootRef.muted
                    font { family: rootRef.fontFamily; pixelSize: 10; weight: Font.Bold }
                }
                Rectangle {
                    Layout.preferredWidth: 26
                    Layout.preferredHeight: 26
                    color: "transparent"
                    border { color: rootRef.line; width: 1 }
                    radius: 5
                    Text { anchors.centerIn: parent; text: "×"; color: rootRef.fg; font { family: rootRef.fontFamily; pixelSize: 16; weight: Font.Bold } }
                    MouseArea { anchors.fill: parent; onClicked: rootRef.keybindsOpen = false }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: rootRef.line }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                spacing: 5
                Repeater {
                    model: keybindsShade.categories
                    delegate: Rectangle {
                        required property string modelData
                        required property int index
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        color: keybindsShade.category === index ? rootRef.accent : "transparent"
                        border { color: keybindsShade.category === index ? rootRef.accent : rootRef.line; width: 1 }
                        radius: 5
                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: keybindsShade.category === index ? rootRef.bg : rootRef.fg
                            font { family: rootRef.fontFamily; pixelSize: 10; weight: Font.Bold }
                        }
                        MouseArea { anchors.fill: parent; onClicked: keybindsShade.category = index }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                color: "#0A0A0A"
                border { color: rootRef.line; width: 1 }
                radius: 5

                TextInput {
                    id: searchField
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    color: "#FFFFFF"
                    selectionColor: rootRef.accent
                    selectedTextColor: rootRef.bg
                    font { family: rootRef.fontFamily; pixelSize: 12; weight: Font.Bold }
                    clip: true
                    focus: rootRef.keybindsOpen
                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Search keybinds..."
                        visible: searchField.text.length === 0
                        color: "#666666"
                        font { family: rootRef.fontFamily; pixelSize: 12; weight: Font.Bold }
                    }
                    Keys.onEscapePressed: event => {
                        rootRef.keybindsOpen = false
                        event.accepted = true
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: rootRef.line }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 5

                Repeater {
                    model: keybindsShade.visibleRows()
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        color: index % 2 === 0 ? "#171719" : "#0A0A0A"
                        border { color: "#1F1F22"; width: 1 }
                        radius: 4

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 12
                            Text {
                                Layout.preferredWidth: 205
                                text: modelData[0]
                                color: "#FFFFFF"
                                font { family: rootRef.fontFamily; pixelSize: 12; weight: Font.Bold }
                            }
                            Text {
                                Layout.fillWidth: true
                                text: modelData.length > 2 ? modelData[2] + "  /  " + modelData[1] : modelData[1]
                                color: "#A0A0A0"
                                elide: Text.ElideRight
                                font { family: rootRef.fontFamily; pixelSize: 12 }
                            }
                        }
                    }
                }
            }
        }
    }
}
