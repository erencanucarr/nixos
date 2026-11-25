pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    FileView {
        id: paletteFile
        path: Quickshell.env("HOME") + "/.config/ecu-theme/palette.json"
        blockLoading: true
    }
    readonly property var palette: {
        try {
            return JSON.parse(paletteFile.text());
        } catch (e) {
            return ({});
        }
    }

    readonly property color ground: palette.ground
    readonly property color raised: palette.raised
    readonly property color rule: palette.rule
    readonly property color line: palette.line
    readonly property color edge: palette.edge
    readonly property color hover: palette.hover
    readonly property color hoverRaised: palette.hoverRaised
    readonly property color selRaised: palette.selRaised
    readonly property color text: palette.text
    readonly property color bright: palette.bright
    readonly property color dim: palette.dim
    readonly property color warm: palette.warm
    readonly property color hot: palette.hot
    readonly property color green: palette.green
    readonly property color blue: palette.blue
    readonly property color cyan: palette.cyan
    readonly property color magenta: palette.magenta

    readonly property color card: "#05ffffff"
    readonly property color ring: "#4d000000"
    readonly property color lift: "#0dffffff"
    readonly property color sel: "#12ffffff"

    readonly property color glowPanel: "#11ffffff"
    readonly property color glowPanelFar: "#08ffffff"
    readonly property int radiusLg: 10
    readonly property int ease: Easing.OutCubic

    readonly property int barHeight: 30
    readonly property int gap: 4
    readonly property int glyphGap: 2
    readonly property int pad: 10
    readonly property int radius: 6
    readonly property string family: "Inter"
    readonly property int size: 12
    readonly property int anim: 160

    readonly property int small: 11
    readonly property int menuSize: 14
    readonly property int menuWeight: 550
    readonly property int menuWidth: 280
}
