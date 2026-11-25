pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var cache: ({})
    property var pending: []

    function videoId(url: string): string {
        const m = /(?:youtube\.com\/(?:watch\?(?:.*&)?v=|shorts\/|embed\/)|youtu\.be\/)([A-Za-z0-9_-]{11})/.exec(url ?? "");
        return m ? m[1] : "";
    }

    function lengthOf(url: string): real {
        const id = root.videoId(url);
        return id && id in root.cache ? root.cache[id] : 0;
    }

    function request(url: string): void {
        const id = root.videoId(url);
        if (!id || id in root.cache || root.pending.includes(id))
            return;
        root.pending = root.pending.concat([id]);
        root.next();
    }

    function next(): void {
        const id = root.pending[0];
        if (!id || fetcher.running || !fetcher.done)
            return;
        fetcher.id = id;
        fetcher.done = false;
        fetcher.command = ["sh", "-c", 'curl -s --max-time 6 -H "Accept-Language: en" "https://www.youtube.com/watch?v=$1" | grep -oE \'"lengthSeconds":"[0-9]+"\' | head -1 | grep -oE "[0-9]+"', "sh", id];
        fetcher.running = true;
    }

    Process {
        id: fetcher

        property string id
        property bool done: true

        onExited: root.next()

        stdout: StdioCollector {
            onStreamFinished: {
                const s = parseInt(text.trim());
                const all = Object.assign({}, root.cache);
                all[fetcher.id] = isNaN(s) ? -1 : s;
                root.cache = all;
                root.pending = root.pending.filter(p => p !== fetcher.id);
                fetcher.done = true;
                root.next();
            }
        }
    }
}
