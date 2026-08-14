import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: captureShade

    required property var modelData
    required property var rootRef

    screen: modelData
    WlrLayershell.namespace: "quickshell-capture-center"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"
    visible: rootRef.captureOpen

    function close() { rootRef.captureOpen = false }
    function run(command) {
        close()
        Quickshell.execDetached(command)
    }
    function runShell(script) {
        close()
        Quickshell.execDetached(["sh", "-c", script])
    }

    MouseArea {
        anchors.fill: parent
        onClicked: captureShade.close()
    }

    Rectangle {
        id: panel
        x: parent.width - width - 12
        y: 0
        width: 420
        height: 430
        color: rootRef.chip
        border { color: "#8A8A8A"; width: 2 }
        radius: 7
        focus: visible

        Keys.onEscapePressed: event => {
            captureShade.close()
            event.accepted = true
        }
        MouseArea { anchors.fill: parent; onClicked: {} }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: "CAPTURE CENTER"
                    color: rootRef.accent
                    font { family: rootRef.fontFamily; pixelSize: 20; weight: Font.Bold }
                }
                Text { text: "ESC"; color: rootRef.muted; font { family: rootRef.fontFamily; pixelSize: 9; weight: Font.Bold } }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: rootRef.line }

            Text { text: "SCREENSHOT"; color: rootRef.fg; font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold } }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                CaptureAction { label: "REGION"; detail: "select + edit"; onTriggered: captureShade.run(["screenshot-region"]) }
                CaptureAction { label: "FULL SCREEN"; detail: "all pixels"; onTriggered: captureShade.run(["screenshot-full"]) }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                CaptureAction { label: "OCR TEXT"; detail: "copy text"; onTriggered: captureShade.runShell("grim -g \"$(slurp)\" - | tesseract stdin stdout -l tur 2>/dev/null | wl-copy && notify-send 'Capture' 'Text copied to clipboard'") }
                CaptureAction { label: "QR CODE"; detail: "decode + copy"; onTriggered: captureShade.runShell("grim -g \"$(slurp)\" - | zbarimg -q --raw - 2>/dev/null | wl-copy && notify-send 'Capture' 'QR content copied to clipboard'") }
            }

            Text { text: "TOOLS"; color: rootRef.fg; font { family: rootRef.fontFamily; pixelSize: 11; weight: Font.Bold } }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                CaptureAction { label: "COLOR PICKER"; detail: "copy hex color"; onTriggered: captureShade.runShell("set -o pipefail; color=$(grim -g \"$(slurp -p)\" - | convert png:- -format '%[hex:p{0,0}]' info:-); [ -n \"$color\" ] || { notify-send -u critical 'Capture' 'Could not read color'; exit 1; }; printf '#%s\\n' \"$color\" | wl-copy --type text/plain;charset=utf-8 && notify-send 'Capture' 'Color copied to clipboard'") }
                CaptureAction { label: "RECORDING"; detail: "start / stop"; onTriggered: captureShade.run(["recording-toggle"]) }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: rootRef.line }
            Text { text: "Print opens this center. Existing direct shortcuts remain available."; color: rootRef.muted; font { family: rootRef.fontFamily; pixelSize: 9 } }
        }
    }

    component CaptureAction: Rectangle {
        required property string label
        required property string detail
        signal triggered()
        Layout.fillWidth: true
        Layout.preferredHeight: 58
        color: actionArea.containsMouse ? rootRef.chipHover : "transparent"
        border { color: rootRef.line; width: 1 }
        radius: 4
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 2
            Text { Layout.alignment: Qt.AlignHCenter; text: label; color: rootRef.accent; font { family: rootRef.fontFamily; pixelSize: 10; weight: Font.Bold } }
            Text { Layout.alignment: Qt.AlignHCenter; text: detail; color: rootRef.muted; font { family: rootRef.fontFamily; pixelSize: 8 } }
        }
        MouseArea {
            id: actionArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.triggered()
        }
    }
}
