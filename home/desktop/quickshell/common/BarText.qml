import QtQuick

Text {
    property int weight: 0

    color: Theme.text
    font.family: weight > 0 ? "Inter Variable" : Theme.family
    font.pixelSize: Theme.size
    font.variableAxes: weight > 0 ? ({
            wght: weight
        }) : ({})
    font.features: ({
            tnum: 1
        })
    renderType: Text.NativeRendering
}
