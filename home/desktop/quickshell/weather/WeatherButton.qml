import QtQuick
import qs

// The weather card in the bar: the condition glyph and the temperature,
// dimmed while the last fetch failed. Click for WeatherMenu, middle click to
// refresh. Hidden until the first reading arrives.
BarModule {
    id: root

    required property string screenName

    visible: WeatherData.ready
    selected: menu.visible

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

    WeatherMenu {
        id: menu
        key: "weather"
        anchorItem: root
        screenName: root.screenName
    }
}
