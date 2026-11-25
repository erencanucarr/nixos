import QtQuick
import Quickshell
import Quickshell.Hyprland

Scope {
    Component.onCompleted: Hyprland.refreshToplevels()

    Variants {
        model: Quickshell.screens

        delegate: OverviewScreen {}
    }
}
