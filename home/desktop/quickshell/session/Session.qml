import QtQuick
import Quickshell

// The full-screen power menu (Super+P, qs ipc call session toggle), on every
// screen: see SessionScreen.qml. The bar's power button keeps its small menu
// with the power profiles and keep-awake.
Scope {
    Variants {
        model: Quickshell.screens

        delegate: SessionScreen {}
    }
}
