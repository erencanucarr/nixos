pragma Singleton

import QtQuick
import Quickshell

// Graphite (xeome/dots, infra/data.py), the same palette as the prompt,
// Vicinae, Ghostty and the window borders. Sizes are smaller than xeome's
// (a 48px bar at 14px, 550 weight) on purpose: a thin, light bar.
Singleton {
    readonly property color ground: "#0a0a0c"
    readonly property color raised: "#151618"
    readonly property color rule: "#232427"
    readonly property color line: "#1d1d1f" // an edge over the ground
    readonly property color edge: "#26272a" // an edge over `raised`
    readonly property color hover: "#161618" // over the ground
    readonly property color hoverRaised: "#212224"
    readonly property color selRaised: "#2a2b2e"
    readonly property color text: "#e6e7ea"
    readonly property color bright: "#f7f8f8"
    readonly property color dim: "#8a8f98"
    readonly property color warm: "#e5ae52"
    readonly property color hot: "#e2715a"

    // Bar cards, as in xeome's bar: a nearly clear fill inside a `line`
    // border, a dark ring as the outer pixel and a faint lit top edge. `sel`
    // fills what is shown or switched on. #AARRGGBB, Qt's order.
    readonly property color card: "#05ffffff"
    readonly property color ring: "#4d000000"
    readonly property color lift: "#0dffffff"
    readonly property color sel: "#12ffffff"

    readonly property int barHeight: 30
    // Space above and below a bar card: 30 - 2 * 4 makes a 22px card.
    readonly property int gap: 4
    // Widens the space between a glyph and its value: Inter's space is
    // narrow and the Nerd Font fallback glyphs narrower, so the two touch.
    readonly property int glyphGap: 2
    readonly property int pad: 10
    readonly property int radius: 6
    readonly property string family: "Inter"
    readonly property int size: 12
    readonly property int anim: 160
}
