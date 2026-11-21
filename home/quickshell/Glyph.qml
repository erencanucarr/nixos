pragma Singleton

import Quickshell

// Nerd Font glyphs by code point, so the source stays plain ASCII. The bar's
// picks follow xeome's (Audio.qml, AudioMenu.qml, Idle.qml, Net.qml, Tray.qml).
Singleton {
    readonly property string apps: String.fromCodePoint(0xF003B)
    readonly property string power: String.fromCodePoint(0xF0425)
    readonly property string lock: String.fromCodePoint(0xF033E)
    readonly property string logout: String.fromCodePoint(0xF0343)
    readonly property string sleep: String.fromCodePoint(0xF04B2)
    readonly property string reboot: String.fromCodePoint(0xF0709)
    readonly property string search: String.fromCodePoint(0xF0349)
    readonly property string volHigh: String.fromCodePoint(0xF057E)
    readonly property string volMid: String.fromCodePoint(0xF0580)
    readonly property string volLow: String.fromCodePoint(0xF057F)
    readonly property string volOff: String.fromCodePoint(0xF0581)
    readonly property string headset: String.fromCodePoint(0xF00B0)
    readonly property string mic: String.fromCodePoint(0xF036C)
    readonly property string micOff: String.fromCodePoint(0xF036D)
    readonly property string chevronUp: String.fromCodePoint(0xF0143)
    readonly property string chevronDown: String.fromCodePoint(0xF0140)
    readonly property string battery: String.fromCodePoint(0xF0949)
    // Idle inhibitor on and off, as in xeome's Idle.qml.
    readonly property string awake: String.fromCodePoint(0xF0176)
    readonly property string sleepAllowed: String.fromCodePoint(0xF0FAA)
    readonly property string chevronLeft: String.fromCodePoint(0xF0141)
    readonly property string chevronRight: String.fromCodePoint(0xF0142)
    readonly property string wired: String.fromCodePoint(0xF0317)
    readonly property string wiredOff: String.fromCodePoint(0xF0319)
    readonly property string wifiOff: String.fromCodePoint(0xF092E)
    // The wifi signal ramp, weakest first.
    readonly property var wifi: [0xF092F, 0xF091F, 0xF0922, 0xF0925, 0xF0928].map(c => String.fromCodePoint(c))
}
