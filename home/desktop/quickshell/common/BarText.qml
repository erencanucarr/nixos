import QtQuick

// Every label in the bar. Tabular figures, so labels that update in place
// (clock, volume) don't reflow as digits change width.
//
// `weight` (0 = leave the font alone) sets an exact weight, as xeome's
// panels use (550): through Inter Variable's wght axis, since Qt rounds
// font.weight to the nearest 100 and static Inter has no 550.
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
