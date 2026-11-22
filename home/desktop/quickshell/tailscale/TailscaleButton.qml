import QtQuick
import Quickshell
import qs.common

BarModule {
    id: root

    required property string screenName

    readonly property bool open: Panels.popup === `tailscale@${root.screenName}`

    selected: open
    onClicked: button => {
        if (button === Qt.RightButton)
            TailscaleData.setUp(!TailscaleData.running);
        else
            Panels.togglePopup("tailscale", root.screenName);
    }

    TailscaleIcon {
        anchors.verticalCenter: parent.verticalCenter
        lit: TailscaleData.running
        color: TailscaleData.running ? Theme.text : Theme.dim
    }

    BarText {
        visible: TailscaleData.running && TailscaleData.exitNode !== ""
        anchors.verticalCenter: parent.verticalCenter
        text: TailscaleData.exitNode
        color: Theme.warm
        font.pixelSize: Theme.small
    }

    LazyLoader {
        active: root.open

        TailscaleMenu {
            key: "tailscale"
            anchorItem: root
            screenName: root.screenName
            alignRight: true
        }
    }
}
