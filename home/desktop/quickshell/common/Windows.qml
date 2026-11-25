pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    function classOf(t: var): string {
        return (t?.lastIpcObject?.class ?? "").toLowerCase();
    }

    function forKeys(keys: var): var {
        return Hyprland.toplevels.values.find(t => keys.includes(root.classOf(t))) ?? null;
    }

    function focus(t: var): void {
        if (t)
            Hyprland.dispatch(`hl.dsp.focus({ window = "address:0x${t.address}" })`);
    }
}
