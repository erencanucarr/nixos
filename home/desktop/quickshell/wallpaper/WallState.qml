pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Which wallpaper is on: a file in ~/nixos/home/desktop/wallpapers, or
// "siyah" for plain black. The picker (Super+Shift+W) sets it, and it is
// kept in ~/.local/state/can-wallpaper so it survives a restart.
Singleton {
    id: root

    readonly property string dir: `${Quickshell.env("HOME")}/nixos/home/desktop/wallpapers`
    readonly property string black: "siyah"

    // Until the state file is read (or when there is none yet).
    property string current: "zirve.jpg"

    function set(name: string): void {
        root.current = name;
        file.setText(name + "\n");
    }

    FileView {
        id: file

        path: `${Quickshell.env("HOME")}/.local/state/can-wallpaper`
        printErrors: false
        onLoaded: {
            const name = text().trim();
            if (name)
                root.current = name;
        }
    }
}
