import QtQuick
import Quickshell

// "22:14  Cmt 21 Kas" in a card; the time bright and the bar's one
// heavier label, the date dim.
BarModule {
    id: root

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
}
