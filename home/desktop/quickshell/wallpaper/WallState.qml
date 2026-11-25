pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string dir: `${Quickshell.env("HOME")}/nixos/home/desktop/wallpapers`
    readonly property string black: "siyah"

    property string current: "zirve.jpg"

    function set(name: string): void {
        root.current = name;
        file.setText(name + "\n");
    }

    FileView {
        id: file

        path: `${Quickshell.env("HOME")}/.local/state/ecu-wallpaper`
        printErrors: false
        onLoaded: {
            const name = text().trim();
            if (name)
                root.current = name;
        }
    }
}
