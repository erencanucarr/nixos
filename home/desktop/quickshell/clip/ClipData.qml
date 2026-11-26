pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool enabled: false
    property var items: []
    property bool loaded: false

    function refresh(): void {
        if (!lister.running)
            lister.running = true;
    }

    function copy(id: string): void {
        Quickshell.execDetached(["ecu-clip", "copy", id]);
    }

    function remove(id: string): void {
        root.items = root.items.filter(i => i.id !== id);
        Quickshell.execDetached(["ecu-clip", "delete", id]);
    }

    function wipe(): void {
        root.items = [];
        Quickshell.execDetached(["ecu-clip", "wipe"]);
    }

    property var config: ({
            days: 7,
            maxItems: 200,
            images: true,
            paused: false
        })
    property var queue: []

    function loadConfig(): void {
        if (!configReader.running)
            configReader.running = true;
    }

    function set(key: string, value: var): void {
        const next = Object.assign({}, root.config);
        next[key] = value;
        root.config = next;
        root.run(["ecu-clip", "set", key, String(value)]);
    }

    function reset(): void {
        root.run(["ecu-clip", "reset"]);
    }

    function run(cmd: var): void {
        root.queue = [...root.queue, cmd];
        root.next();
    }

    function next(): void {
        if (setter.running || root.queue.length === 0)
            return;
        setter.command = root.queue[0];
        root.queue = root.queue.slice(1);
        setter.running = true;
    }

    Process {
        id: setter

        onExited: {
            if (root.queue.length > 0) {
                root.next();
            } else {
                root.loadConfig();
                root.refresh();
            }
        }
    }

    Process {
        id: configReader

        command: ["ecu-clip", "config"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.config = Object.assign({}, root.config, JSON.parse(this.text));
                } catch (e) {}
            }
        }
    }

    FileView {
        path: "/etc/ecu/clipboard.json"
        printErrors: false
        onLoaded: {
            try {
                root.enabled = JSON.parse(text()).enable === true;
                if (root.enabled)
                    root.loadConfig();
            } catch (e) {
                root.enabled = false;
            }
        }
    }

    Process {
        id: lister

        command: ["ecu-clip", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const list = JSON.parse(this.text);
                    root.items = Array.isArray(list) ? list : [];
                } catch (e) {
                    root.items = [];
                }
                root.loaded = true;
            }
        }
    }
}
