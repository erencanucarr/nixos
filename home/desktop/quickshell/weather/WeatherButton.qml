import QtQuick
import Quickshell
import qs.common

BarModule {
    id: root

    required property string screenName

    visible: WeatherData.ready
    readonly property bool open: Panels.popup === `weather@${root.screenName}`

    selected: open

    onClicked: button => {
        if (button === Qt.MiddleButton)
            WeatherData.refresh();
        else
            Panels.togglePopup("weather", root.screenName);
    }

    BarText {
        anchors.verticalCenter: parent.verticalCenter
        text: `${WeatherData.glyph} ${WeatherData.current.temp ?? ""}°`
        color: WeatherData.failed ? Theme.dim : Theme.text
        font.pixelSize: Theme.size + 1
        font.wordSpacing: Theme.glyphGap
    }

    LazyLoader {
        active: root.open

        WeatherMenu {
            key: "weather"
            anchorItem: root
            screenName: root.screenName
        }
    }
}
