import QtQuick
import Quickshell
import qs.common

BarModule {
    id: root

    required property string screenName

    readonly property bool open: Panels.popup === `clipboard@${root.screenName}`

    visible: ClipData.enabled
    selected: open
    onClicked: Panels.togglePopup("clipboard", root.screenName)

    BarText {
        anchors.verticalCenter: parent.verticalCenter
        text: Glyph.clipboard
        color: root.open ? Theme.bright : ClipData.config.paused ? Theme.warm : Theme.text
        font.pixelSize: Theme.size + 1
    }

    LazyLoader {
        active: root.open

        ClipMenu {
            key: "clipboard"
            anchorItem: root
            screenName: root.screenName
            alignRight: true
        }
    }
}
