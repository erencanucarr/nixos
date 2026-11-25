import QtQuick
import Quickshell
import qs.common

BarModule {
    id: root

    required property string screenName

    readonly property bool open: Panels.popup === `notifs@${root.screenName}`
    readonly property int count: Notifs.history.length

    selected: open || Notifs.dnd

    onClicked: button => {
        if (button === Qt.RightButton)
            Notifs.setDnd(!Notifs.dnd);
        else
            Panels.togglePopup("notifs", root.screenName);
    }

    BarText {
        anchors.verticalCenter: parent.verticalCenter
        text: Notifs.dnd ? Glyph.bellOff : root.count > 0 ? Glyph.bellBadge : Glyph.bell
        color: Notifs.dnd ? Theme.bright : root.count > 0 ? Theme.text : Theme.dim
        font.pixelSize: Theme.size + 1
    }

    BarText {
        visible: root.count > 0 && !Notifs.dnd
        anchors.verticalCenter: parent.verticalCenter
        text: root.count
        color: Theme.text
    }

    LazyLoader {
        active: root.open

        NotifCenter {
            key: "notifs"
            anchorItem: root
            screenName: root.screenName
            alignRight: true
        }
    }
}
