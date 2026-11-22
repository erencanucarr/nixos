import QtQuick
import Quickshell
import qs.common

BarModule {
    id: root

    required property string screenName

    readonly property bool open: Panels.popup === `calendar@${root.screenName}`

    selected: open
    onClicked: Panels.togglePopup("calendar", root.screenName)

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    BarText {
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatDateTime(clock.date, "HH:mm")
        color: Theme.bright
        font.weight: Font.DemiBold
    }

    BarText {
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.locale("tr_TR").toString(clock.date, "ddd d MMM")
        color: Theme.dim
    }

    Rectangle {
        visible: Notes.list(clock.date).length > 0
        anchors.verticalCenter: parent.verticalCenter
        width: 5
        height: 5
        radius: 2.5
        color: Theme.warm
    }

    LazyLoader {
        active: root.open

        CalendarMenu {
            key: "calendar"
            anchorItem: root
            screenName: root.screenName
        }
    }
}
