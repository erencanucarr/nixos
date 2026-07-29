import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: switcherShade

    required property var modelData
    required property var rootRef

    property string query: ""
    property var windows: []
    property var filteredWindows: []
    property int selectedIndex: 0

    Process {
        id: treeProcess
        running: rootRef.windowSwitcherOpen
        command: ["swaymsg", "-t", "get_tree", "-r"]
        stdout: StdioCollector {
            onStreamFinished: switcherShade.loadWindows(text)
        }
    }

    function loadWindows(text) {
        const result = []
        try {
            const tree = JSON.parse(text)
            function walk(node, workspace) {
                if (!node) return
                const currentWorkspace = node.type === "workspace" ? node.name : workspace
                const props = node.window_properties || {}
                const appId = node.app_id || props.class || props.instance || ""
                if (node.type === "con" && node.id && appId && node.name) {
                    result.push({ id: node.id, app: appId, title: node.name, workspace: currentWorkspace || "—" })
                }
                for (const child of (node.nodes || [])) walk(child, currentWorkspace)
                for (const child of (node.floating_nodes || [])) walk(child, currentWorkspace)
            }
            walk(tree, "—")
        } catch (error) {
            result.length = 0
        }
        windows = result
        refreshResults()
    }

    function refreshResults() {
        const text = query.trim().toLowerCase()
        filteredWindows = windows.filter(item => !text
            || item.app.toLowerCase().indexOf(text) >= 0
            || item.title.toLowerCase().indexOf(text) >= 0
            || item.workspace.toLowerCase().indexOf(text) >= 0)
        selectedIndex = Math.min(selectedIndex, Math.max(0, filteredWindows.length - 1))
    }

    function moveSelection(delta) {
        if (filteredWindows.length === 0) return
        selectedIndex = (selectedIndex + delta + filteredWindows.length) % filteredWindows.length
        windowList.positionViewAtIndex(selectedIndex, ListView.Contain)
    }

    function focusWindow(item) {
        if (!item) return
        rootRef.windowSwitcherOpen = false
        Quickshell.execDetached(["swaymsg", "[con_id=" + item.id + "]", "focus"])
    }

    screen: modelData
    WlrLayershell.namespace: "quickshell-window-switcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors { top: true; left: true; right: true; bottom: true }
    margins { top: 0 }
    color: "transparent"
    visible: rootRef.windowSwitcherOpen

    onVisibleChanged: {
        if (visible) {
            query = ""
            selectedIndex = 0
            treeProcess.running = true
            searchField.forceActiveFocus()
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: rootRef.windowSwitcherOpen = false
    }

    Rectangle {
        anchors.centerIn: parent
        width: 620
        height: 430
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
                Text {
                    Layout.fillWidth: true
                    text: "WINDOWS"
                    color: rootRef.accent
                    font { family: rootRef.fontFamily; pixelSize: 20; weight: Font.Bold }
                }
                Text {
                    text: switcherShade.filteredWindows.length + " RESULTS"
                    color: rootRef.muted
                    font { family: rootRef.fontFamily; pixelSize: 10; weight: Font.Bold }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                color: rootRef.bg
                border { color: rootRef.line; width: 1 }
                TextInput {
                    id: searchField
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    color: rootRef.accent
                    font { family: rootRef.fontFamily; pixelSize: 13; weight: Font.Bold }
                    onTextChanged: {
                        switcherShade.query = text
                        switcherShade.selectedIndex = 0
                        switcherShade.refreshResults()
                    }
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            rootRef.windowSwitcherOpen = false
                            event.accepted = true
                        } else if (event.key === Qt.Key_Down) {
                            switcherShade.moveSelection(1)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Up) {
                            switcherShade.moveSelection(-1)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            switcherShade.focusWindow(switcherShade.filteredWindows[switcherShade.selectedIndex])
                            event.accepted = true
                        }
                    }
                }
            }

            ListView {
                id: windowList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 5
                currentIndex: switcherShade.selectedIndex
                model: switcherShade.filteredWindows

                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    width: windowList.width
                    height: 52
                    color: index === switcherShade.selectedIndex ? rootRef.chipOn : rootRef.bg
                    border { color: index === switcherShade.selectedIndex ? rootRef.accent : rootRef.line; width: 1 }
                    radius: 4

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12
                        Text {
                            Layout.preferredWidth: 180
                            text: modelData.app
                            color: rootRef.accent
                            elide: Text.ElideRight
                            font { family: rootRef.fontFamily; pixelSize: 12; weight: Font.Bold }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: modelData.title
                            color: rootRef.fg
                            elide: Text.ElideRight
                            font { family: rootRef.fontFamily; pixelSize: 11 }
                        }
                        Text {
                            text: modelData.workspace
                            color: rootRef.muted
                            font { family: rootRef.fontFamily; pixelSize: 10; weight: Font.Bold }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: switcherShade.selectedIndex = index
                        onClicked: switcherShade.focusWindow(modelData)
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: windowList.count === 0
                    text: "NO WINDOWS"
                    color: rootRef.muted
                    font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Text { Layout.fillWidth: true; text: "↑ ↓  SELECT"; color: rootRef.muted; font { family: rootRef.fontFamily; pixelSize: 9; weight: Font.Bold } }
                Text { text: "ENTER  FOCUS   ESC  CLOSE"; color: rootRef.muted; font { family: rootRef.fontFamily; pixelSize: 9; weight: Font.Bold } }
            }
        }
    }
}
