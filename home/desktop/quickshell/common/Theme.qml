pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property color ground: "#0a0a0c"
    readonly property color raised: "#151618"
    readonly property color rule: "#232427"
    readonly property color line: "#1d1d1f"
    readonly property color edge: "#26272a"
    readonly property color hover: "#161618"
    readonly property color hoverRaised: "#212224"
    readonly property color selRaised: "#2a2b2e"
    readonly property color text: "#e6e7ea"
    readonly property color bright: "#f7f8f8"
    readonly property color dim: "#8a8f98"
    readonly property color warm: "#e5ae52"
    readonly property color hot: "#e2715a"

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
    readonly property int menuWidth: 280
}
