pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var pinned: []
    property var usage: ({})

    function save(): void {
        file.setText(JSON.stringify({
            pinned: root.pinned,
            usage: root.usage
        }, null, 2) + "\n");
    }

    function isPinned(id: string): bool {
        return root.pinned.includes(id);
    }

    function togglePin(id: string): void {
        root.pinned = root.isPinned(id) ? root.pinned.filter(p => p !== id) : root.pinned.concat([id]);
        root.save();
    }

    function launched(id: string): void {
        const all = Object.assign({}, root.usage);
        all[id] = {
            n: (all[id]?.n ?? 0) + 1,
            t: Date.now()
        };
        root.usage = all;
        root.save();
    }

    function score(id: string): real {
        const u = root.usage[id];
        if (!u)
            return 0;
        return u.n * Math.pow(0.5, (Date.now() - u.t) / (7 * 86400000));
    }

    FileView {
        id: file

        path: `${Quickshell.env("HOME")}/.local/state/can-drawer.json`
        blockLoading: true
        printErrors: false
        onLoaded: {
            try {
                const d = JSON.parse(text());
                root.pinned = d.pinned ?? [];
                root.usage = d.usage ?? {};
            } catch (e) {
                console.warn(`drawer: ${e}`);
            }
        }
    }
}
