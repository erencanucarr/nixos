import QtQuick

// Every label in the bar. Tabular figures, so labels that update in place
// (clock, volume) don't reflow as digits change width.
Text {
    color: Theme.text
    font.family: Theme.family
    font.pixelSize: Theme.size
    font.features: ({
            tnum: 1
        })
    renderType: Text.NativeRendering
}
